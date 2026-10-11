-- E6B: canonical case jurisdictions, scoped preliminary review and request metadata.
-- Existing applicant submissions, evidence custody, clearances and live services are unchanged.
-- An unclassified case is DENIED to staff. Raw free-text region is NEVER treated as ISO.
ALTER TABLE public.operations_duty_grants
 DROP CONSTRAINT operations_duty_grants_duty_check;
ALTER TABLE public.operations_duty_grants
 ADD CONSTRAINT operations_duty_grants_duty_check CHECK (duty IN (
  'policy_author','policy_reviewer','case_reviewer','evidence_officer',
  'final_approver','safety_investigator'));

CREATE OR REPLACE FUNCTION public.has_operations_scope(
 p_duty text,p_country_code text,p_region_code text,p_category_scope text
) RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
 SET search_path=public,auth AS $$
 SELECT auth.uid() IS NOT NULL AND p_duty IN (
  'policy_author','policy_reviewer','case_reviewer','evidence_officer',
  'final_approver','safety_investigator')
 AND p_country_code ~ '^[A-Z]{2}$'
 AND (p_region_code IS NULL OR
  (p_region_code ~ '^[A-Z]{2}-[A-Z0-9]{1,6}$'
   AND left(p_region_code,2)=p_country_code))
 AND p_category_scope IN (
  'all','transport','food','trades','equipment','accommodation','other')
 AND EXISTS (
  SELECT 1 FROM public.operations_duty_grants g
  WHERE g.staff_user_id=auth.uid()
  AND g.duty=p_duty AND g.country_code=p_country_code
  AND g.revoked_at IS NULL
  AND g.issued_at<=statement_timestamp()
  AND (g.expires_at IS NULL OR g.expires_at>statement_timestamp())
  AND (g.region_code IS NULL OR g.region_code=p_region_code)
  AND (g.category_scope='all' OR g.category_scope=p_category_scope)
 );
$$;

-- Trusted, audited mapping of existing service categories to the finite policy
-- taxonomy. No guesses from category slug, applicant category text or regex.
CREATE TABLE public.operations_service_category_scopes (
 category_id uuid PRIMARY KEY REFERENCES public.service_categories(id) ON DELETE RESTRICT,
 category_scope text NOT NULL CHECK(category_scope IN
  ('transport','food','trades','equipment','accommodation','other')),
 classified_by uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
 classification_reason text NOT NULL CHECK(length(btrim(classification_reason)) BETWEEN 20 AND 1000),
 reviewed_at timestamptz NOT NULL DEFAULT clock_timestamp()
);
CREATE TABLE public.operations_case_jurisdictions (
 case_id uuid PRIMARY KEY REFERENCES public.vendor_intake_cases(id) ON DELETE RESTRICT,
 country_code text NOT NULL CHECK(country_code ~ '^[A-Z]{2}$'),
 region_code text NOT NULL CHECK(region_code ~ '^[A-Z]{2}-[A-Z0-9]{1,6}$'),
 category_scope text NOT NULL CHECK(category_scope IN
  ('transport','food','trades','equipment','accommodation','other')),
 classified_by uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
 classification_reason text NOT NULL CHECK(length(btrim(classification_reason)) BETWEEN 20 AND 1000),
 reviewed_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 CONSTRAINT case_jurisdiction_country CHECK(left(region_code,2)=country_code)
);
CREATE TABLE public.operations_case_jurisdiction_events (
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 case_id uuid NOT NULL REFERENCES public.vendor_intake_cases(id) ON DELETE RESTRICT,
 prior_region_code text,
 new_region_code text NOT NULL,
 prior_category_scope text,
 new_category_scope text NOT NULL,
 classified_by uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
 reason text NOT NULL CHECK(length(btrim(reason)) BETWEEN 20 AND 1000),
 occurred_at timestamptz NOT NULL DEFAULT clock_timestamp()
);
ALTER TABLE public.operations_service_category_scopes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.operations_case_jurisdictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.operations_case_jurisdiction_events ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.operations_service_category_scopes FROM PUBLIC,anon,authenticated;
REVOKE ALL ON public.operations_case_jurisdictions FROM PUBLIC,anon,authenticated;
REVOKE ALL ON public.operations_case_jurisdiction_events FROM PUBLIC,anon,authenticated;

-- Only the backend with a trusted service_role credential may certify the
-- category mapping and ISO subdivision after checking the source material.
CREATE FUNCTION public.map_operations_service_category(
 p_category_id uuid,p_scope text,p_operator_id uuid,p_reason text
) RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER
 SET search_path=public,auth AS $$
BEGIN
 IF p_scope NOT IN ('transport','food','trades','equipment','accommodation','other')
    OR length(btrim(coalesce(p_reason,''))) NOT BETWEEN 20 AND 1000
    OR NOT EXISTS(SELECT 1 FROM public.profiles WHERE id=p_operator_id)
    OR NOT EXISTS(SELECT 1 FROM public.service_categories WHERE id=p_category_id) THEN
   RAISE EXCEPTION 'Independent classification evidence required' USING errcode='22023';
 END IF;
 INSERT INTO public.operations_service_category_scopes(
  category_id,category_scope,classified_by,classification_reason)
 VALUES(p_category_id,p_scope,p_operator_id,btrim(p_reason))
 ON CONFLICT (category_id) DO UPDATE
 SET category_scope=EXCLUDED.category_scope,classified_by=EXCLUDED.classified_by,
     classification_reason=EXCLUDED.classification_reason,
     reviewed_at=clock_timestamp();
 RETURN true;
END $$;

CREATE FUNCTION public.register_operations_case_jurisdiction(
 p_case_id uuid,p_region_code text,p_operator_id uuid,p_reason text
) RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER
 SET search_path=public,auth AS $$
DECLARE v_case public.vendor_intake_cases%ROWTYPE;
 v_category text;v_prior public.operations_case_jurisdictions%ROWTYPE;
BEGIN
 SELECT * INTO v_case FROM public.vendor_intake_cases WHERE id=p_case_id FOR UPDATE;
 SELECT category_scope INTO v_category FROM public.operations_service_category_scopes
 WHERE category_id=v_case.category_id;
 IF NOT FOUND OR v_case.id IS NULL OR v_category IS NULL
 OR p_region_code IS NULL OR p_region_code !~ '^[A-Z]{2}-[A-Z0-9]{1,6}$'
 OR left(p_region_code,2)<>v_case.country_code
 OR length(btrim(coalesce(p_reason,''))) NOT BETWEEN 20 AND 1000
 OR NOT EXISTS(SELECT 1 FROM public.profiles WHERE id=p_operator_id) THEN
  RAISE EXCEPTION 'Verified case jurisdiction and category mapping required'
   USING errcode='22023';
 END IF;
 SELECT * INTO v_prior FROM public.operations_case_jurisdictions
 WHERE case_id=p_case_id FOR UPDATE;
 INSERT INTO public.operations_case_jurisdictions(
  case_id,country_code,region_code,category_scope,classified_by,classification_reason)
 VALUES(p_case_id,v_case.country_code,p_region_code,v_category,p_operator_id,btrim(p_reason))
 ON CONFLICT (case_id) DO UPDATE
 SET country_code=EXCLUDED.country_code,region_code=EXCLUDED.region_code,
  category_scope=EXCLUDED.category_scope,classified_by=EXCLUDED.classified_by,
  classification_reason=EXCLUDED.classification_reason,reviewed_at=clock_timestamp();
 INSERT INTO public.operations_case_jurisdiction_events(
  case_id,prior_region_code,new_region_code,prior_category_scope,
  new_category_scope,classified_by,reason)
 VALUES(p_case_id,v_prior.region_code,p_region_code,v_prior.category_scope,
        v_category,p_operator_id,btrim(p_reason));
 RETURN true;
END $$;
REVOKE ALL ON FUNCTION public.map_operations_service_category(uuid,text,uuid,text)
 FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.register_operations_case_jurisdiction(uuid,text,uuid,text)
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.map_operations_service_category(uuid,text,uuid,text)
 TO service_role;
GRANT EXECUTE ON FUNCTION public.register_operations_case_jurisdiction(uuid,text,uuid,text)
 TO service_role;

CREATE FUNCTION public.has_operations_case_scope(p_duty text,p_case_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
 SET search_path=public,auth AS $$
 SELECT auth.uid() IS NOT NULL
 AND p_duty IN ('case_reviewer','evidence_officer')
 AND EXISTS (
  SELECT 1 FROM public.vendor_intake_cases c
  JOIN public.operations_case_jurisdictions j ON j.case_id=c.id
  JOIN public.operations_service_category_scopes m ON m.category_id=c.category_id
  WHERE c.id=p_case_id AND c.country_code=j.country_code
    AND j.category_scope=m.category_scope
    AND public.has_operations_scope(
     p_duty,j.country_code,j.region_code,j.category_scope)
 );
$$;
REVOKE ALL ON FUNCTION public.has_operations_case_scope(text,uuid)
 FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.has_operations_case_scope(text,uuid)
 TO authenticated;

-- Replace every broad legacy admin read for this case workflow. Applicants
-- retain their own case/request reads, not internal review/checklist reads.
DROP POLICY intake_owner_or_admin ON public.vendor_intake_cases;
CREATE POLICY intake_owner_or_scoped_staff ON public.vendor_intake_cases
 FOR SELECT TO authenticated USING (
  applicant_id=auth.uid()
  OR public.has_operations_case_scope('case_reviewer',id)
  OR public.has_operations_case_scope('evidence_officer',id));
DROP POLICY intake_events_owner_or_admin ON public.vendor_intake_events;
CREATE POLICY intake_events_owner_or_scoped_staff ON public.vendor_intake_events
 FOR SELECT TO authenticated USING (EXISTS(
  SELECT 1 FROM public.vendor_intake_cases c WHERE c.id=case_id AND (
    c.applicant_id=auth.uid()
    OR public.has_operations_case_scope('case_reviewer',c.id)
    OR public.has_operations_case_scope('evidence_officer',c.id))));
DROP POLICY verification_checks_operations_read ON public.vendor_verification_checks;
CREATE POLICY verification_checks_scoped_read ON public.vendor_verification_checks
 FOR SELECT TO authenticated USING(
  public.has_operations_case_scope('case_reviewer',case_id)
  OR public.has_operations_case_scope('evidence_officer',case_id));
DROP POLICY verification_events_operations_read ON public.vendor_verification_check_events;
CREATE POLICY verification_events_scoped_read ON public.vendor_verification_check_events
 FOR SELECT TO authenticated USING(
  public.has_operations_case_scope('case_reviewer',case_id)
  OR public.has_operations_case_scope('evidence_officer',case_id));
DROP POLICY evidence_requests_owner_or_operations ON public.vendor_evidence_requests;
CREATE POLICY evidence_requests_owner_or_scoped_staff ON public.vendor_evidence_requests
 FOR SELECT TO authenticated USING (
  public.has_operations_case_scope('case_reviewer',case_id)
  OR public.has_operations_case_scope('evidence_officer',case_id)
  OR EXISTS (SELECT 1 FROM public.vendor_intake_cases c
    WHERE c.id=case_id AND c.applicant_id=auth.uid()));
DROP POLICY evidence_events_owner_or_operations ON public.vendor_evidence_request_events;
CREATE POLICY evidence_events_owner_or_scoped_staff
 ON public.vendor_evidence_request_events FOR SELECT TO authenticated
 USING (EXISTS(
  SELECT 1 FROM public.vendor_evidence_requests req
  JOIN public.vendor_intake_cases c ON c.id=req.case_id
  WHERE req.id=request_id AND (
   c.applicant_id=auth.uid()
   OR public.has_operations_case_scope('case_reviewer',c.id)
   OR public.has_operations_case_scope('evidence_officer',c.id))));

-- Reuse the existing audited state machine but replace the broad role gate.
-- The classification record MUST exist, even if an employee has a country-wide duty.
CREATE OR REPLACE FUNCTION public.triage_vendor_intake_case(
 p_case_id uuid,p_action text,p_reason text DEFAULT NULL
) RETURNS public.vendor_intake_cases
 LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,auth AS $$
DECLARE v_case public.vendor_intake_cases%ROWTYPE;
 v_prior text;v_next text;v_event text;
BEGIN
 IF auth.uid() IS NULL OR NOT public.has_operations_case_scope('case_reviewer',p_case_id) THEN
  RAISE EXCEPTION 'Scoped case reviewer required' USING errcode='42501'; END IF;
 SELECT * INTO v_case FROM public.vendor_intake_cases WHERE id=p_case_id FOR UPDATE;
 IF NOT FOUND OR v_case.applicant_id=auth.uid()
 OR (v_case.assigned_reviewer IS NOT NULL
     AND v_case.assigned_reviewer<>auth.uid()) THEN
  RAISE EXCEPTION 'Case not assigned to this reviewer' USING errcode='42501'; END IF;
 v_prior:=v_case.status;
 IF p_action='start_review' AND v_prior='submitted' THEN
  v_next:='in_review';v_event:='review_started';
 ELSIF p_action='request_information' AND v_prior IN ('submitted','in_review')
  AND length(btrim(coalesce(p_reason,''))) BETWEEN 10 AND 1000 THEN
  v_next:='needs_information';v_event:='information_requested';
 ELSIF p_action='decline' AND v_prior IN
 ('submitted','in_review','needs_information')
 AND length(btrim(coalesce(p_reason,''))) BETWEEN 10 AND 1000 THEN
  v_next:='declined';v_event:='declined';
 ELSE RAISE EXCEPTION 'Invalid application state or missing explanation'
   USING errcode='22023'; END IF;
 UPDATE public.vendor_intake_cases SET status=v_next,
 assigned_reviewer=coalesce(assigned_reviewer,auth.uid()),
 reviewed_at=clock_timestamp(),updated_at=clock_timestamp()
 WHERE id=p_case_id RETURNING * INTO v_case;
 INSERT INTO public.vendor_intake_events(
  case_id,actor_id,event_type,previous_status,next_status,reason)
 VALUES(p_case_id,auth.uid(),v_event,v_prior,v_next,
 nullif(btrim(coalesce(p_reason,'')),''));
 RETURN v_case;
END $$;

CREATE OR REPLACE FUNCTION public.record_vendor_verification_review(
 p_check_id uuid,p_action text,p_rationale text
) RETURNS public.vendor_verification_checks
 LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,auth AS $$
DECLARE v_check public.vendor_verification_checks%ROWTYPE;
 v_case public.vendor_intake_cases%ROWTYPE;
 v_previous text;v_next text;v_event text;
BEGIN
 IF length(btrim(coalesce(p_rationale,''))) NOT BETWEEN 15 AND 1000 THEN
  RAISE EXCEPTION 'A 15-1000 character review rationale is required'
   USING errcode='22023'; END IF;
 SELECT * INTO v_check FROM public.vendor_verification_checks
 WHERE id=p_check_id FOR UPDATE;
 IF NOT FOUND OR NOT public.has_operations_case_scope('case_reviewer',v_check.case_id) THEN
  RAISE EXCEPTION 'Scoped case reviewer required' USING errcode='42501'; END IF;
 SELECT * INTO v_case FROM public.vendor_intake_cases
 WHERE id=v_check.case_id FOR UPDATE;
 IF v_case.status<>'in_review' THEN
  RAISE EXCEPTION 'The case must be in review' USING errcode='22023'; END IF;
 IF v_case.applicant_id=auth.uid() THEN
  RAISE EXCEPTION 'Applicants cannot review their own cases' USING errcode='42501'; END IF;
 v_previous:=v_check.state;
 IF p_action='start' AND v_previous IN ('pending','needs_followup') THEN
  v_next:='in_review';v_event:='started';
 ELSIF p_action='followup' AND v_previous IN ('pending','in_review') THEN
  v_next:='needs_followup';v_event:='followup_requested';
 ELSIF p_action='record_first' AND v_previous='in_review' THEN
  IF v_case.assigned_reviewer IS DISTINCT FROM auth.uid() THEN
   RAISE EXCEPTION 'Only the assigned case reviewer can record the first review'
   USING errcode='42501'; END IF;
  v_next:='first_review_recorded';v_event:='first_review_recorded';
 ELSIF p_action='record_second' AND v_previous='first_review_recorded' THEN
  IF v_check.first_reviewer=auth.uid() OR v_check.first_reviewer IS NULL THEN
   RAISE EXCEPTION 'An independent second reviewer is required'
    USING errcode='42501'; END IF;
  v_next:='second_review_recorded';v_event:='second_review_recorded';
 ELSE
  RAISE EXCEPTION 'Invalid review transition or checklist is sealed'
  USING errcode='22023'; END IF;
 UPDATE public.vendor_verification_checks SET state=v_next,
 first_reviewer=CASE WHEN p_action='record_first' THEN auth.uid()
                     ELSE first_reviewer END,
 first_reviewed_at=CASE WHEN p_action='record_first' THEN clock_timestamp()
                        ELSE first_reviewed_at END,
 second_reviewer=CASE WHEN p_action='record_second' THEN auth.uid()
                      ELSE second_reviewer END,
 second_reviewed_at=CASE WHEN p_action='record_second' THEN clock_timestamp()
                         ELSE second_reviewed_at END,
 updated_at=clock_timestamp()
 WHERE id=p_check_id RETURNING * INTO v_check;
 INSERT INTO public.vendor_verification_check_events(
  case_id,check_id,actor_id,action,prior_state,next_state,rationale)
 VALUES(v_check.case_id,v_check.id,auth.uid(),v_event,v_previous,v_next,btrim(p_rationale));
 RETURN v_check;
END $$;

CREATE OR REPLACE FUNCTION public.request_vendor_evidence(
 p_check_id uuid,p_note text
) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER
 SET search_path=public,auth AS $$
DECLARE v_id uuid; v_case public.vendor_intake_cases%ROWTYPE;
BEGIN
 IF length(btrim(coalesce(p_note,''))) NOT BETWEEN 15 AND 500 THEN
  RAISE EXCEPTION 'Explanation must contain 15-500 characters'
   USING errcode='22023'; END IF;
 SELECT c.* INTO v_case FROM public.vendor_verification_checks k
 JOIN public.vendor_intake_cases c ON c.id=k.case_id
 WHERE k.id=p_check_id FOR UPDATE OF c;
 IF NOT FOUND OR NOT public.has_operations_case_scope('evidence_officer',v_case.id) THEN
  RAISE EXCEPTION 'Scoped evidence officer required' USING errcode='42501'; END IF;
 IF v_case.status<>'in_review' THEN
  RAISE EXCEPTION 'Case is not in review' USING errcode='22023'; END IF;
 IF v_case.applicant_id=auth.uid() THEN
  RAISE EXCEPTION 'Applicants may not request their own evidence'
   USING errcode='42501'; END IF;
 IF EXISTS(SELECT 1 FROM public.vendor_evidence_requests r
 WHERE r.check_id=p_check_id AND r.status IN ('requested','acknowledged')) THEN
  RAISE EXCEPTION 'An evidence request for this check is already open'
   USING errcode='23505'; END IF;
 INSERT INTO public.vendor_evidence_requests(
  case_id,check_id,requested_by,requirement_note)
 VALUES(v_case.id,p_check_id,auth.uid(),btrim(p_note))
 RETURNING id INTO v_id;
 INSERT INTO public.vendor_evidence_request_events(
  request_id,actor_id,action,to_status,rationale)
 VALUES(v_id,auth.uid(),'requested','requested',btrim(p_note));
 RETURN v_id;
END $$;

CREATE OR REPLACE FUNCTION public.cancel_vendor_evidence_request(
 p_request_id uuid,p_reason text
) RETURNS public.vendor_evidence_requests LANGUAGE plpgsql SECURITY DEFINER
 SET search_path=public,auth AS $$
DECLARE v_req public.vendor_evidence_requests%ROWTYPE;
 v_previous text;
BEGIN
 IF length(btrim(coalesce(p_reason,''))) NOT BETWEEN 15 AND 500 THEN
  RAISE EXCEPTION 'Reason must contain 15-500 characters'
   USING errcode='22023'; END IF;
 SELECT * INTO v_req FROM public.vendor_evidence_requests
 WHERE id=p_request_id FOR UPDATE;
 IF NOT FOUND OR NOT public.has_operations_case_scope('evidence_officer',v_req.case_id) THEN
  RAISE EXCEPTION 'Scoped evidence officer required' USING errcode='42501'; END IF;
 IF v_req.status NOT IN ('requested','acknowledged') THEN
  RAISE EXCEPTION 'No cancellable request found' USING errcode='22023'; END IF;
 v_previous:=v_req.status;
 UPDATE public.vendor_evidence_requests
 SET status='cancelled',last_action_at=clock_timestamp()
 WHERE id=p_request_id RETURNING * INTO v_req;
 INSERT INTO public.vendor_evidence_request_events(
  request_id,actor_id,action,from_status,to_status,rationale)
 VALUES(p_request_id,auth.uid(),'cancelled',v_previous,'cancelled',btrim(p_reason));
 RETURN v_req;
END $$;
COMMENT ON FUNCTION public.has_operations_case_scope(text,uuid) IS
 'Verified country, ISO subdivision and registered category mapping plus active caller duty. Absent mapping fails closed.';
COMMENT ON FUNCTION public.record_vendor_verification_review(uuid,text,text) IS
 'E6B preliminary country-scoped procedural review, independent first and second reviewers, no identity clearance.';
