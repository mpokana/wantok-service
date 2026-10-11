-- E6B2: a syntactically plausible subdivision is NOT sufficient for scope.
-- Only an independently checked, explicitly registered region may be used.
CREATE TABLE public.operations_approved_regions (
 region_code text PRIMARY KEY CHECK(region_code ~ '^[A-Z]{2}-[A-Z0-9]{1,6}$'),
 country_code text NOT NULL CHECK(country_code ~ '^[A-Z]{2}$'),
 region_name text NOT NULL CHECK(length(btrim(region_name)) BETWEEN 2 AND 120),
 verified_by uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
 verification_reason text NOT NULL CHECK(length(btrim(verification_reason)) BETWEEN 20 AND 1000),
 verified_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 is_enabled boolean NOT NULL DEFAULT true,
 CHECK(left(region_code,2)=country_code)
);
ALTER TABLE public.operations_approved_regions ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.operations_approved_regions FROM PUBLIC,anon,authenticated;

CREATE FUNCTION public.register_operations_region(
 p_region_code text,p_region_name text,p_operator_id uuid,p_reason text
) RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER
 SET search_path=public,auth AS $$
BEGIN
 IF p_region_code IS NULL OR p_region_code !~ '^[A-Z]{2}-[A-Z0-9]{1,6}$'
 OR length(btrim(coalesce(p_region_name,''))) NOT BETWEEN 2 AND 120
 OR length(btrim(coalesce(p_reason,''))) NOT BETWEEN 20 AND 1000
 OR NOT EXISTS(SELECT 1 FROM public.profiles WHERE id=p_operator_id) THEN
  RAISE EXCEPTION 'Independent country subdivision verification required'
  USING errcode='22023';
 END IF;
 INSERT INTO public.operations_approved_regions
 (region_code,country_code,region_name,verified_by,verification_reason)
 VALUES(p_region_code,left(p_region_code,2),btrim(p_region_name),
 p_operator_id,btrim(p_reason))
 ON CONFLICT (region_code) DO UPDATE SET
  region_name=EXCLUDED.region_name,verified_by=EXCLUDED.verified_by,
  verification_reason=EXCLUDED.verification_reason,
  verified_at=clock_timestamp(),is_enabled=true;
 RETURN true;
END $$;
REVOKE ALL ON FUNCTION public.register_operations_region(text,text,uuid,text)
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.register_operations_region(text,text,uuid,text)
 TO service_role;

-- Check registered, enabled geography for both classification and reads.
CREATE OR REPLACE FUNCTION public.register_operations_case_jurisdiction(
 p_case_id uuid,p_region_code text,p_operator_id uuid,p_reason text
) RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER
 SET search_path=public,auth AS $$
DECLARE v_case public.vendor_intake_cases%ROWTYPE;
 v_category text;v_prior public.operations_case_jurisdictions%ROWTYPE;
BEGIN
 SELECT * INTO v_case FROM public.vendor_intake_cases WHERE id=p_case_id FOR UPDATE;
 SELECT category_scope INTO v_category FROM public.operations_service_category_scopes
 WHERE category_id=v_case.category_id;
 IF v_case.id IS NULL OR v_category IS NULL
 OR NOT EXISTS(SELECT 1 FROM public.operations_approved_regions r
   WHERE r.region_code=p_region_code AND r.country_code=v_case.country_code
   AND r.is_enabled)
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
REVOKE ALL ON FUNCTION public.register_operations_case_jurisdiction(uuid,text,uuid,text)
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.register_operations_case_jurisdiction(uuid,text,uuid,text)
 TO service_role;

CREATE OR REPLACE FUNCTION public.has_operations_case_scope(p_duty text,p_case_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
 SET search_path=public,auth AS $$
 SELECT auth.uid() IS NOT NULL
 AND p_duty IN ('case_reviewer','evidence_officer')
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
