-- E6F: immutable case conflict disclosures. Active exclusions override
-- otherwise valid country/category duties. No private business relationship
-- can be inferred from free-text applicant identity.
CREATE TABLE public.operations_case_recusals (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 enterprise_case_id uuid REFERENCES public.vendor_intake_cases(id)
 ON DELETE RESTRICT,
 staged_application_id uuid REFERENCES public.staged_provider_applications(id)
 ON DELETE RESTRICT,
 staff_user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
 recorded_by uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
 reason text NOT NULL CHECK(length(btrim(reason)) BETWEEN 30 AND 1000),
 recorded_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 CHECK((enterprise_case_id IS NULL)<>(staged_application_id IS NULL)),
 UNIQUE(enterprise_case_id,staff_user_id),
 UNIQUE(staged_application_id,staff_user_id)
);
ALTER TABLE public.operations_case_recusals ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.operations_case_recusals FROM PUBLIC,anon,authenticated;
GRANT SELECT ON public.operations_case_recusals TO authenticated;
CREATE POLICY my_operations_case_recusals ON public.operations_case_recusals
 FOR SELECT TO authenticated USING(staff_user_id=auth.uid());

CREATE FUNCTION public.declare_operations_case_recusal(
 p_case_type text,p_case_id uuid,p_reason text
) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER
 SET search_path=public,auth AS $$
DECLARE v_actor uuid:=auth.uid();v_id uuid;
BEGIN
 IF length(btrim(coalesce(p_reason,''))) NOT BETWEEN 30 AND 1000 THEN
  RAISE EXCEPTION 'Conflict disclosure reason required' USING errcode='22023';
 END IF;
 IF v_actor IS NULL OR NOT (
  (p_case_type='enterprise' AND (
   public.has_operations_case_scope('case_reviewer',p_case_id)
   OR public.has_operations_case_scope('evidence_officer',p_case_id)
   OR public.has_operations_case_scope('safety_investigator',p_case_id)))
  OR (p_case_type='staged' AND (
   public.has_operations_staged_scope('case_reviewer',p_case_id)
   OR public.has_operations_staged_scope('evidence_officer',p_case_id)))
 ) THEN
  RAISE EXCEPTION 'Assigned scoped staff required for case disclosure'
   USING errcode='42501';
 END IF;
 INSERT INTO public.operations_case_recusals(
 enterprise_case_id,staged_application_id,staff_user_id,recorded_by,reason)
 VALUES(
 CASE WHEN p_case_type='enterprise' THEN p_case_id ELSE NULL END,
 CASE WHEN p_case_type='staged' THEN p_case_id ELSE NULL END,
 v_actor,v_actor,btrim(p_reason))
 ON CONFLICT DO NOTHING RETURNING id INTO v_id;
 IF v_id IS NULL THEN
  SELECT id INTO v_id FROM public.operations_case_recusals
  WHERE staff_user_id=v_actor AND (
    (p_case_type='enterprise' AND enterprise_case_id=p_case_id) OR
    (p_case_type='staged' AND staged_application_id=p_case_id));
 END IF;
 RETURN v_id;
END $$;
REVOKE ALL ON FUNCTION public.declare_operations_case_recusal(text,uuid,text)
 FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.declare_operations_case_recusal(text,uuid,text)
 TO authenticated;

CREATE FUNCTION public.record_operations_case_conflict_trusted(
 p_case_type text,p_case_id uuid,p_staff_user_id uuid,
 p_independent_operator_id uuid,p_reason text
) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER
 SET search_path=public,auth AS $$
DECLARE v_id uuid;
BEGIN
 IF p_staff_user_id=p_independent_operator_id OR
 length(btrim(coalesce(p_reason,''))) NOT BETWEEN 30 AND 1000
 OR NOT EXISTS(SELECT 1 FROM public.profiles WHERE id=p_staff_user_id)
 OR NOT EXISTS(SELECT 1 FROM public.profiles WHERE id=p_independent_operator_id)
 OR NOT (
  (p_case_type='enterprise' AND EXISTS(
    SELECT 1 FROM public.vendor_intake_cases WHERE id=p_case_id))
  OR (p_case_type='staged' AND EXISTS(
    SELECT 1 FROM public.staged_provider_applications WHERE id=p_case_id))
 ) THEN
  RAISE EXCEPTION 'Independently verified staff conflict record required'
  USING errcode='22023'; END IF;
 INSERT INTO public.operations_case_recusals(
 enterprise_case_id,staged_application_id,staff_user_id,recorded_by,reason)
 VALUES(
 CASE WHEN p_case_type='enterprise' THEN p_case_id ELSE NULL END,
 CASE WHEN p_case_type='staged' THEN p_case_id ELSE NULL END,
 p_staff_user_id,p_independent_operator_id,btrim(p_reason))
 ON CONFLICT DO NOTHING RETURNING id INTO v_id;
 IF v_id IS NULL THEN
  SELECT id INTO v_id FROM public.operations_case_recusals
  WHERE staff_user_id=p_staff_user_id AND (
   (p_case_type='enterprise' AND enterprise_case_id=p_case_id) OR
   (p_case_type='staged' AND staged_application_id=p_case_id));
 END IF;
 RETURN v_id;
END $$;
REVOKE ALL ON FUNCTION public.record_operations_case_conflict_trusted(
 text,uuid,uuid,uuid,text) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.record_operations_case_conflict_trusted(
 text,uuid,uuid,uuid,text) TO service_role;

CREATE OR REPLACE FUNCTION public.has_operations_case_scope(
 p_duty text,p_case_id uuid
) RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
 SET search_path=public,auth AS $$
 SELECT auth.uid() IS NOT NULL
 AND p_duty IN ('case_reviewer','evidence_officer','safety_investigator')
 AND NOT EXISTS(
  SELECT 1 FROM public.operations_case_recusals conflict
  WHERE conflict.enterprise_case_id=p_case_id
  AND conflict.staff_user_id=auth.uid())
 AND EXISTS (
  SELECT 1 FROM public.vendor_intake_cases c
  JOIN public.operations_case_jurisdictions j ON j.case_id=c.id
  JOIN public.operations_service_category_scopes m ON m.category_id=c.category_id
  JOIN public.operations_approved_regions r ON
   r.region_code=j.region_code AND r.country_code=j.country_code AND r.is_enabled
  WHERE c.id=p_case_id AND c.country_code=j.country_code
  AND j.category_scope=m.category_scope
  AND public.has_operations_scope(
   p_duty,j.country_code,j.region_code,j.category_scope)
 );
$$;

CREATE OR REPLACE FUNCTION public.has_operations_staged_scope(
 p_duty text,p_application_id uuid
) RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
 SET search_path=public,auth AS $$
 SELECT auth.uid() IS NOT NULL
 AND p_duty IN('case_reviewer','evidence_officer')
 AND NOT EXISTS (
  SELECT 1 FROM public.operations_case_recusals conflict
  WHERE conflict.staged_application_id=p_application_id
  AND conflict.staff_user_id=auth.uid())
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
