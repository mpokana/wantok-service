-- Use statement time for assignments issued in an existing transaction.
-- now() is transaction-start time and can precede clock_timestamp() issue times.
CREATE OR REPLACE FUNCTION public.has_operations_scope(
 p_duty text,p_country_code text,p_region_code text,p_category_scope text
) RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
 SET search_path=public,auth AS $$
 SELECT auth.uid() IS NOT NULL AND p_duty IN (
   'policy_author','policy_reviewer','evidence_officer',
   'final_approver','safety_investigator')
 AND p_country_code ~ '^[A-Z]{2}$'
 AND (p_region_code IS NULL OR
   (p_region_code ~ '^[A-Z]{2}-[A-Z0-9]{1,6}$'
    AND left(p_region_code,2)=p_country_code))
 AND p_category_scope IN (
   'all','transport','food','trades','equipment','accommodation','other')
 AND EXISTS(
  SELECT 1 FROM public.operations_duty_grants g
  WHERE g.staff_user_id=auth.uid()
   AND g.duty=p_duty AND g.country_code=p_country_code
   AND g.revoked_at IS NULL
   AND g.issued_at<=statement_timestamp() AND (g.expires_at IS NULL OR g.expires_at>statement_timestamp())
   AND (g.region_code IS NULL OR g.region_code=p_region_code)
   AND (g.category_scope='all' OR g.category_scope=p_category_scope)
 );
$$;
