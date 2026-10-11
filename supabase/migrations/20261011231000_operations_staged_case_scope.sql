-- E6E: separate historical staged applicant classification; NO free-text
-- province guesses, no implicit admin privilege, no identity document upload.
CREATE TABLE public.operations_staged_jurisdictions (
 application_id uuid PRIMARY KEY REFERENCES public.staged_provider_applications(id)
   ON DELETE RESTRICT,
 country_code text NOT NULL CHECK(country_code ~ '^[A-Z]{2}$'),
 region_code text NOT NULL CHECK(region_code ~ '^[A-Z]{2}-[A-Z0-9]{1,6}$'),
 category_scope text NOT NULL CHECK(category_scope IN (
 'transport','food','trades','equipment','accommodation','other')),
 classified_by uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
 reason text NOT NULL CHECK(length(btrim(reason)) BETWEEN 25 AND 1000),
 classified_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 CHECK(left(region_code,2)=country_code)
);
CREATE TABLE public.operations_staged_jurisdiction_events (
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 application_id uuid NOT NULL REFERENCES public.staged_provider_applications(id)
 ON DELETE RESTRICT,
 previous_region text,
 new_region text NOT NULL,
 previous_category text,
 new_category text NOT NULL,
 operator_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
 reason text NOT NULL,
 occurred_at timestamptz NOT NULL DEFAULT clock_timestamp()
);
ALTER TABLE public.operations_staged_jurisdictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.operations_staged_jurisdiction_events ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.operations_staged_jurisdictions FROM PUBLIC,anon,authenticated;
REVOKE ALL ON public.operations_staged_jurisdiction_events FROM PUBLIC,anon,authenticated;

CREATE FUNCTION public.classify_operations_staged_application(
 p_application_id uuid,p_region_code text,p_operator_id uuid,p_reason text
) RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,auth AS $$
DECLARE v_application public.staged_provider_applications%ROWTYPE;
 v_category text;v_prev public.operations_staged_jurisdictions%ROWTYPE;
BEGIN
 SELECT * INTO v_application FROM public.staged_provider_applications
 WHERE id=p_application_id FOR UPDATE;
 SELECT m.category_scope INTO v_category
 FROM public.operations_service_category_scopes m
 WHERE m.category_id=v_application.category_id;
 IF v_application.id IS NULL OR v_category IS NULL
 OR NOT EXISTS(SELECT 1 FROM public.operations_approved_regions r
   WHERE r.region_code=p_region_code
   AND r.country_code=v_application.coverage_country_code
   AND r.is_enabled)
 OR NOT EXISTS(SELECT 1 FROM public.profiles WHERE id=p_operator_id)
 OR length(btrim(coalesce(p_reason,''))) NOT BETWEEN 25 AND 1000 THEN
  RAISE EXCEPTION 'Independently verified staged jurisdiction required'
   USING errcode='22023';
 END IF;
 SELECT * INTO v_prev FROM public.operations_staged_jurisdictions
 WHERE application_id=p_application_id FOR UPDATE;
 INSERT INTO public.operations_staged_jurisdictions(
 application_id,country_code,region_code,category_scope,classified_by,reason)
 VALUES(p_application_id,v_application.coverage_country_code,p_region_code,
 v_category,p_operator_id,btrim(p_reason))
 ON CONFLICT(application_id) DO UPDATE SET
 country_code=EXCLUDED.country_code,region_code=EXCLUDED.region_code,
 category_scope=EXCLUDED.category_scope,classified_by=EXCLUDED.classified_by,
 reason=EXCLUDED.reason,classified_at=clock_timestamp();
 INSERT INTO public.operations_staged_jurisdiction_events(
 application_id,previous_region,new_region,previous_category,new_category,
 operator_id,reason)
 VALUES(p_application_id,v_prev.region_code,p_region_code,v_prev.category_scope,
 v_category,p_operator_id,btrim(p_reason));
 RETURN true;
END $$;
REVOKE ALL ON FUNCTION public.classify_operations_staged_application(
 uuid,text,uuid,text) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.classify_operations_staged_application(
 uuid,text,uuid,text) TO service_role;

CREATE FUNCTION public.has_operations_staged_scope(p_duty text,p_application_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path=public,auth AS $$
 SELECT auth.uid() IS NOT NULL
 AND p_duty IN('case_reviewer','evidence_officer')
 AND EXISTS(
 SELECT 1 FROM public.staged_provider_applications a
 JOIN public.operations_staged_jurisdictions j
 ON j.application_id=a.id AND j.country_code=a.coverage_country_code
 JOIN public.operations_service_category_scopes m
 ON m.category_id=a.category_id AND m.category_scope=j.category_scope
 JOIN public.operations_approved_regions r
 ON r.region_code=j.region_code AND r.country_code=j.country_code AND r.is_enabled
 WHERE a.id=p_application_id AND a.user_id<>auth.uid()
 AND public.has_operations_scope(
 p_duty,j.country_code,j.region_code,j.category_scope)
 );
$$;
REVOKE ALL ON FUNCTION public.has_operations_staged_scope(text,uuid)
 FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.has_operations_staged_scope(text,uuid)
 TO authenticated;

-- Every old admin RLS policy for this staged workflow is replaced. Owners may
-- still read their OWN progress and withdraw their OWN non-uploading intent.
DROP POLICY staged_applications_read_owner_admin
 ON public.staged_provider_applications;
CREATE POLICY staged_applications_read_scoped ON public.staged_provider_applications
 FOR SELECT TO authenticated USING(user_id=auth.uid()
 OR public.has_operations_staged_scope('case_reviewer',id)
 OR public.has_operations_staged_scope('evidence_officer',id));

DROP POLICY staged_verification_checks_owner_admin
 ON public.staged_verification_checks;
CREATE POLICY staged_verification_checks_read_scoped
 ON public.staged_verification_checks FOR SELECT TO authenticated
 USING(EXISTS(SELECT 1 FROM public.staged_provider_applications a
 WHERE a.id=application_id AND (
 a.user_id=auth.uid()
 OR public.has_operations_staged_scope('case_reviewer',a.id)
 OR public.has_operations_staged_scope('evidence_officer',a.id))));
DROP POLICY staged_verification_audit_admin_only
 ON public.staged_verification_audit;
CREATE POLICY staged_verification_audit_scoped
 ON public.staged_verification_audit FOR SELECT TO authenticated
 USING(public.has_operations_staged_scope('case_reviewer',application_id));

DROP POLICY staged_evidence_requirements_owner_admin
 ON public.staged_evidence_requirements;
CREATE POLICY staged_evidence_requirements_scoped
 ON public.staged_evidence_requirements FOR SELECT TO authenticated
 USING(EXISTS(SELECT 1 FROM public.staged_provider_applications a
 WHERE a.id=application_id AND (
 a.user_id=auth.uid()
 OR public.has_operations_staged_scope('case_reviewer',a.id)
 OR public.has_operations_staged_scope('evidence_officer',a.id))));
DROP POLICY staged_evidence_requirements_audit_admin
 ON public.staged_evidence_requirement_audit;
CREATE POLICY staged_evidence_requirements_audit_scoped
 ON public.staged_evidence_requirement_audit FOR SELECT TO authenticated
 USING(public.has_operations_staged_scope('evidence_officer',application_id));

DROP POLICY staged_intents_read_owner_admin
 ON public.staged_evidence_intake_intents;
CREATE POLICY staged_intents_read_scoped
 ON public.staged_evidence_intake_intents FOR SELECT TO authenticated
 USING(applicant_id=auth.uid()
 OR public.has_operations_staged_scope('evidence_officer',application_id));

CREATE OR REPLACE FUNCTION public.triage_staged_provider_application(
 p_application_id uuid,p_decision text
) RETURNS public.staged_provider_applications
 LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,auth AS $$
DECLARE v_app public.staged_provider_applications%ROWTYPE;
BEGIN
 IF NOT public.has_operations_staged_scope('case_reviewer',p_application_id)
 THEN RAISE EXCEPTION 'Scoped staged case reviewer required' USING errcode='42501'; END IF;
 IF p_decision NOT IN ('in_review','declined') THEN
  RAISE EXCEPTION 'Only preliminary triage is permitted' USING errcode='22023'; END IF;
 SELECT * INTO v_app FROM public.staged_provider_applications
 WHERE id=p_application_id FOR UPDATE;
 IF v_app.status<>'submitted' THEN
  RAISE EXCEPTION 'Submitted preliminary application not found' USING errcode='22023'; END IF;
 UPDATE public.staged_provider_applications
 SET status=p_decision,reviewed_by=auth.uid(),reviewed_at=clock_timestamp()
 WHERE id=p_application_id AND status='submitted' RETURNING * INTO v_app;
 RETURN v_app;
END $$;

CREATE OR REPLACE FUNCTION public.update_staged_verification_check(
 p_check_id uuid,p_status text
) RETURNS public.staged_verification_checks
 LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,auth AS $$
DECLARE v_old public.staged_verification_checks%ROWTYPE;
 v_app public.staged_provider_applications%ROWTYPE;
 v_updated public.staged_verification_checks%ROWTYPE;
BEGIN
 SELECT * INTO v_old FROM public.staged_verification_checks
 WHERE id=p_check_id FOR UPDATE;
 IF NOT FOUND OR NOT public.has_operations_staged_scope(
 'case_reviewer',v_old.application_id) THEN
  RAISE EXCEPTION 'Scoped staged case reviewer required'
  USING errcode='42501'; END IF;
 IF p_status NOT IN ('pending','under_review','needs_followup') THEN
  RAISE EXCEPTION 'Only preliminary review progress is supported'
  USING errcode='22023'; END IF;
 SELECT * INTO v_app FROM public.staged_provider_applications
 WHERE id=v_old.application_id FOR UPDATE;
 IF v_app.status<>'in_review'
 OR NOT EXISTS(SELECT 1 FROM public.provider_onboarding_policies p
 WHERE p.category_id=v_app.category_id AND p.intake_status='staged') THEN
  RAISE EXCEPTION 'Application is not in preliminary review'
  USING errcode='22023'; END IF;
 IF v_old.review_status=p_status THEN RETURN v_old; END IF;
 UPDATE public.staged_verification_checks
 SET review_status=p_status,last_reviewed_by=auth.uid(),
 last_reviewed_at=clock_timestamp()
 WHERE id=p_check_id RETURNING * INTO v_updated;
 INSERT INTO public.staged_verification_audit(
 application_id,check_id,reviewed_by,previous_status,next_status)
 VALUES(v_old.application_id,p_check_id,auth.uid(),v_old.review_status,p_status);
 RETURN v_updated;
END $$;

CREATE OR REPLACE FUNCTION public.plan_staged_evidence_requirement(p_check_id uuid)
RETURNS public.staged_evidence_requirements
 LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,auth AS $$
DECLARE v_check public.staged_verification_checks%ROWTYPE;
 v_app public.staged_provider_applications%ROWTYPE;
 v_result public.staged_evidence_requirements%ROWTYPE;
BEGIN
 SELECT * INTO v_check FROM public.staged_verification_checks
 WHERE id=p_check_id;
 IF NOT FOUND OR NOT public.has_operations_staged_scope(
 'evidence_officer',v_check.application_id) THEN
  RAISE EXCEPTION 'Scoped staged evidence officer required' USING errcode='42501'; END IF;
 SELECT * INTO v_app FROM public.staged_provider_applications
 WHERE id=v_check.application_id FOR UPDATE;
 IF v_app.status<>'in_review' OR NOT EXISTS(
  SELECT 1 FROM public.provider_onboarding_policies p
  WHERE p.category_id=v_app.category_id AND p.intake_status='staged') THEN
  RAISE EXCEPTION 'Application is not in preliminary review'
  USING errcode='22023'; END IF;
 INSERT INTO public.staged_evidence_requirements(check_id,application_id,planned_by)
 VALUES(v_check.id,v_app.id,auth.uid())
 ON CONFLICT(check_id) DO NOTHING RETURNING * INTO v_result;
 IF FOUND THEN
  INSERT INTO public.staged_evidence_requirement_audit(
    check_id,application_id,actor_id,action)
  VALUES(v_check.id,v_app.id,auth.uid(),'planned');
 ELSE
  SELECT * INTO v_result FROM public.staged_evidence_requirements
  WHERE check_id=v_check.id;
 END IF;
 RETURN v_result;
END $$;

CREATE OR REPLACE FUNCTION public.cancel_staged_evidence_requirement(p_check_id uuid)
RETURNS public.staged_evidence_requirements
 LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,auth AS $$
DECLARE v_result public.staged_evidence_requirements%ROWTYPE;
 v_app_id uuid;
BEGIN
 SELECT application_id INTO v_app_id FROM public.staged_evidence_requirements
 WHERE check_id=p_check_id;
 IF v_app_id IS NULL OR NOT public.has_operations_staged_scope(
 'evidence_officer',v_app_id) THEN
  RAISE EXCEPTION 'Scoped staged evidence officer required'
  USING errcode='42501'; END IF;
 UPDATE public.staged_evidence_requirements
 SET state='cancelled',cancelled_by=auth.uid(),cancelled_at=clock_timestamp()
 WHERE check_id=p_check_id AND state='planned'
 RETURNING * INTO v_result;
 IF NOT FOUND THEN
  RAISE EXCEPTION 'Active evidence requirement not found'
  USING errcode='22023'; END IF;
 INSERT INTO public.staged_evidence_requirement_audit(
  check_id,application_id,actor_id,action)
 VALUES(v_result.check_id,v_result.application_id,auth.uid(),'cancelled');
 RETURN v_result;
END $$;

-- No administrator may activate older provider resource records while final
-- independent qualification and release remain disabled. Existing provider
-- resource drafting and owner submissions are left unchanged.
CREATE OR REPLACE FUNCTION public.admin_set_provider_resource_status(
 p_resource_id uuid,p_status text
) RETURNS public.provider_resources
 LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,auth AS $$
BEGIN
 RAISE EXCEPTION 'Legacy resource moderation disabled pending independent release'
 USING errcode='42501';
END $$;
COMMENT ON FUNCTION public.admin_set_provider_resource_status(uuid,text) IS
 'Fail closed: no legacy resource activation or global-admin moderation until E9.';
