-- E6H: enterprise applicants may never use staff duties on their own case.
-- Existing country/subdivision/category, duty and explicit recusal controls stay.
CREATE OR REPLACE FUNCTION public.has_operations_case_scope(
 p_duty text,p_case_id uuid
) RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
 SET search_path=public,auth AS $$
 SELECT auth.uid() IS NOT NULL
 AND p_duty IN ('case_reviewer','evidence_officer','safety_investigator')
 AND NOT EXISTS (
  SELECT 1 FROM public.operations_case_recusals conflict
  WHERE conflict.enterprise_case_id=p_case_id
  AND conflict.staff_user_id=auth.uid())
 AND EXISTS (
  SELECT 1 FROM public.vendor_intake_cases c
  JOIN public.operations_case_jurisdictions j ON j.case_id=c.id
  JOIN public.operations_service_category_scopes m ON m.category_id=c.category_id
  JOIN public.operations_approved_regions r ON
   r.region_code=j.region_code AND r.country_code=j.country_code AND r.is_enabled
  WHERE c.id=p_case_id AND c.applicant_id<>auth.uid()
  AND c.country_code=j.country_code
  AND j.category_scope=m.category_scope
  AND public.has_operations_scope(
   p_duty,j.country_code,j.region_code,j.category_scope)
 );
$$;
COMMENT ON FUNCTION public.has_operations_case_scope(text,uuid) IS
 'E6H: independent staff duties; applicant-owned enterprise case always denied.';

-- Prevent previous clearance reviewers from browsing the same provider's
-- safety evidence by switching to a later investigator duty. The applicant
-- and the two recorded clearance reviewers are never independent investigators.
CREATE OR REPLACE FUNCTION public.has_operations_clearance_scope(
 p_duty text,p_provider_id uuid
) RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
 SET search_path=public,auth AS $$
 SELECT p_duty='safety_investigator'
 AND auth.uid() IS NOT NULL
 AND EXISTS (
  SELECT 1 FROM public.vendor_activation_clearances a
  JOIN public.vendor_intake_cases c
    ON c.id=a.evidence_case_id AND c.applicant_id=a.provider_id
  WHERE a.provider_id=p_provider_id
  AND auth.uid()<>a.provider_id
  AND auth.uid() IS DISTINCT FROM a.identity_reviewer
  AND auth.uid() IS DISTINCT FROM a.approving_officer
  AND public.has_operations_case_scope('safety_investigator',c.id)
 );
$$;
COMMENT ON FUNCTION public.has_operations_clearance_scope(text,uuid) IS
 'E6H: case-bound safety clearance excludes applicant and its prior reviewers.';
