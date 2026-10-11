-- Enterprise intake v1: read-restricted registration metadata, NEVER raw ID
-- scans, full NID/TIN numbers, bank details or passwords.
-- This migration is additive. Existing production providers/listings are not
-- reclassified or deleted; new approvals are gated until independently cleared.

CREATE TABLE public.vendor_intake_cases (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  applicant_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  category_id uuid NOT NULL REFERENCES public.service_categories(id),
  applicant_kind text NOT NULL CHECK(applicant_kind IN ('individual','business')),
  display_name text NOT NULL CHECK (length(btrim(display_name)) BETWEEN 2 AND 120),
  country_code text NOT NULL CHECK(country_code ~ '^[A-Z]{2}$'),
  region text NOT NULL CHECK(length(btrim(region)) BETWEEN 2 AND 120),
  locality text NOT NULL CHECK(length(btrim(locality)) BETWEEN 2 AND 120),
  street_address text NOT NULL CHECK(length(btrim(street_address)) BETWEEN 5 AND 240),
  contact_email text NOT NULL CHECK(length(contact_email) BETWEEN 5 AND 240 AND
    contact_email ~* '^[^ @]+@[^ @]+[.][^ @]+$'),
  contact_phone text NOT NULL CHECK(length(contact_phone) BETWEEN 7 AND 35),
  applicant_identity_type text NOT NULL CHECK
    (applicant_identity_type IN ('national_id','passport','drivers_licence','other')),
  identity_last_four text CHECK(identity_last_four IS NULL OR
    identity_last_four ~ '^[A-Za-z0-9]{4}$'),
  business_registration text CHECK(business_registration IS NULL OR
    length(btrim(business_registration)) BETWEEN 3 AND 70),
  tax_reference_last_four text CHECK(tax_reference_last_four IS NULL OR
    tax_reference_last_four ~ '^[A-Za-z0-9]{4}$'),
  service_summary text NOT NULL CHECK(length(btrim(service_summary)) BETWEEN 10 AND 1200),
  service_metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  status text NOT NULL DEFAULT 'submitted' CHECK(status IN
    ('submitted','in_review','needs_information','declined')),
  assigned_reviewer uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  submitted_at timestamptz NOT NULL DEFAULT now(),
  reviewed_at timestamptz,
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX vendor_intake_case_queue_idx
  ON public.vendor_intake_cases(status,country_code,submitted_at DESC);
CREATE INDEX vendor_intake_owner_idx
  ON public.vendor_intake_cases(applicant_id,submitted_at DESC);

CREATE TABLE public.vendor_intake_events (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  case_id uuid NOT NULL REFERENCES public.vendor_intake_cases(id) ON DELETE RESTRICT,
  actor_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  event_type text NOT NULL CHECK(event_type IN
    ('submitted','review_started','information_requested','declined')),
  previous_status text,
  next_status text NOT NULL,
  reason text CHECK(reason IS NULL OR length(reason) BETWEEN 10 AND 1000),
  recorded_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX vendor_intake_events_case_idx
  ON public.vendor_intake_events(case_id,recorded_at DESC);

-- Separate explicit clearance from registration acceptance, so a historical
-- "verified" status does not itself grant any new listing activation.
CREATE TABLE public.vendor_activation_clearances (
  provider_id uuid PRIMARY KEY REFERENCES public.provider_profiles(provider_id),
  identity_reviewer uuid NOT NULL REFERENCES auth.users(id),
  approving_officer uuid NOT NULL REFERENCES auth.users(id),
  clearance_type text NOT NULL CHECK(clearance_type='final_independent_review'),
  evidence_case_id uuid NOT NULL REFERENCES public.vendor_intake_cases(id),
  cleared_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz NOT NULL CHECK(expires_at > cleared_at),
  CHECK(identity_reviewer <> approving_officer)
);

ALTER TABLE public.vendor_intake_cases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vendor_intake_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vendor_activation_clearances ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.vendor_intake_cases FROM PUBLIC,anon,authenticated;
REVOKE ALL ON public.vendor_intake_events FROM PUBLIC,anon,authenticated;
REVOKE ALL ON public.vendor_activation_clearances FROM PUBLIC,anon,authenticated;
GRANT SELECT ON public.vendor_intake_cases TO authenticated;
GRANT SELECT ON public.vendor_intake_events TO authenticated;

CREATE POLICY intake_owner_or_admin ON public.vendor_intake_cases
 FOR SELECT TO authenticated
 USING (applicant_id=auth.uid() OR public.is_admin(auth.uid()));
CREATE POLICY intake_events_owner_or_admin ON public.vendor_intake_events
 FOR SELECT TO authenticated
 USING (EXISTS (SELECT 1 FROM public.vendor_intake_cases c WHERE c.id=case_id
  AND (c.applicant_id=auth.uid() OR public.is_admin(auth.uid()))));

-- Only allow a known, category-relevant list of metadata fields. Inputs are
-- identifiers and equipment descriptors, NOT full identity/tax numbers.
CREATE OR REPLACE FUNCTION public.vendor_intake_metadata_valid(p_kind text,p_details jsonb)
RETURNS boolean LANGUAGE plpgsql IMMUTABLE SET search_path=public AS $$
DECLARE v_key text; v_val jsonb;
BEGIN
  IF jsonb_typeof(p_details)<>'object' OR
    (SELECT count(*) FROM jsonb_object_keys(p_details))>16 THEN RETURN false; END IF;
  FOR v_key,v_val IN SELECT key,value FROM jsonb_each(p_details) LOOP
    IF v_key NOT IN (
      'vehicle_type','vehicle_make','vehicle_model','vehicle_year','vehicle_plate',
      'vehicle_registration_expiry','driver_licence_class','driver_licence_expiry',
      'insurance_expiry','food_handling_permit_expiry','food_premises_type',
      'trade_speciality','trade_licence_expiry','professional_registration_expiry',
      'equipment_type','equipment_make','equipment_model','equipment_serial',
      'equipment_inspection_expiry','operator_qualification_expiry'
    ) THEN RETURN false; END IF;
    IF jsonb_typeof(v_val)<>'string' OR length(v_val #>> '{}')>120
      OR length(v_val #>> '{}')<1 THEN RETURN false; END IF;
  END LOOP;
  IF p_details ? 'vehicle_year' AND
    (p_details->>'vehicle_year') !~ '^[12][0-9]{3}$' THEN RETURN false; END IF;
  IF p_details ? 'vehicle_plate' AND
    (p_details->>'vehicle_plate') !~ '^[A-Za-z0-9 -]{2,25}$' THEN RETURN false; END IF;
  RETURN true;
EXCEPTION WHEN OTHERS THEN RETURN false;
END $$;

CREATE OR REPLACE FUNCTION public.submit_vendor_intake_case(
 p_category_slug text,p_kind text,p_display_name text,p_country_code text,
 p_region text,p_locality text,p_street_address text,
 p_email text,p_phone text,p_identity_type text,p_identity_last_four text,
 p_business_registration text,p_tax_reference_last_four text,
 p_summary text,p_metadata jsonb
) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER
SET search_path=public,auth AS $$
DECLARE v_category uuid; v_case uuid;
BEGIN
 IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Sign in required'
   USING errcode='28000'; END IF;
 SELECT c.id INTO v_category FROM public.service_categories c
 LEFT JOIN public.provider_onboarding_policies p ON p.category_id=c.id
 WHERE c.is_active
   AND c.slug=lower(btrim(coalesce(p_category_slug,'')))
   AND coalesce(p.intake_status,'staged')='staged'
   AND c.slug NOT IN ('financial-services','health-medical');
 IF v_category IS NULL THEN
   RAISE EXCEPTION 'This category is not currently accepting applications'
     USING errcode='22023'; END IF;
 IF p_kind NOT IN ('individual','business')
   OR p_identity_type NOT IN ('national_id','passport','drivers_licence','other')
   OR length(btrim(coalesce(p_display_name,''))) NOT BETWEEN 2 AND 120
   OR coalesce(p_country_code,'') !~ '^[A-Z]{2}$'
   OR length(btrim(coalesce(p_region,''))) NOT BETWEEN 2 AND 120
   OR length(btrim(coalesce(p_locality,''))) NOT BETWEEN 2 AND 120
   OR length(btrim(coalesce(p_street_address,''))) NOT BETWEEN 5 AND 240
   OR length(btrim(coalesce(p_email,''))) NOT BETWEEN 5 AND 240
   OR p_email !~* '^[^ @]+@[^ @]+[.][^ @]+$'
   OR length(btrim(coalesce(p_phone,''))) NOT BETWEEN 7 AND 35
   OR length(btrim(coalesce(p_summary,''))) NOT BETWEEN 10 AND 1200
   OR (nullif(btrim(coalesce(p_identity_last_four,'')),'') IS NOT NULL AND
     btrim(p_identity_last_four) !~ '^[A-Za-z0-9]{4}$')
   OR (nullif(btrim(coalesce(p_tax_reference_last_four,'')),'') IS NOT NULL AND
     btrim(p_tax_reference_last_four) !~ '^[A-Za-z0-9]{4}$')
   OR (p_kind='business' AND (length(btrim(coalesce(p_business_registration,'')))
        NOT BETWEEN 3 AND 70 OR p_tax_reference_last_four IS NULL))
   OR NOT public.vendor_intake_metadata_valid(p_kind,coalesce(p_metadata,'{}'::jsonb))
 THEN RAISE EXCEPTION 'Application details are incomplete or invalid'
   USING errcode='22023'; END IF;
 IF EXISTS (SELECT 1 FROM public.vendor_intake_cases
    WHERE applicant_id=auth.uid() AND category_id=v_category
      AND status IN ('submitted','in_review','needs_information')) THEN
   RAISE EXCEPTION 'An open application already exists for this category'
   USING errcode='23505'; END IF;
 INSERT INTO public.vendor_intake_cases (
    applicant_id,category_id,applicant_kind,display_name,country_code,
    region,locality,street_address,contact_email,contact_phone,
    applicant_identity_type,identity_last_four,business_registration,
    tax_reference_last_four,service_summary,service_metadata)
 VALUES(auth.uid(),v_category,p_kind,btrim(p_display_name),p_country_code,
   btrim(p_region),btrim(p_locality),btrim(p_street_address),
   lower(btrim(p_email)),btrim(p_phone),p_identity_type,
   nullif(btrim(coalesce(p_identity_last_four,'')),''),
   nullif(btrim(coalesce(p_business_registration,'')),''),
   nullif(btrim(coalesce(p_tax_reference_last_four,'')),''),
   btrim(p_summary),coalesce(p_metadata,'{}'::jsonb))
 RETURNING id INTO v_case;
 INSERT INTO public.vendor_intake_events(case_id,actor_id,event_type,next_status)
 VALUES(v_case,auth.uid(),'submitted','submitted');
 RETURN v_case;
END $$;

CREATE OR REPLACE FUNCTION public.triage_vendor_intake_case(
 p_case_id uuid,p_action text,p_reason text DEFAULT NULL
) RETURNS public.vendor_intake_cases
LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,auth AS $$
DECLARE v_case public.vendor_intake_cases%ROWTYPE; v_next text; v_event text;
BEGIN
 IF auth.uid() IS NULL OR NOT public.is_admin(auth.uid()) THEN
   RAISE EXCEPTION 'Operations reviewer required' USING errcode='42501'; END IF;
 SELECT * INTO v_case FROM public.vendor_intake_cases
   WHERE id=p_case_id FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Application not found'; END IF;
 IF p_action='start_review' AND v_case.status='submitted' THEN
   v_next:='in_review';v_event:='review_started';
 ELSIF p_action='request_information' AND v_case.status IN ('submitted','in_review')
   AND length(btrim(coalesce(p_reason,''))) BETWEEN 10 AND 1000 THEN
   v_next:='needs_information';v_event:='information_requested';
 ELSIF p_action='decline' AND v_case.status IN
   ('submitted','in_review','needs_information')
   AND length(btrim(coalesce(p_reason,''))) BETWEEN 10 AND 1000 THEN
   v_next:='declined';v_event:='declined';
 ELSE RAISE EXCEPTION 'Invalid application state or missing explanation'
   USING errcode='22023'; END IF;
 UPDATE public.vendor_intake_cases SET status=v_next,
   assigned_reviewer=coalesce(assigned_reviewer,auth.uid()),
   reviewed_at=now(),updated_at=now()
 WHERE id=p_case_id RETURNING * INTO v_case;
 INSERT INTO public.vendor_intake_events(
   case_id,actor_id,event_type,previous_status,next_status,reason)
 VALUES(p_case_id,auth.uid(),v_event,
   CASE WHEN v_event='review_started' THEN 'submitted'
        WHEN v_event='information_requested' THEN
          CASE WHEN v_case.assigned_reviewer IS NULL THEN 'submitted' ELSE 'in_review' END
        ELSE 'in_review' END,
   v_next,nullif(btrim(coalesce(p_reason,'')),''));
 RETURN v_case;
END $$;

-- Legacy acceptance no longer grants a provider/driver permission and cannot
-- imply identity verification. No previously approved record is modified.
CREATE OR REPLACE FUNCTION public.review_provider_application(
 p_application_id uuid,p_decision text
) RETURNS public.provider_applications
LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,auth AS $$
DECLARE v_row public.provider_applications%ROWTYPE;
BEGIN
 IF auth.uid() IS NULL OR NOT public.is_admin(auth.uid()) THEN
   RAISE EXCEPTION 'Operations reviewer required' USING errcode='42501'; END IF;
 IF p_decision NOT IN ('approved','rejected') THEN
   RAISE EXCEPTION 'Decision must be approved or rejected' USING errcode='22023'; END IF;
 UPDATE public.provider_applications
 SET status=p_decision,reviewed_by=auth.uid(),reviewed_at=now()
 WHERE id=p_application_id AND status='pending' RETURNING * INTO v_row;
 IF NOT FOUND THEN RAISE EXCEPTION 'Pending application not found' USING errcode='22023'; END IF;
 -- Deliberately no changes to profiles, driver_profiles, provider_profiles or listings.
 RETURN v_row;
END $$;

-- New activation requires independent and unexpired clearance, never just a
-- verified flag or a single administrator's approval.
CREATE OR REPLACE FUNCTION public.admin_set_provider_service_status(
 p_service_id uuid,p_status text
) RETURNS public.provider_services
LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,auth AS $$
DECLARE v_service public.provider_services%ROWTYPE;
BEGIN
 IF auth.uid() IS NULL OR NOT public.is_admin(auth.uid()) THEN
   RAISE EXCEPTION 'Operations reviewer required' USING errcode='42501'; END IF;
 IF p_status NOT IN ('draft','pending_review','active','paused','rejected') THEN
   RAISE EXCEPTION 'Invalid status' USING errcode='22023'; END IF;
 SELECT * INTO v_service FROM public.provider_services
   WHERE id=p_service_id FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Service not found' USING errcode='22023'; END IF;
 IF p_status='active' AND v_service.status<>'active' AND NOT EXISTS (
   SELECT 1 FROM public.vendor_activation_clearances clearance
   JOIN public.provider_profiles p ON p.provider_id=clearance.provider_id
   WHERE clearance.provider_id=v_service.provider_id
     AND clearance.expires_at>now() AND p.is_active
     AND p.verification_status='verified'
 ) THEN RAISE EXCEPTION
    'Independent identity clearance required before activation'
    USING errcode='42501'; END IF;
 UPDATE public.provider_services SET status=p_status
 WHERE id=p_service_id RETURNING * INTO v_service;
 RETURN v_service;
END $$;

REVOKE ALL ON FUNCTION public.submit_vendor_intake_case(
 text,text,text,text,text,text,text,text,text,text,text,text,text,text,jsonb)
 FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.submit_vendor_intake_case(
 text,text,text,text,text,text,text,text,text,text,text,text,text,text,jsonb)
 TO authenticated;
REVOKE ALL ON FUNCTION public.triage_vendor_intake_case(uuid,text,text)
 FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.triage_vendor_intake_case(uuid,text,text)
 TO authenticated;
REVOKE ALL ON FUNCTION public.vendor_intake_metadata_valid(text,jsonb)
 FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.review_provider_application(uuid,text)
 FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.review_provider_application(uuid,text)
 TO authenticated;
REVOKE ALL ON FUNCTION public.admin_set_provider_service_status(uuid,text)
 FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.admin_set_provider_service_status(uuid,text)
 TO authenticated;
COMMENT ON TABLE public.vendor_intake_cases IS
 'Restricted pending applications only. No document upload, KYC approval, provider role, booking or payment activation.';
