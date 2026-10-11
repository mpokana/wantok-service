-- International compliance policy governance; NO legal approval or upload grants.
-- All states are non-operative; formal jurisdictional/legal release is separate.
CREATE TABLE public.vendor_policy_drafts (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 country_code text NOT NULL CHECK(country_code ~ '^[A-Z]{2}$'),
 region_code text CHECK(region_code IS NULL OR
   region_code ~ '^[A-Z]{2}-[A-Z0-9]{1,6}$'),
 category_scope text NOT NULL CHECK(category_scope IN
   ('all','transport','food','trades','equipment','accommodation','other')),
 revision integer NOT NULL DEFAULT 1 CHECK(revision > 0),
 notice_title text NOT NULL CHECK(length(btrim(notice_title)) BETWEEN 12 AND 150),
 notice_body text NOT NULL CHECK(length(btrim(notice_body)) BETWEEN 80 AND 5000),
 collection_purpose text NOT NULL CHECK(length(btrim(collection_purpose)) BETWEEN 30 AND 1500),
 legal_basis_notes text NOT NULL CHECK(length(btrim(legal_basis_notes)) BETWEEN 30 AND 1500),
 retention_days integer NOT NULL CHECK(retention_days BETWEEN 1 AND 3650),
 evidence_requirements jsonb NOT NULL CHECK(
   jsonb_typeof(evidence_requirements)='array'
   AND jsonb_array_length(evidence_requirements) BETWEEN 1 AND 16),
 state text NOT NULL DEFAULT 'draft' CHECK(state IN
   ('draft','submitted','revision_requested','internal_review_complete')),
 created_by uuid NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
 reviewer_id uuid REFERENCES auth.users(id) ON DELETE RESTRICT,
 reviewer_notes text CHECK(reviewer_notes IS NULL OR
   length(btrim(reviewer_notes)) BETWEEN 20 AND 1500),
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 submitted_at timestamptz,
 reviewed_at timestamptz,
 updated_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 -- Only metadata for administrative review, NOT legal-effect dates.
 CONSTRAINT vendor_policy_distinct_reviewers CHECK(
   reviewer_id IS NULL OR reviewer_id<>created_by),
 CONSTRAINT vendor_policy_state_consistency CHECK(
  (state='draft' AND submitted_at IS NULL AND reviewer_id IS NULL
    AND reviewed_at IS NULL AND reviewer_notes IS NULL)
  OR (state='submitted' AND submitted_at IS NOT NULL
    AND reviewer_id IS NULL AND reviewed_at IS NULL AND reviewer_notes IS NULL)
  OR (state IN ('revision_requested','internal_review_complete')
    AND submitted_at IS NOT NULL AND reviewer_id IS NOT NULL
    AND reviewed_at IS NOT NULL AND reviewer_notes IS NOT NULL))
);
CREATE INDEX vendor_policy_country_scope_idx
 ON public.vendor_policy_drafts(country_code,region_code,category_scope,created_at DESC);
CREATE TABLE public.vendor_policy_events (
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 policy_id uuid NOT NULL REFERENCES public.vendor_policy_drafts(id) ON DELETE RESTRICT,
 actor_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
 event_type text NOT NULL CHECK(event_type IN
   ('draft_created','submitted','revision_requested','internal_review_complete')),
 prior_state text,
 next_state text NOT NULL,
 notes text CHECK(notes IS NULL OR length(btrim(notes)) BETWEEN 20 AND 1500),
 recorded_at timestamptz NOT NULL DEFAULT clock_timestamp()
);
CREATE INDEX vendor_policy_events_idx ON public.vendor_policy_events(policy_id,recorded_at DESC);
ALTER TABLE public.vendor_policy_drafts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vendor_policy_events ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.vendor_policy_drafts FROM PUBLIC,anon,authenticated;
REVOKE ALL ON public.vendor_policy_events FROM PUBLIC,anon,authenticated;
GRANT SELECT ON public.vendor_policy_drafts TO authenticated;
GRANT SELECT ON public.vendor_policy_events TO authenticated;
CREATE POLICY policy_admin_read ON public.vendor_policy_drafts FOR SELECT
 TO authenticated USING(public.is_admin(auth.uid()));
CREATE POLICY policy_events_admin_read ON public.vendor_policy_events FOR SELECT
 TO authenticated USING(public.is_admin(auth.uid()));

CREATE OR REPLACE FUNCTION public.create_vendor_policy_draft(
 p_country_code text,p_region_code text,p_category_scope text,
 p_notice_title text,p_notice_body text,p_collection_purpose text,
 p_legal_basis_notes text,p_retention_days integer,
 p_evidence_requirements jsonb
) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER
 SET search_path=public,auth AS $$
DECLARE v_id uuid;
BEGIN
 IF auth.uid() IS NULL OR NOT public.is_admin(auth.uid()) THEN
  RAISE EXCEPTION 'Operations policy administrator required' USING errcode='42501';
 END IF;
 IF p_country_code IS NULL OR p_country_code !~ '^[A-Z]{2}$'
    OR (p_region_code IS NOT NULL AND
        (p_region_code !~ '^[A-Z]{2}-[A-Z0-9]{1,6}$'
        OR left(p_region_code,2)<>p_country_code))
    OR p_category_scope NOT IN
     ('all','transport','food','trades','equipment','accommodation','other')
    OR length(btrim(coalesce(p_notice_title,''))) NOT BETWEEN 12 AND 150
    OR length(btrim(coalesce(p_notice_body,''))) NOT BETWEEN 80 AND 5000
    OR length(btrim(coalesce(p_collection_purpose,''))) NOT BETWEEN 30 AND 1500
    OR length(btrim(coalesce(p_legal_basis_notes,''))) NOT BETWEEN 30 AND 1500
    OR p_retention_days NOT BETWEEN 1 AND 3650
    OR jsonb_typeof(p_evidence_requirements) IS DISTINCT FROM 'array'
    OR jsonb_array_length(p_evidence_requirements) NOT BETWEEN 1 AND 16
    OR EXISTS(SELECT 1 FROM jsonb_array_elements(p_evidence_requirements) item
      WHERE jsonb_typeof(item)<>'string'
      OR length(btrim(item #>> '{}')) NOT BETWEEN 5 AND 120)
 THEN RAISE EXCEPTION 'Policy draft details are incomplete or invalid'
  USING errcode='22023'; END IF;
 INSERT INTO public.vendor_policy_drafts(
  country_code,region_code,category_scope,notice_title,notice_body,
  collection_purpose,legal_basis_notes,retention_days,
  evidence_requirements,created_by)
 VALUES(p_country_code,p_region_code,p_category_scope,
   btrim(p_notice_title),btrim(p_notice_body),btrim(p_collection_purpose),
   btrim(p_legal_basis_notes),p_retention_days,p_evidence_requirements,auth.uid())
 RETURNING id INTO v_id;
 INSERT INTO public.vendor_policy_events(
   policy_id,actor_id,event_type,next_state)
 VALUES(v_id,auth.uid(),'draft_created','draft');
 RETURN v_id;
END $$;

CREATE OR REPLACE FUNCTION public.submit_vendor_policy_draft(p_policy_id uuid)
RETURNS public.vendor_policy_drafts LANGUAGE plpgsql SECURITY DEFINER
 SET search_path=public,auth AS $$
DECLARE v_row public.vendor_policy_drafts%ROWTYPE;
BEGIN
 IF auth.uid() IS NULL OR NOT public.is_admin(auth.uid()) THEN
  RAISE EXCEPTION 'Operations policy administrator required' USING errcode='42501';
 END IF;
 SELECT * INTO v_row FROM public.vendor_policy_drafts
   WHERE id=p_policy_id FOR UPDATE;
 IF NOT FOUND OR v_row.created_by<>auth.uid() OR v_row.state<>'draft' THEN
  RAISE EXCEPTION 'Draft is unavailable for submission' USING errcode='42501';
 END IF;
 UPDATE public.vendor_policy_drafts
  SET state='submitted',submitted_at=clock_timestamp(),
  updated_at=clock_timestamp()
 WHERE id=p_policy_id RETURNING * INTO v_row;
 INSERT INTO public.vendor_policy_events(
   policy_id,actor_id,event_type,prior_state,next_state)
 VALUES(p_policy_id,auth.uid(),'submitted','draft','submitted');
 RETURN v_row;
END $$;

CREATE OR REPLACE FUNCTION public.review_vendor_policy_draft(
 p_policy_id uuid,p_decision text,p_notes text
) RETURNS public.vendor_policy_drafts LANGUAGE plpgsql SECURITY DEFINER
 SET search_path=public,auth AS $$
DECLARE v_row public.vendor_policy_drafts%ROWTYPE;
BEGIN
 IF auth.uid() IS NULL OR NOT public.is_admin(auth.uid()) THEN
  RAISE EXCEPTION 'Operations policy reviewer required' USING errcode='42501';
 END IF;
 IF p_decision NOT IN ('revision_requested','internal_review_complete')
 OR length(btrim(coalesce(p_notes,''))) NOT BETWEEN 20 AND 1500 THEN
  RAISE EXCEPTION 'Independent decision and reason are required'
   USING errcode='22023'; END IF;
 SELECT * INTO v_row FROM public.vendor_policy_drafts
  WHERE id=p_policy_id FOR UPDATE;
 IF NOT FOUND OR v_row.state<>'submitted' OR
    v_row.created_by=auth.uid() THEN
  RAISE EXCEPTION 'Independent reviewer required for submitted draft'
   USING errcode='42501';
 END IF;
 UPDATE public.vendor_policy_drafts
 SET state=p_decision,reviewer_id=auth.uid(),reviewer_notes=btrim(p_notes),
   reviewed_at=clock_timestamp(),updated_at=clock_timestamp()
 WHERE id=p_policy_id RETURNING * INTO v_row;
 INSERT INTO public.vendor_policy_events(
  policy_id,actor_id,event_type,prior_state,next_state,notes)
 VALUES(p_policy_id,auth.uid(),p_decision,'submitted',p_decision,btrim(p_notes));
 RETURN v_row;
END $$;

REVOKE ALL ON FUNCTION public.create_vendor_policy_draft(
 text,text,text,text,text,text,text,integer,jsonb) FROM PUBLIC,anon;
REVOKE ALL ON FUNCTION public.submit_vendor_policy_draft(uuid) FROM PUBLIC,anon;
REVOKE ALL ON FUNCTION public.review_vendor_policy_draft(uuid,text,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.create_vendor_policy_draft(
 text,text,text,text,text,text,text,integer,jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.submit_vendor_policy_draft(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.review_vendor_policy_draft(uuid,text,text)
 TO authenticated;

COMMENT ON TABLE public.vendor_policy_drafts IS
 'Internal country/region/service governance candidates only. No state publishes to applicants or grants legal consent, uploads, clearance or provider activation.';
