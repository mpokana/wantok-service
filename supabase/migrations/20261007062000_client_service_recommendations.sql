-- CX1D: privacy-aware client service recommendations.
-- Recommendations use the signed-in customer's saved items, recent service
-- history and optional already-authorised device coordinates. No recommendation
-- data is returned when the customer has opted out.

CREATE OR REPLACE FUNCTION public.list_client_service_recommendations(
  p_lat double precision DEFAULT NULL,
  p_lng double precision DEFAULT NULL,
  p_limit integer DEFAULT 8
)
RETURNS TABLE (
  category_id uuid,
  category_slug text,
  category_name text,
  reason text,
  score integer,
  distance_km double precision
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_allow boolean := true;
  v_limit integer := greatest(1, least(coalesce(p_limit, 8), 20));
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'Authentication required';
  END IF;

  IF (p_lat IS NULL) <> (p_lng IS NULL) THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001',
      MESSAGE = 'Latitude and longitude must be supplied together';
  END IF;

  IF p_lat IS NOT NULL
     AND (p_lat NOT BETWEEN -90 AND 90 OR p_lng NOT BETWEEN -180 AND 180) THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001',
      MESSAGE = 'Invalid recommendation coordinates';
  END IF;

  SELECT coalesce(preferences.allow_recommendations, true)
  INTO v_allow
  FROM public.profiles profile
  LEFT JOIN public.account_preferences preferences
    ON preferences.user_id = profile.id
  WHERE profile.id = v_user_id;

  IF NOT coalesce(v_allow, true) THEN
    RETURN;
  END IF;

  RETURN QUERY
  WITH active_categories AS (
    SELECT category.id, category.slug, category.name, category.sort_order
    FROM public.service_categories category
    WHERE category.is_active
  ),
  saved_raw AS (
    SELECT saved.entity_id AS category_id, 60 AS weight
    FROM public.client_saved_items saved
    WHERE saved.user_id = v_user_id
      AND saved.item_type = 'category'

    UNION ALL

    SELECT service.category_id, 36
    FROM public.client_saved_items saved
    JOIN public.provider_services service
      ON saved.item_type = 'service'
     AND service.id = saved.entity_id
     AND service.status = 'active'
    WHERE saved.user_id = v_user_id

    UNION ALL

    SELECT service.category_id, 24
    FROM public.client_saved_items saved
    JOIN public.provider_services service
      ON saved.item_type = 'provider'
     AND service.provider_id = saved.entity_id
     AND service.status = 'active'
    WHERE saved.user_id = v_user_id

    UNION ALL

    SELECT resource.category_id, 36
    FROM public.client_saved_items saved
    JOIN public.provider_resources resource
      ON saved.item_type = 'resource'
     AND resource.id = saved.entity_id
     AND resource.status = 'active'
    WHERE saved.user_id = v_user_id

    UNION ALL

    SELECT service.category_id, 36
    FROM public.client_saved_items saved
    JOIN public.events event
      ON saved.item_type = 'event'
     AND event.id = saved.entity_id
     AND event.status = 'published'
    JOIN public.provider_services service
      ON service.id = event.provider_service_id
    WHERE saved.user_id = v_user_id
  ),
  saved_scores AS (
    SELECT raw.category_id, least(sum(raw.weight), 72)::integer AS saved_score
    FROM saved_raw raw
    GROUP BY raw.category_id
  ),
  history_raw AS (
    SELECT booking.category_id, booking.created_at
    FROM public.service_bookings booking
    WHERE booking.customer_id = v_user_id
      AND booking.status NOT IN ('cancelled', 'rejected', 'expired')

    UNION ALL

    SELECT orders.category_id, orders.created_at
    FROM public.commerce_orders orders
    WHERE orders.customer_id = v_user_id
      AND orders.status NOT IN ('cancelled', 'rejected')

    UNION ALL

    SELECT service.category_id, registration.created_at
    FROM public.event_registrations registration
    JOIN public.events event
      ON event.id = registration.event_id
    JOIN public.provider_services service
      ON service.id = event.provider_service_id
    WHERE registration.customer_id = v_user_id
      AND registration.status <> 'cancelled'

    UNION ALL

    SELECT service.category_id, booking.created_at
    FROM public.water_passenger_bookings booking
    JOIN public.water_departures departure
      ON departure.id = booking.departure_id
    JOIN public.provider_services service
      ON service.id = departure.provider_service_id
    WHERE booking.customer_id = v_user_id
      AND booking.status NOT IN ('cancelled', 'no_show')

    UNION ALL

    SELECT category.id, ride.created_at
    FROM public.rides ride
    JOIN public.service_categories category
      ON category.slug = 'taxi-ride'
    WHERE ride.passenger_id = v_user_id
      AND ride.status <> 'cancelled'
  ),
  history_scores AS (
    SELECT
      history.category_id,
      least(
        sum(
          CASE
            WHEN history.created_at >= now() - interval '30 days' THEN 18
            WHEN history.created_at >= now() - interval '90 days' THEN 12
            ELSE 6
          END
        ),
        60
      )::integer AS history_score
    FROM history_raw history
    GROUP BY history.category_id
  ),
  coverage_points AS (
    SELECT
      service.category_id,
      coalesce(service.lat, provider.base_lat) AS lat,
      coalesce(service.lng, provider.base_lng) AS lng
    FROM public.provider_services service
    JOIN public.provider_profiles provider
      ON provider.provider_id = service.provider_id
    WHERE service.status = 'active'
      AND provider.is_active
      AND provider.verification_status = 'verified'
      AND coalesce(service.lat, provider.base_lat) IS NOT NULL
      AND coalesce(service.lng, provider.base_lng) IS NOT NULL

    UNION ALL

    SELECT resource.category_id, resource.lat, resource.lng
    FROM public.provider_resources resource
    JOIN public.provider_profiles provider
      ON provider.provider_id = resource.provider_id
    WHERE resource.status = 'active'
      AND provider.is_active
      AND provider.verification_status = 'verified'
      AND resource.lat IS NOT NULL
      AND resource.lng IS NOT NULL

    UNION ALL

    SELECT service.category_id, event.venue_lat, event.venue_lng
    FROM public.events event
    JOIN public.provider_services service
      ON service.id = event.provider_service_id
    JOIN public.provider_profiles provider
      ON provider.provider_id = event.provider_id
    WHERE event.status = 'published'
      AND service.status = 'active'
      AND event.starts_at >= now()
      AND provider.is_active
      AND provider.verification_status = 'verified'
      AND event.venue_lat IS NOT NULL
      AND event.venue_lng IS NOT NULL

    UNION ALL

    SELECT service.category_id, route.origin_lat, route.origin_lng
    FROM public.water_routes route
    JOIN public.provider_services service
      ON service.id = route.provider_service_id
    JOIN public.provider_profiles provider
      ON provider.provider_id = route.provider_id
    WHERE route.status = 'active'
      AND service.status = 'active'
      AND provider.is_active
      AND provider.verification_status = 'verified'
      AND route.origin_lat IS NOT NULL
      AND route.origin_lng IS NOT NULL

    UNION ALL

    SELECT service.category_id, route.destination_lat, route.destination_lng
    FROM public.water_routes route
    JOIN public.provider_services service
      ON service.id = route.provider_service_id
    JOIN public.provider_profiles provider
      ON provider.provider_id = route.provider_id
    WHERE route.status = 'active'
      AND service.status = 'active'
      AND provider.is_active
      AND provider.verification_status = 'verified'
      AND route.destination_lat IS NOT NULL
      AND route.destination_lng IS NOT NULL
  ),
  nearest AS (
    SELECT
      point.category_id,
      min(
        public.haversine_km(
          p_lat,
          p_lng,
          point.lat,
          point.lng
        )
      ) AS distance_km
    FROM coverage_points point
    WHERE p_lat IS NOT NULL
      AND p_lng IS NOT NULL
    GROUP BY point.category_id
  ),
  ranked AS (
    SELECT
      category.id,
      category.slug,
      category.name,
      coalesce(saved.saved_score, 0) AS saved_score,
      coalesce(history.history_score, 0) AS history_score,
      nearest.distance_km,
      CASE
        WHEN nearest.distance_km IS NULL THEN 0
        WHEN nearest.distance_km <= 10 THEN 30
        WHEN nearest.distance_km <= 30 THEN 22
        WHEN nearest.distance_km <= 75 THEN 14
        WHEN nearest.distance_km <= 200 THEN 6
        ELSE 0
      END AS nearby_score,
      category.sort_order
    FROM active_categories category
    LEFT JOIN saved_scores saved
      ON saved.category_id = category.id
    LEFT JOIN history_scores history
      ON history.category_id = category.id
    LEFT JOIN nearest
      ON nearest.category_id = category.id
  )
  SELECT
    ranked.id,
    ranked.slug,
    ranked.name,
    CASE
      WHEN ranked.saved_score >= 60 THEN 'Saved by you'
      WHEN ranked.history_score > 0 THEN 'Based on your recent activity'
      WHEN ranked.nearby_score > 0 AND ranked.distance_km <= 10
        THEN 'Available near you'
      WHEN ranked.nearby_score > 0
        THEN 'Available in your area'
      WHEN ranked.saved_score > 0 THEN 'Related to something you saved'
      ELSE 'Recommended for you'
    END,
    (ranked.saved_score + ranked.history_score + ranked.nearby_score)::integer,
    ranked.distance_km
  FROM ranked
  WHERE ranked.saved_score + ranked.history_score + ranked.nearby_score > 0
  ORDER BY
    ranked.saved_score + ranked.history_score + ranked.nearby_score DESC,
    ranked.distance_km NULLS LAST,
    ranked.sort_order,
    ranked.name
  LIMIT v_limit;
END;
$$;

REVOKE ALL ON FUNCTION public.list_client_service_recommendations(
  double precision,
  double precision,
  integer
) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.list_client_service_recommendations(
  double precision,
  double precision,
  integer
) TO authenticated;

COMMENT ON FUNCTION public.list_client_service_recommendations(
  double precision,
  double precision,
  integer
) IS
  'Returns privacy-aware category recommendations from the signed-in customer saved items, service history and optional already-authorised coordinates; returns no rows when recommendations are disabled.';
