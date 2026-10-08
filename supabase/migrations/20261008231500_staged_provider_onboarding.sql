-- CX1 staged category onboarding. Explicitly NOT the legacy provider approval path.
-- Staged review can never activate providers, listings, roles or financial rails.
-- No identity/medical/financial documents are collected at this stage.
CREATE TABLE public.provider_onboarding_policies (
  category_id uuid PRIMARY KEY REFERENCES public.service_categories(id) ON DELETE RESTRICT,
  intake_status text NOT NULL CHECK (intake_status IN ('staged','restricted')),
  requirements text[] NOT NULL DEFAULT '{}'::text[],
  guidance text NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO public.provider_onboarding_policies
 (category_id, intake_status, requirements, guidance)
SELECT c.id, policy.intake_status, policy.requirements, policy.guidance
FROM (VALUES
 ('shopping-retail','staged',ARRAY['Service and product description','Business identity review pending','Product safety and trading requirements review pending']::text[],
  'Preliminary application only. No sales or published retail listing will be enabled.'),
 ('home-services','staged',ARRAY['Trade description and coverage area','Identity and trade qualification review pending','Insurance and consumer-safety review pending']::text[],
  'Preliminary application only. Trade evidence will be requested during controlled review.'),
 ('beauty-wellness','staged',ARRAY['Services offered and hygiene arrangements','Identity and qualifications review pending','Relevant health and consumer-safety requirements review pending']::text[],
  'Preliminary application only. Regulated treatments cannot be advertised or booked.'),
 ('health-medical','restricted',ARRAY['Professional registration verification required','Facility licence and service-scope review required','Privacy and safeguarding review required']::text[],
  'Applications closed pending medical regulatory verification policy and document controls.'),
 ('travel-flights','restricted',ARRAY['Travel seller/agency authority review required','Supplier/airline integration and refund controls required']::text[],
  'Applications closed until lawful travel sales and supplier integration standards are approved.'),
 ('education-training','restricted',ARRAY['Tutor and institution validation required','Safeguarding and child-protection arrangements to be approved']::text[],
  'Applications closed until safeguarding and identity-check requirements are approved.'),
 ('financial-services','restricted',ARRAY['Regulator authorisation verification required','AML/CTF and safeguarding policy required','Financial-service scope and disclosures required']::text[],
  'Applications closed pending regulated-provider compliance design.')
) AS policy(slug,intake_status,requirements,guidance)
JOIN public.service_categories c ON c.slug=policy.slug
ON CONFLICT (category_id) DO NOTHING;

CREATE TABLE public.staged_provider_applications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  category_id uuid NOT NULL REFERENCES public.service_categories(id) ON DELETE RESTRICT,
  applicant_name text NOT NULL CHECK (length(btrim(applicant_name)) BETWEEN 2 AND 120),
  applicant_kind text NOT NULL CHECK (applicant_kind IN ('individual','business')),
  coverage_province text NOT NULL CHECK (length(btrim(coverage_province)) BETWEEN 2 AND 90),
  coverage_town text CHECK (coverage_town IS NULL OR length(btrim(coverage_town)) BETWEEN 2 AND 90),
  service_summary text NOT NULL CHECK (length(btrim(service_summary)) BETWEEN 10 AND 1000),
  status text NOT NULL DEFAULT 'submitted'
    CHECK (status IN ('submitted','in_review','declined')),
  submitted_at timestamptz NOT NULL DEFAULT now(),
  reviewed_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  reviewed_at timestamptz,
  UNIQUE (user_id, category_id)
);
CREATE INDEX staged_provider_applications_review_idx
  ON public.staged_provider_applications (status, submitted_at DESC);

ALTER TABLE public.provider_onboarding_policies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.staged_provider_applications ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.provider_onboarding_policies FROM PUBLIC, anon, authenticated;
REVOKE ALL ON public.staged_provider_applications FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.provider_onboarding_policies TO authenticated;
GRANT SELECT ON public.staged_provider_applications TO authenticated;

CREATE POLICY onboarding_policy_read_authenticated
  ON public.provider_onboarding_policies FOR SELECT TO authenticated USING (true);
CREATE POLICY staged_applications_read_owner_admin
  ON public.staged_provider_applications FOR SELECT TO authenticated
  USING (user_id = auth.uid() OR public.is_admin(auth.uid()));

CREATE OR REPLACE FUNCTION public.submit_staged_provider_application(
  p_category_slug text, p_applicant_name text, p_applicant_kind text,
  p_coverage_province text, p_coverage_town text, p_service_summary text
) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth AS $$
DECLARE
  v_category uuid;
  v_id uuid;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING errcode = '28000';
  END IF;
  SELECT c.id INTO v_category
  FROM public.service_categories c
  JOIN public.provider_onboarding_policies p ON p.category_id = c.id
  WHERE c.slug = lower(btrim(coalesce(p_category_slug,'')))
    AND c.is_active AND c.booking_mode = 'information'
    AND c.metadata->>'rollout_status' = 'catalogue_only'
    AND c.metadata->>'provider_onboarding_enabled' = 'false'
    AND p.intake_status = 'staged';
  IF v_category IS NULL THEN
    RAISE EXCEPTION 'Formal category intake not available'
      USING errcode = '22023';
  END IF;
  IF length(btrim(coalesce(p_applicant_name,''))) NOT BETWEEN 2 AND 120
    OR lower(btrim(coalesce(p_applicant_kind,''))) NOT IN ('individual','business')
    OR length(btrim(coalesce(p_coverage_province,''))) NOT BETWEEN 2 AND 90
    OR (nullif(btrim(coalesce(p_coverage_town,'')),'') IS NOT NULL
        AND length(btrim(p_coverage_town)) NOT BETWEEN 2 AND 90)
    OR length(btrim(coalesce(p_service_summary,''))) NOT BETWEEN 10 AND 1000 THEN
    RAISE EXCEPTION 'Invalid preliminary application fields' USING errcode = '22023';
  END IF;
  INSERT INTO public.staged_provider_applications
    (user_id,category_id,applicant_name,applicant_kind,coverage_province,coverage_town,service_summary)
  VALUES
    (auth.uid(),v_category,btrim(p_applicant_name),lower(btrim(p_applicant_kind)),
     btrim(p_coverage_province),nullif(btrim(coalesce(p_coverage_town,'')),''),btrim(p_service_summary))
  ON CONFLICT (user_id, category_id) DO NOTHING RETURNING id INTO v_id;
  IF v_id IS NULL THEN
    RAISE EXCEPTION 'A preliminary application already exists for this category'
      USING errcode = '23505';
  END IF;
  RETURN v_id;
END; $$;

CREATE OR REPLACE FUNCTION public.triage_staged_provider_application(
  p_application_id uuid, p_decision text
) RETURNS public.staged_provider_applications
LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,auth AS $$
DECLARE v_row public.staged_provider_applications%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL OR NOT public.is_admin(auth.uid()) THEN
    RAISE EXCEPTION 'Admin access required' USING errcode='42501';
  END IF;
  IF p_decision NOT IN ('in_review','declined') THEN
    RAISE EXCEPTION 'Only preliminary triage is permitted' USING errcode='22023';
  END IF;
  UPDATE public.staged_provider_applications
  SET status=p_decision,reviewed_by=auth.uid(),reviewed_at=now()
  WHERE id=p_application_id AND status='submitted'
  RETURNING * INTO v_row;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Submitted preliminary application not found'
      USING errcode='22023';
  END IF;
  RETURN v_row;
END; $$;

REVOKE ALL ON FUNCTION public.submit_staged_provider_application(text,text,text,text,text,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.submit_staged_provider_application(text,text,text,text,text,text) TO authenticated;
REVOKE ALL ON FUNCTION public.triage_staged_provider_application(uuid,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.triage_staged_provider_application(uuid,text) TO authenticated;

COMMENT ON TABLE public.staged_provider_applications IS
 'Preliminary category intake only; admin triage NEVER grants verification, role, published service or booking rights.';
