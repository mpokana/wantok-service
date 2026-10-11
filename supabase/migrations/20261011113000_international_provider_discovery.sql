-- International coverage belongs to the service, not the user's language.
-- Existing PNG providers are explicitly backfilled to PG; no location is inferred.
ALTER TABLE public.provider_services
 ADD COLUMN IF NOT EXISTS coverage_country_code text NOT NULL DEFAULT 'PG'
 CHECK (coverage_country_code ~ '^[A-Z]{2}$'),
 ADD COLUMN IF NOT EXISTS delivery_mode text NOT NULL DEFAULT 'onsite'
 CHECK (delivery_mode IN ('onsite','remote','hybrid'));
ALTER TABLE public.staged_provider_applications
 ADD COLUMN IF NOT EXISTS coverage_country_code text NOT NULL DEFAULT 'PG'
 CHECK (coverage_country_code ~ '^[A-Z]{2}$');
ALTER TABLE public.provider_profiles
 ADD COLUMN IF NOT EXISTS base_country_code text NOT NULL DEFAULT 'PG'
 CHECK (base_country_code ~ '^[A-Z]{2}$');
CREATE INDEX IF NOT EXISTS provider_services_country_region_idx
 ON public.provider_services (coverage_country_code, lower(coverage_province), lower(coverage_town))
 WHERE status='active';
CREATE INDEX IF NOT EXISTS provider_services_delivery_mode_idx
 ON public.provider_services (delivery_mode) WHERE status='active';

-- Strictly additive RPC: existing client calls and specialized booking flows remain unchanged.
CREATE OR REPLACE FUNCTION public.search_client_providers_international(
 p_query text DEFAULT NULL,
 p_category_id uuid DEFAULT NULL,
 p_country_code text DEFAULT NULL,
 p_region text DEFAULT NULL,
 p_town text DEFAULT NULL,
 p_provider_type text DEFAULT NULL,
 p_min_rating numeric DEFAULT NULL,
 p_remote_only boolean DEFAULT false,
 p_limit integer DEFAULT 30
) RETURNS TABLE(
 provider_id uuid,display_name text,provider_type text,bio text,
 rating_average numeric,rating_count integer,service_count integer,
 category_ids uuid[],category_names text[],service_titles text[],
 coverage_provinces text[],coverage_towns text[],organic_score numeric,
 country_codes text[]
)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path=public,auth AS $$
WITH eligible_services AS (
 SELECT s.*,c.name AS category_name
 FROM public.provider_services s
 JOIN public.service_categories c ON c.id=s.category_id
 WHERE auth.uid() IS NOT NULL AND s.status='active' AND c.is_active
 AND (p_category_id IS NULL OR s.category_id=p_category_id)
 AND (NULLIF(btrim(coalesce(p_country_code,'')),'') IS NULL
   OR s.coverage_country_code=upper(btrim(p_country_code)))
 AND (NULLIF(btrim(coalesce(p_region,'')),'') IS NULL
   OR lower(btrim(s.coverage_province))=lower(btrim(p_region)))
 AND (NULLIF(btrim(coalesce(p_town,'')),'') IS NULL
   OR lower(btrim(s.coverage_town))=lower(btrim(p_town)))
 AND (NOT coalesce(p_remote_only,false) OR s.delivery_mode IN ('remote','hybrid'))
), candidates AS (
 SELECT p.provider_id,p.display_name,p.provider_type,p.bio,
  p.rating_average,p.rating_count,count(s.id)::integer AS service_count,
  array_agg(DISTINCT s.category_id ORDER BY s.category_id) AS category_ids,
  array_agg(DISTINCT s.category_name ORDER BY s.category_name) AS category_names,
  array_agg(DISTINCT s.title ORDER BY s.title) AS service_titles,
  coalesce(array_agg(DISTINCT s.coverage_province ORDER BY s.coverage_province)
    FILTER(WHERE s.coverage_province IS NOT NULL),'{}'::text[]) AS coverage_provinces,
  coalesce(array_agg(DISTINCT s.coverage_town ORDER BY s.coverage_town)
    FILTER(WHERE s.coverage_town IS NOT NULL),'{}'::text[]) AS coverage_towns,
  round(
    ((p.rating_count::numeric*p.rating_average)+(10::numeric*4.0::numeric))
       /(p.rating_count::numeric+10::numeric)
      + least(ln(p.rating_count::numeric+1),4::numeric)*0.10,4
  ) AS organic_score,
  array_agg(DISTINCT s.coverage_country_code ORDER BY s.coverage_country_code)
    AS country_codes
 FROM public.provider_profiles p
 JOIN eligible_services s ON s.provider_id=p.provider_id
 WHERE p.is_active AND p.verification_status='verified'
 AND (NULLIF(btrim(coalesce(p_provider_type,'')),'') IS NULL OR
      p.provider_type=p_provider_type)
 AND (p_min_rating IS NULL OR p.rating_average >= p_min_rating)
 AND (NULLIF(btrim(coalesce(p_query,'')),'') IS NULL
   OR lower(p.display_name) LIKE '%'||lower(btrim(p_query))||'%'
   OR lower(coalesce(p.bio,'')) LIKE '%'||lower(btrim(p_query))||'%'
   OR EXISTS (SELECT 1 FROM eligible_services matching
     WHERE matching.provider_id=p.provider_id AND (
       lower(matching.title) LIKE '%'||lower(btrim(p_query))||'%'
       OR lower(coalesce(matching.description,'')) LIKE '%'||lower(btrim(p_query))||'%'
       OR lower(matching.category_name) LIKE '%'||lower(btrim(p_query))||'%')))
 GROUP BY p.provider_id,p.display_name,p.provider_type,p.bio,
   p.rating_average,p.rating_count
)
SELECT provider_id,display_name,provider_type,bio,rating_average,rating_count,
 service_count,category_ids,category_names,service_titles,coverage_provinces,
 coverage_towns,organic_score,country_codes
FROM candidates
ORDER BY organic_score DESC,rating_count DESC,lower(display_name),provider_id
LIMIT greatest(1,least(coalesce(p_limit,30),100));
$$;
REVOKE ALL ON FUNCTION public.search_client_providers_international(
 text,uuid,text,text,text,text,numeric,boolean,integer) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.search_client_providers_international(
 text,uuid,text,text,text,text,numeric,boolean,integer) TO authenticated;

-- Available location options reflect actual ACTIVE and VERIFIED listings only.
CREATE OR REPLACE FUNCTION public.list_client_provider_locations()
RETURNS TABLE(country_code text,region text,town text)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path=public,auth AS $$
 SELECT DISTINCT s.coverage_country_code,s.coverage_province,s.coverage_town
 FROM public.provider_services s
 JOIN public.provider_profiles p ON p.provider_id=s.provider_id
 JOIN public.service_categories c ON c.id=s.category_id
 WHERE auth.uid() IS NOT NULL AND s.status='active'
   AND p.is_active AND p.verification_status='verified' AND c.is_active
 ORDER BY 1,2,3 LIMIT 400;
$$;
REVOKE ALL ON FUNCTION public.list_client_provider_locations() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.list_client_provider_locations() TO authenticated;

-- Staged onboarding gains a country-aware endpoint without ever approving a provider.
CREATE OR REPLACE FUNCTION public.submit_staged_provider_application_international(
 p_category_slug text,p_applicant_name text,p_applicant_kind text,
 p_country_code text,p_coverage_region text,p_coverage_town text,
 p_service_summary text
) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,auth AS $$
DECLARE v_id uuid;
BEGIN
 IF upper(coalesce(p_country_code,'')) !~ '^[A-Z]{2}$' THEN
   RAISE EXCEPTION 'A valid ISO 3166-1 alpha-2 country code is required'
   USING errcode='22023';
 END IF;
 v_id:=public.submit_staged_provider_application(p_category_slug,
   p_applicant_name,p_applicant_kind,p_coverage_region,p_coverage_town,
   p_service_summary);
 UPDATE public.staged_provider_applications
 SET coverage_country_code=upper(p_country_code)
 WHERE id=v_id AND user_id=auth.uid();
 RETURN v_id;
END; $$;
REVOKE ALL ON FUNCTION public.submit_staged_provider_application_international(
 text,text,text,text,text,text,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.submit_staged_provider_application_international(
 text,text,text,text,text,text,text) TO authenticated;
