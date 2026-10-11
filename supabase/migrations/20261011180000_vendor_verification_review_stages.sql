-- Phase 2A: metadata-only verification review task workflow.
-- No upload policies, no identity scans, no verified flags, no activation.
CREATE TABLE public.vendor_verification_checks (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 case_id uuid NOT NULL REFERENCES public.vendor_intake_cases(id) ON DELETE RESTRICT,
 requirement_key text NOT NULL CHECK(requirement_key ~ '^[a-z_]{4,64}$'),
 requirement_label text NOT NULL CHECK(length(requirement_label) BETWEEN 8 AND 200),
 requirement_scope text NOT NULL CHECK(requirement_scope IN
   ('baseline','business','category','jurisdiction')),
 state text NOT NULL DEFAULT 'pending' CHECK(state IN
   ('pending','in_review','needs_followup','first_review_recorded',
    'second_review_recorded')),
 first_reviewer uuid REFERENCES auth.users(id),
 second_reviewer uuid REFERENCES auth.users(id),
 first_reviewed_at timestamptz,
 second_reviewed_at timestamptz,
 updated_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 UNIQUE(case_id,requirement_key),
 CONSTRAINT independent_review_check CHECK(
   (state IN ('pending','in_review','needs_followup') AND
     first_reviewer IS NULL AND second_reviewer IS NULL AND
     first_reviewed_at IS NULL AND second_reviewed_at IS NULL)
   OR (state='first_review_recorded' AND
     first_reviewer IS NOT NULL AND first_reviewed_at IS NOT NULL
     AND second_reviewer IS NULL AND second_reviewed_at IS NULL)
   OR (state='second_review_recorded' AND
     first_reviewer IS NOT NULL AND first_reviewed_at IS NOT NULL
     AND second_reviewer IS NOT NULL AND second_reviewed_at IS NOT NULL
     AND first_reviewer<>second_reviewer))
);
CREATE INDEX vendor_verification_checks_case_idx
 ON public.vendor_verification_checks(case_id,state);

CREATE TABLE public.vendor_verification_check_events (
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 case_id uuid NOT NULL REFERENCES public.vendor_intake_cases(id) ON DELETE RESTRICT,
 check_id uuid NOT NULL REFERENCES public.vendor_verification_checks(id) ON DELETE RESTRICT,
 actor_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
 action text NOT NULL CHECK(action IN
   ('started','followup_requested','first_review_recorded',
    'second_review_recorded')),
 prior_state text NOT NULL,
 next_state text NOT NULL,
 rationale text NOT NULL CHECK(length(btrim(rationale)) BETWEEN 15 AND 1000),
 occurred_at timestamptz NOT NULL DEFAULT clock_timestamp()
);
CREATE INDEX vendor_verification_events_case_idx
 ON public.vendor_verification_check_events(case_id,occurred_at DESC);
ALTER TABLE public.vendor_verification_checks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vendor_verification_check_events ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.vendor_verification_checks FROM PUBLIC,anon,authenticated;
REVOKE ALL ON public.vendor_verification_check_events FROM PUBLIC,anon,authenticated;
GRANT SELECT ON public.vendor_verification_checks TO authenticated;
GRANT SELECT ON public.vendor_verification_check_events TO authenticated;
CREATE POLICY verification_checks_operations_read
 ON public.vendor_verification_checks FOR SELECT TO authenticated
 USING(public.is_admin(auth.uid()));
CREATE POLICY verification_events_operations_read
 ON public.vendor_verification_check_events FOR SELECT TO authenticated
 USING(public.is_admin(auth.uid()));

CREATE OR REPLACE FUNCTION public.populate_vendor_verification_checks()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER
SET search_path=public AS $$
DECLARE v_slug text;
BEGIN
 SELECT slug INTO v_slug FROM public.service_categories WHERE id=NEW.category_id;
 INSERT INTO public.vendor_verification_checks
   (case_id,requirement_key,requirement_label,requirement_scope)
 VALUES
 (NEW.id,'identity_check','Identity and contact details: independently verify','baseline'),
 (NEW.id,'operating_address','Proof of physical operating address','baseline'),
 (NEW.id,'service_eligibility','Authority and eligibility for selected service','baseline');
 IF NEW.applicant_kind='business' THEN
  INSERT INTO public.vendor_verification_checks
   (case_id,requirement_key,requirement_label,requirement_scope)
  VALUES
   (NEW.id,'company_registration','Company or business registry validation','business'),
   (NEW.id,'tax_registration','Tax registration and beneficial ownership checks','business');
 END IF;
 IF v_slug ~ '(taxi|ride|transport|delivery|car-hire)' THEN
  INSERT INTO public.vendor_verification_checks
   (case_id,requirement_key,requirement_label,requirement_scope)
  VALUES
   (NEW.id,'vehicle_registration','Vehicle registration and roadworthiness check','category'),
   (NEW.id,'driver_licence','Driver licence class and validity review','category'),
   (NEW.id,'vehicle_insurance','Vehicle insurance and coverage validation','category');
 ELSIF v_slug ~ '(food|catering|grocery|restaurant)' THEN
  INSERT INTO public.vendor_verification_checks
   (case_id,requirement_key,requirement_label,requirement_scope)
  VALUES (NEW.id,'food_hygiene','Food premises and hygiene authority review','category');
 ELSIF v_slug ~ '(equipment|machinery|plant-hire)' THEN
  INSERT INTO public.vendor_verification_checks
   (case_id,requirement_key,requirement_label,requirement_scope)
  VALUES (NEW.id,'equipment_safety','Equipment ownership, inspection and safety review','category');
 ELSE
  INSERT INTO public.vendor_verification_checks
   (case_id,requirement_key,requirement_label,requirement_scope)
  VALUES (NEW.id,'professional_scope','Trade, professional or service competency review','category');
 END IF;
 -- No jurisdiction is certified by this preliminary checklist. The extra
 -- non-PG task flags the absence of a reviewed country policy, not a waiver.
 IF NEW.country_code<>'PG' THEN
  INSERT INTO public.vendor_verification_checks
   (case_id,requirement_key,requirement_label,requirement_scope)
  VALUES (NEW.id,'local_regulation','Country-specific regulatory policy review pending','jurisdiction');
 ELSE
  INSERT INTO public.vendor_verification_checks
   (case_id,requirement_key,requirement_label,requirement_scope)
  VALUES (NEW.id,'png_local_authority','PNG-specific licensing authority review required','jurisdiction');
 END IF;
 RETURN NEW;
END $$;
REVOKE ALL ON FUNCTION public.populate_vendor_verification_checks()
 FROM PUBLIC,anon,authenticated;
CREATE TRIGGER vendor_case_verification_tasks
 AFTER INSERT ON public.vendor_intake_cases
 FOR EACH ROW EXECUTE FUNCTION public.populate_vendor_verification_checks();

-- Existing cases get a minimal baseline, without changing approval state.
INSERT INTO public.vendor_verification_checks
 (case_id,requirement_key,requirement_label,requirement_scope)
SELECT c.id,v.key,v.label,'baseline'
FROM public.vendor_intake_cases c CROSS JOIN (VALUES
 ('identity_check','Identity and contact details: independently verify'),
 ('operating_address','Proof of physical operating address'),
 ('service_eligibility','Authority and eligibility for selected service')
) AS v(key,label)
ON CONFLICT (case_id,requirement_key) DO NOTHING;

-- Administrative procedural review, not evidence certification.
CREATE OR REPLACE FUNCTION public.record_vendor_verification_review(
 p_check_id uuid,p_action text,p_rationale text
) RETURNS public.vendor_verification_checks
LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,auth AS $$
DECLARE
 v_check public.vendor_verification_checks%ROWTYPE;
 v_case public.vendor_intake_cases%ROWTYPE;
 v_previous text;
 v_next text;
 v_event text;
BEGIN
 IF auth.uid() IS NULL OR NOT public.is_admin(auth.uid()) THEN
  RAISE EXCEPTION 'Operations reviewer access required' USING errcode='42501';
 END IF;
 IF length(btrim(coalesce(p_rationale,''))) NOT BETWEEN 15 AND 1000 THEN
  RAISE EXCEPTION 'A 15–1000 character review rationale is required'
   USING errcode='22023';
 END IF;
 SELECT * INTO v_check FROM public.vendor_verification_checks
 WHERE id=p_check_id FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Checklist item not found'
  USING errcode='22023'; END IF;
 SELECT * INTO v_case FROM public.vendor_intake_cases
 WHERE id=v_check.case_id FOR UPDATE;
 IF v_case.status<>'in_review' THEN
  RAISE EXCEPTION 'The case must be in review' USING errcode='22023';
 END IF;
 IF v_case.applicant_id=auth.uid() THEN
  RAISE EXCEPTION 'Applicants cannot review their own cases'
   USING errcode='42501';
 END IF;
 v_previous:=v_check.state;
 IF p_action='start' AND v_previous IN ('pending','needs_followup') THEN
  v_next:='in_review';v_event:='started';
 ELSIF p_action='followup' AND v_previous IN ('pending','in_review') THEN
  v_next:='needs_followup';v_event:='followup_requested';
 ELSIF p_action='record_first' AND v_previous='in_review' THEN
  IF v_case.assigned_reviewer IS DISTINCT FROM auth.uid() THEN
   RAISE EXCEPTION 'Only the assigned case reviewer can record the first review'
    USING errcode='42501';
  END IF;
  v_next:='first_review_recorded';v_event:='first_review_recorded';
 ELSIF p_action='record_second' AND v_previous='first_review_recorded' THEN
  IF v_check.first_reviewer=auth.uid() OR
    v_check.first_reviewer IS NULL THEN
   RAISE EXCEPTION 'An independent second reviewer is required'
     USING errcode='42501';
  END IF;
  v_next:='second_review_recorded';v_event:='second_review_recorded';
 ELSE
  RAISE EXCEPTION 'Invalid review transition or checklist is sealed'
   USING errcode='22023';
 END IF;
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
 INSERT INTO public.vendor_verification_check_events
  (case_id,check_id,actor_id,action,prior_state,next_state,rationale)
 VALUES (v_check.case_id,v_check.id,auth.uid(),v_event,
  v_previous,v_next,btrim(p_rationale));
 RETURN v_check;
END $$;
REVOKE ALL ON FUNCTION public.record_vendor_verification_review(uuid,text,text)
 FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.record_vendor_verification_review(uuid,text,text)
 TO authenticated;
COMMENT ON TABLE public.vendor_verification_checks IS
 'Procedural two-person review tasks, NOT validated identity or regulatory clearance. Cannot activate services.';
COMMENT ON FUNCTION public.record_vendor_verification_review(uuid,text,text) IS
 'Admin-only audited preliminary review. First reviewer must own case; second reviewer must be different. Never grants clearance.';

-- Prevent silent issuance via ordinary role: existing clearance table remains
-- without client grants, INSERT/UPDATE policies, or approval RPC.
REVOKE ALL ON public.vendor_activation_clearances FROM PUBLIC,anon,authenticated;
