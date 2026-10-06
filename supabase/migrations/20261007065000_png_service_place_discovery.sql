-- CX1E: PNG place and destination discovery backed by real service coverage.
-- Providers attach structured province/town labels to listings, resources,
-- events and water-route endpoints. Client discovery only surfaces places that
-- currently have active, verified coverage.

ALTER TABLE public.provider_services
  ADD COLUMN coverage_province text,
  ADD COLUMN coverage_town text;

ALTER TABLE public.provider_resources
  ADD COLUMN coverage_province text,
  ADD COLUMN coverage_town text;

ALTER TABLE public.events
  ADD COLUMN venue_province text,
  ADD COLUMN venue_town text;

ALTER TABLE public.water_routes
  ADD COLUMN origin_province text,
  ADD COLUMN origin_town text,
  ADD COLUMN destination_province text,
  ADD COLUMN destination_town text;

ALTER TABLE public.provider_services
  ADD CONSTRAINT provider_services_coverage_province_length
    CHECK (coverage_province IS NULL OR char_length(btrim(coverage_province)) BETWEEN 2 AND 100),
  ADD CONSTRAINT provider_services_coverage_town_length
    CHECK (coverage_town IS NULL OR char_length(btrim(coverage_town)) BETWEEN 2 AND 100),
  ADD CONSTRAINT provider_services_coverage_town_requires_province
    CHECK (coverage_town IS NULL OR coverage_province IS NOT NULL);

ALTER TABLE public.provider_resources
  ADD CONSTRAINT provider_resources_coverage_province_length
    CHECK (coverage_province IS NULL OR char_length(btrim(coverage_province)) BETWEEN 2 AND 100),
  ADD CONSTRAINT provider_resources_coverage_town_length
    CHECK (coverage_town IS NULL OR char_length(btrim(coverage_town)) BETWEEN 2 AND 100),
  ADD CONSTRAINT provider_resources_coverage_town_requires_province
    CHECK (coverage_town IS NULL OR coverage_province IS NOT NULL);

ALTER TABLE public.events
  ADD CONSTRAINT events_venue_province_length
    CHECK (venue_province IS NULL OR char_length(btrim(venue_province)) BETWEEN 2 AND 100),
  ADD CONSTRAINT events_venue_town_length
    CHECK (venue_town IS NULL OR char_length(btrim(venue_town)) BETWEEN 2 AND 100),
  ADD CONSTRAINT events_venue_town_requires_province
    CHECK (venue_town IS NULL OR venue_province IS NOT NULL);

ALTER TABLE public.water_routes
  ADD CONSTRAINT water_routes_origin_province_length
    CHECK (origin_province IS NULL OR char_length(btrim(origin_province)) BETWEEN 2 AND 100),
  ADD CONSTRAINT water_routes_origin_town_length
    CHECK (origin_town IS NULL OR char_length(btrim(origin_town)) BETWEEN 2 AND 100),
  ADD CONSTRAINT water_routes_destination_province_length
    CHECK (destination_province IS NULL OR char_length(btrim(destination_province)) BETWEEN 2 AND 100),
  ADD CONSTRAINT water_routes_destination_town_length
    CHECK (destination_town IS NULL OR char_length(btrim(destination_town)) BETWEEN 2 AND 100),
  ADD CONSTRAINT water_routes_origin_town_requires_province
    CHECK (origin_town IS NULL OR origin_province IS NOT NULL),
  ADD CONSTRAINT water_routes_destination_town_requires_province
    CHECK (destination_town IS NULL OR destination_province IS NOT NULL);

CREATE INDEX provider_services_coverage_place_idx
  ON public.provider_services (
    lower(btrim(coverage_province)),
    lower(btrim(coverage_town))
  )
  WHERE status = 'active' AND coverage_province IS NOT NULL;

CREATE INDEX provider_resources_coverage_place_idx
  ON public.provider_resources (
    lower(btrim(coverage_province)),
    lower(btrim(coverage_town))
  )
  WHERE status = 'active' AND coverage_province IS NOT NULL;

CREATE INDEX events_venue_place_idx
  ON public.events (
    lower(btrim(venue_province)),
    lower(btrim(venue_town)),
    starts_at
  )
  WHERE status = 'published' AND venue_province IS NOT NULL;

CREATE INDEX water_routes_origin_place_idx
  ON public.water_routes (
    lower(btrim(origin_province)),
    lower(btrim(origin_town))
  )
  WHERE status = 'active' AND origin_province IS NOT NULL;

CREATE INDEX water_routes_destination_place_idx
  ON public.water_routes (
    lower(btrim(destination_province)),
    lower(btrim(destination_town))
  )
  WHERE status = 'active' AND destination_province IS NOT NULL;
CREATE OR REPLACE FUNCTION public.list_client_service_places(
  p_limit integer DEFAULT 30
)
RETURNS TABLE (
  province text,
  town text,
  category_ids uuid[],
  category_names text[],
  listing_count integer,
  event_count integer,
  route_count integer
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
  WITH coverage AS (
    SELECT
      btrim(service.coverage_province) AS province,
      nullif(btrim(service.coverage_town), '') AS town,
      service.category_id,
      1 AS listing_count,
      0 AS event_count,
      0 AS route_count
    FROM public.provider_services service
    JOIN public.provider_profiles provider
      ON provider.provider_id = service.provider_id
    WHERE auth.uid() IS NOT NULL
      AND service.status = 'active'
      AND provider.is_active
      AND provider.verification_status = 'verified'
      AND nullif(btrim(service.coverage_province), '') IS NOT NULL

    UNION ALL

    SELECT
      btrim(resource.coverage_province),
      nullif(btrim(resource.coverage_town), ''),
      resource.category_id,
      1,
      0,
      0
    FROM public.provider_resources resource
    JOIN public.provider_profiles provider
      ON provider.provider_id = resource.provider_id
    WHERE auth.uid() IS NOT NULL
      AND resource.status = 'active'
      AND provider.is_active
      AND provider.verification_status = 'verified'
      AND nullif(btrim(resource.coverage_province), '') IS NOT NULL

    UNION ALL

    SELECT
      btrim(event.venue_province),
      nullif(btrim(event.venue_town), ''),
      service.category_id,
      0,
      1,
      0
    FROM public.events event
    JOIN public.provider_services service
      ON service.id = event.provider_service_id
    JOIN public.provider_profiles provider
      ON provider.provider_id = event.provider_id
    WHERE auth.uid() IS NOT NULL
      AND event.status = 'published'
      AND event.starts_at >= now()
      AND service.status = 'active'
      AND provider.is_active
      AND provider.verification_status = 'verified'
      AND nullif(btrim(event.venue_province), '') IS NOT NULL

    UNION ALL

    SELECT
      btrim(route.origin_province),
      nullif(btrim(route.origin_town), ''),
      service.category_id,
      0,
      0,
      1
    FROM public.water_routes route
    JOIN public.provider_services service
      ON service.id = route.provider_service_id
    JOIN public.provider_profiles provider
      ON provider.provider_id = route.provider_id
    WHERE auth.uid() IS NOT NULL
      AND route.status = 'active'
      AND service.status = 'active'
      AND provider.is_active
      AND provider.verification_status = 'verified'
      AND nullif(btrim(route.origin_province), '') IS NOT NULL

    UNION ALL

    SELECT
      btrim(route.destination_province),
      nullif(btrim(route.destination_town), ''),
      service.category_id,
      0,
      0,
      1
    FROM public.water_routes route
    JOIN public.provider_services service
      ON service.id = route.provider_service_id
    JOIN public.provider_profiles provider
      ON provider.provider_id = route.provider_id
    WHERE auth.uid() IS NOT NULL
      AND route.status = 'active'
      AND service.status = 'active'
      AND provider.is_active
      AND provider.verification_status = 'verified'
      AND nullif(btrim(route.destination_province), '') IS NOT NULL
  ),
  grouped AS (
    SELECT
      min(coverage.province) AS province,
      min(coverage.town) AS town,
      lower(coverage.province) AS province_key,
      lower(coalesce(coverage.town, '')) AS town_key,
      array_agg(DISTINCT coverage.category_id ORDER BY coverage.category_id)
        AS category_ids,
      sum(coverage.listing_count)::integer AS listing_count,
      sum(coverage.event_count)::integer AS event_count,
      sum(coverage.route_count)::integer AS route_count
    FROM coverage
    GROUP BY
      lower(coverage.province),
      lower(coalesce(coverage.town, ''))
  )
  SELECT
    grouped.province,
    grouped.town,
    grouped.category_ids,
    ARRAY(
      SELECT category.name
      FROM public.service_categories category
      WHERE category.id = ANY(grouped.category_ids)
        AND category.is_active
      ORDER BY category.sort_order, category.name
    ) AS category_names,
    grouped.listing_count,
    grouped.event_count,
    grouped.route_count
  FROM grouped
  ORDER BY
    grouped.listing_count + grouped.event_count + grouped.route_count DESC,
    grouped.province_key,
    grouped.town_key
  LIMIT greatest(1, least(coalesce(p_limit, 30), 100));
$$;

REVOKE EXECUTE ON FUNCTION public.list_client_service_places(integer)
  FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.list_client_service_places(integer)
  FROM anon;
GRANT EXECUTE ON FUNCTION public.list_client_service_places(integer)
  TO authenticated;

GRANT UPDATE (coverage_province, coverage_town)
  ON TABLE public.provider_services TO authenticated;

GRANT INSERT (coverage_province, coverage_town),
      UPDATE (coverage_province, coverage_town)
  ON TABLE public.provider_resources TO authenticated;

GRANT INSERT (venue_province, venue_town),
      UPDATE (venue_province, venue_town)
  ON TABLE public.events TO authenticated;

GRANT INSERT (
  origin_province, origin_town,
  destination_province, destination_town
),
UPDATE (
  origin_province, origin_town,
  destination_province, destination_town
)
  ON TABLE public.water_routes TO authenticated;

COMMENT ON FUNCTION public.list_client_service_places(integer) IS
  'Lists PNG province/town destinations only when active verified Wantok services, resources, future events or water routes currently cover them.';
