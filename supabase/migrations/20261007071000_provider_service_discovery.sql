-- CX1F: provider and service discovery with confidence-aware ratings.
-- Organic discovery never includes paid promotion. Only active verified providers
-- with active approved services are eligible.

CREATE OR REPLACE FUNCTION public.search_client_providers(
  p_query text DEFAULT NULL,
  p_category_id uuid DEFAULT NULL,
  p_province text DEFAULT NULL,
  p_town text DEFAULT NULL,
  p_limit integer DEFAULT 30
)
RETURNS TABLE (
  provider_id uuid,
  display_name text,
  provider_type text,
  bio text,
  rating_average numeric,
  rating_count integer,
  service_count integer,
  category_ids uuid[],
  category_names text[],
  service_titles text[],
  coverage_provinces text[],
  coverage_towns text[],
  organic_score numeric
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
  WITH eligible_services AS (
    SELECT
      service.id,
      service.provider_id,
      service.category_id,
      service.title,
      service.description,
      service.coverage_province,
      service.coverage_town,
      category.name AS category_name
    FROM public.provider_services service
    JOIN public.service_categories category
      ON category.id = service.category_id
    WHERE auth.uid() IS NOT NULL
      AND service.status = 'active'
      AND category.is_active
      AND (p_category_id IS NULL OR service.category_id = p_category_id)
      AND (
        nullif(btrim(coalesce(p_province, '')), '') IS NULL
        OR lower(btrim(service.coverage_province))
           = lower(btrim(p_province))
      )
      AND (
        nullif(btrim(coalesce(p_town, '')), '') IS NULL
        OR lower(btrim(service.coverage_town))
           = lower(btrim(p_town))
      )
  ),
  candidates AS (
    SELECT
      provider.provider_id,
      provider.display_name,
      provider.provider_type,
      provider.bio,
      provider.rating_average,
      provider.rating_count,
      count(service.id)::integer AS service_count,
      array_agg(DISTINCT service.category_id ORDER BY service.category_id)
        AS category_ids,
      array_agg(DISTINCT service.category_name ORDER BY service.category_name)
        AS category_names,
      array_agg(DISTINCT service.title ORDER BY service.title)
        AS service_titles,
      coalesce(
        array_agg(
          DISTINCT service.coverage_province
          ORDER BY service.coverage_province
        ) FILTER (WHERE service.coverage_province IS NOT NULL),
        '{}'::text[]
      ) AS coverage_provinces,
      coalesce(
        array_agg(
          DISTINCT service.coverage_town
          ORDER BY service.coverage_town
        ) FILTER (WHERE service.coverage_town IS NOT NULL),
        '{}'::text[]
      ) AS coverage_towns,
      round(
        (
          (
            (provider.rating_count::numeric * provider.rating_average)
            + (10::numeric * 4.0::numeric)
          )
          / (provider.rating_count::numeric + 10::numeric)
        )
        + least(ln(provider.rating_count::numeric + 1), 4::numeric) * 0.10,
        4
      ) AS organic_score
    FROM public.provider_profiles provider
    JOIN eligible_services service
      ON service.provider_id = provider.provider_id
    WHERE provider.is_active
      AND provider.verification_status = 'verified'
      AND (
        nullif(btrim(coalesce(p_query, '')), '') IS NULL
        OR lower(provider.display_name)
           LIKE '%' || lower(btrim(p_query)) || '%'
        OR lower(coalesce(provider.bio, ''))
           LIKE '%' || lower(btrim(p_query)) || '%'
        OR EXISTS (
          SELECT 1
          FROM eligible_services match_service
          WHERE match_service.provider_id = provider.provider_id
            AND (
              lower(match_service.title)
                LIKE '%' || lower(btrim(p_query)) || '%'
              OR lower(coalesce(match_service.description, ''))
                LIKE '%' || lower(btrim(p_query)) || '%'
              OR lower(match_service.category_name)
                LIKE '%' || lower(btrim(p_query)) || '%'
            )
        )
      )
    GROUP BY
      provider.provider_id,
      provider.display_name,
      provider.provider_type,
      provider.bio,
      provider.rating_average,
      provider.rating_count
  )
  SELECT
    candidates.provider_id,
    candidates.display_name,
    candidates.provider_type,
    candidates.bio,
    candidates.rating_average,
    candidates.rating_count,
    candidates.service_count,
    candidates.category_ids,
    candidates.category_names,
    candidates.service_titles,
    candidates.coverage_provinces,
    candidates.coverage_towns,
    candidates.organic_score
  FROM candidates
  ORDER BY
    candidates.organic_score DESC,
    candidates.rating_count DESC,
    lower(candidates.display_name),
    candidates.provider_id
  LIMIT greatest(1, least(coalesce(p_limit, 30), 100));
$$;

CREATE OR REPLACE FUNCTION public.list_top_client_providers(
  p_category_id uuid DEFAULT NULL,
  p_province text DEFAULT NULL,
  p_town text DEFAULT NULL,
  p_pool_limit integer DEFAULT 20,
  p_display_limit integer DEFAULT 5
)
RETURNS TABLE (
  provider_id uuid,
  display_name text,
  provider_type text,
  bio text,
  rating_average numeric,
  rating_count integer,
  service_count integer,
  category_ids uuid[],
  category_names text[],
  service_titles text[],
  coverage_provinces text[],
  coverage_towns text[],
  organic_score numeric
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
  WITH ranked_pool AS (
    SELECT *
    FROM public.search_client_providers(
      NULL,
      p_category_id,
      p_province,
      p_town,
      greatest(5, least(coalesce(p_pool_limit, 20), 100))
    )
  )
  SELECT
    ranked_pool.provider_id,
    ranked_pool.display_name,
    ranked_pool.provider_type,
    ranked_pool.bio,
    ranked_pool.rating_average,
    ranked_pool.rating_count,
    ranked_pool.service_count,
    ranked_pool.category_ids,
    ranked_pool.category_names,
    ranked_pool.service_titles,
    ranked_pool.coverage_provinces,
    ranked_pool.coverage_towns,
    ranked_pool.organic_score
  FROM ranked_pool
  ORDER BY md5(current_date::text || ranked_pool.provider_id::text)
  LIMIT greatest(1, least(coalesce(p_display_limit, 5), 10));
$$;

REVOKE ALL ON FUNCTION public.search_client_providers(
  text, uuid, text, text, integer
) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.search_client_providers(
  text, uuid, text, text, integer
) FROM anon;
GRANT EXECUTE ON FUNCTION public.search_client_providers(
  text, uuid, text, text, integer
) TO authenticated;

REVOKE ALL ON FUNCTION public.list_top_client_providers(
  uuid, text, text, integer, integer
) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.list_top_client_providers(
  uuid, text, text, integer, integer
) FROM anon;
GRANT EXECUTE ON FUNCTION public.list_top_client_providers(
  uuid, text, text, integer, integer
) TO authenticated;

COMMENT ON FUNCTION public.search_client_providers(
  text, uuid, text, text, integer
) IS
  'Searches active verified Wantok providers through their active services using optional category/place filters and a confidence-aware organic rating score.';

COMMENT ON FUNCTION public.list_top_client_providers(
  uuid, text, text, integer, integer
) IS
  'Returns a daily rotating display subset from a qualified organic provider pool. Sponsored placement is deliberately excluded.';
