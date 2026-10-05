-- Wantok Service taxi dispatch and ride lifecycle.
-- Replaces the prototype "assign nearest driver immediately" flow with a
-- server-controlled offer / accept / progress workflow.

ALTER TABLE public.rides
  ADD COLUMN IF NOT EXISTS pickup_label text,
  ADD COLUMN IF NOT EXISTS dropoff_label text,
  ADD COLUMN IF NOT EXISTS final_fare numeric(10,2)
    CHECK (final_fare IS NULL OR final_fare >= 0),
  ADD COLUMN IF NOT EXISTS accepted_at timestamptz,
  ADD COLUMN IF NOT EXISTS arrived_at timestamptz,
  ADD COLUMN IF NOT EXISTS started_at timestamptz,
  ADD COLUMN IF NOT EXISTS completed_at timestamptz,
  ADD COLUMN IF NOT EXISTS cancelled_at timestamptz,
  ADD COLUMN IF NOT EXISTS cancellation_reason text;

CREATE TABLE public.ride_driver_offers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ride_id uuid NOT NULL REFERENCES public.rides(id) ON DELETE CASCADE,
  driver_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'offered'
    CHECK (status IN ('offered', 'accepted', 'declined', 'expired', 'cancelled')),
  driver_distance_km numeric(10,3) NOT NULL CHECK (driver_distance_km >= 0),
  offered_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz NOT NULL DEFAULT (now() + interval '30 seconds'),
  responded_at timestamptz,
  UNIQUE (ride_id, driver_id)
);

CREATE INDEX ride_driver_offers_driver_status_idx
  ON public.ride_driver_offers (driver_id, status, expires_at);
CREATE INDEX ride_driver_offers_ride_status_idx
  ON public.ride_driver_offers (ride_id, status, offered_at DESC);

ALTER TABLE public.ride_driver_offers ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.ride_driver_offers FROM anon, authenticated;
GRANT SELECT ON TABLE public.ride_driver_offers TO authenticated;

CREATE POLICY ride_driver_offers_select_own_or_admin
ON public.ride_driver_offers
FOR SELECT
TO authenticated
USING (
  driver_id = auth.uid()
  OR public.is_admin(auth.uid())
);

-- Ride state is authoritative through RPCs from this migration forward.
REVOKE UPDATE ON TABLE public.rides FROM authenticated;

-- Retire prototype driver discovery. Live driver coordinates are visible only
-- to the driver, administrators, and assigned ride participants through secured RPCs.
REVOKE EXECUTE ON FUNCTION public.list_available_drivers() FROM authenticated;
DROP POLICY IF EXISTS driver_locations_select_available
  ON public.driver_locations;
CREATE POLICY driver_locations_select_own_or_admin
ON public.driver_locations
FOR SELECT
TO authenticated
USING (
  driver_id = auth.uid()
  OR public.is_admin(auth.uid())
);

-- Disable the prototype RPC that immediately assigned a driver.
REVOKE EXECUTE ON FUNCTION public.request_ride(
  double precision,
  double precision,
  double precision,
  double precision
) FROM authenticated;

CREATE OR REPLACE FUNCTION public.dispatch_next_taxi_driver(p_ride_id uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_ride public.rides%ROWTYPE;
  v_driver_id uuid;
  v_distance double precision;
BEGIN
  SELECT *
  INTO v_ride
  FROM public.rides
  WHERE id = p_ride_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Ride not found';
  END IF;

  IF v_ride.status <> 'pending' OR v_ride.driver_id IS NOT NULL THEN
    RETURN NULL;
  END IF;

  UPDATE public.ride_driver_offers
  SET status = 'expired',
      responded_at = COALESCE(responded_at, now())
  WHERE ride_id = p_ride_id
    AND status = 'offered'
    AND expires_at <= now();

  IF EXISTS (
    SELECT 1
    FROM public.ride_driver_offers
    WHERE ride_id = p_ride_id
      AND status = 'offered'
      AND expires_at > now()
  ) THEN
    RETURN NULL;
  END IF;

  SELECT
    dl.driver_id,
    public.haversine_km(
      v_ride.pickup_lat,
      v_ride.pickup_lng,
      dl.lat,
      dl.lng
    )
  INTO v_driver_id, v_distance
  FROM public.driver_locations AS dl
  JOIN public.profiles AS p
    ON p.id = dl.driver_id
  WHERE dl.is_online = true
    AND dl.updated_at >= now() - interval '30 seconds'
    AND p.is_driver = true
    AND p.is_driver_approved = true
    AND public.has_role('driver', dl.driver_id)
    AND NOT EXISTS (
      SELECT 1
      FROM public.rides AS active_ride
      WHERE active_ride.driver_id = dl.driver_id
        AND active_ride.status NOT IN ('completed', 'cancelled')
    )
    AND NOT EXISTS (
      SELECT 1
      FROM public.ride_driver_offers AS prior_offer
      WHERE prior_offer.ride_id = p_ride_id
        AND prior_offer.driver_id = dl.driver_id
    )
    AND NOT EXISTS (
      SELECT 1
      FROM public.ride_driver_offers AS other_offer
      WHERE other_offer.driver_id = dl.driver_id
        AND other_offer.status = 'offered'
        AND other_offer.expires_at > now()
        AND other_offer.ride_id <> p_ride_id
    )
  ORDER BY public.haversine_km(
    v_ride.pickup_lat,
    v_ride.pickup_lng,
    dl.lat,
    dl.lng
  )
  FOR UPDATE OF dl SKIP LOCKED
  LIMIT 1;

  IF v_driver_id IS NULL THEN
    RETURN NULL;
  END IF;

  INSERT INTO public.ride_driver_offers (
    ride_id,
    driver_id,
    driver_distance_km,
    expires_at
  )
  VALUES (
    p_ride_id,
    v_driver_id,
    round(v_distance::numeric, 3),
    now() + interval '30 seconds'
  );

  RETURN v_driver_id;
END;
$$;

REVOKE ALL ON FUNCTION public.dispatch_next_taxi_driver(uuid) FROM PUBLIC;

CREATE OR REPLACE FUNCTION public.request_taxi_ride(
  p_pickup_lat double precision,
  p_pickup_lng double precision,
  p_dropoff_lat double precision,
  p_dropoff_lng double precision,
  p_pickup_label text DEFAULT NULL,
  p_dropoff_label text DEFAULT NULL
)
RETURNS public.rides
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_trip_distance double precision;
  v_fare numeric(10,2);
  v_ride public.rides%ROWTYPE;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF NOT (p_pickup_lat BETWEEN -90 AND 90)
     OR NOT (p_dropoff_lat BETWEEN -90 AND 90)
     OR NOT (p_pickup_lng BETWEEN -180 AND 180)
     OR NOT (p_dropoff_lng BETWEEN -180 AND 180) THEN
    RAISE EXCEPTION 'Invalid ride coordinates';
  END IF;

  IF public.haversine_km(
    p_pickup_lat,
    p_pickup_lng,
    p_dropoff_lat,
    p_dropoff_lng
  ) < 0.05 THEN
    RAISE EXCEPTION 'Pickup and destination are too close';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.rides AS r
    WHERE r.passenger_id = v_user_id
      AND r.status NOT IN ('completed', 'cancelled')
  ) THEN
    RAISE EXCEPTION 'Passenger already has an active ride';
  END IF;

  v_trip_distance := public.haversine_km(
    p_pickup_lat,
    p_pickup_lng,
    p_dropoff_lat,
    p_dropoff_lng
  );

  v_fare := round(
    greatest(5.0 + (2.5 * v_trip_distance), 8.0)::numeric,
    2
  );

  INSERT INTO public.rides (
    passenger_id,
    driver_id,
    pickup_lat,
    pickup_lng,
    dropoff_lat,
    dropoff_lng,
    pickup_label,
    dropoff_label,
    status,
    fare_estimate,
    distance_km
  )
  VALUES (
    v_user_id,
    NULL,
    p_pickup_lat,
    p_pickup_lng,
    p_dropoff_lat,
    p_dropoff_lng,
    NULLIF(trim(p_pickup_label), ''),
    NULLIF(trim(p_dropoff_label), ''),
    'pending',
    v_fare,
    v_trip_distance
  )
  RETURNING * INTO v_ride;

  PERFORM public.dispatch_next_taxi_driver(v_ride.id);

  RETURN v_ride;
END;
$$;

REVOKE ALL ON FUNCTION public.request_taxi_ride(
  double precision,
  double precision,
  double precision,
  double precision,
  text,
  text
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.request_taxi_ride(
  double precision,
  double precision,
  double precision,
  double precision,
  text,
  text
) TO authenticated;

CREATE OR REPLACE FUNCTION public.refresh_taxi_dispatch(p_ride_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_ride public.rides%ROWTYPE;
BEGIN
  SELECT *
  INTO v_ride
  FROM public.rides
  WHERE id = p_ride_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Ride not found';
  END IF;

  IF v_ride.passenger_id <> auth.uid()
     AND NOT public.is_admin(auth.uid()) THEN
    RAISE EXCEPTION 'Not authorized for this ride';
  END IF;

  IF v_ride.status <> 'pending' THEN
    RETURN false;
  END IF;

  PERFORM public.dispatch_next_taxi_driver(p_ride_id);

  RETURN EXISTS (
    SELECT 1
    FROM public.ride_driver_offers
    WHERE ride_id = p_ride_id
      AND status = 'offered'
      AND expires_at > now()
  );
END;
$$;

REVOKE ALL ON FUNCTION public.refresh_taxi_dispatch(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.refresh_taxi_dispatch(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.get_driver_pending_ride_offer()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_driver_id uuid := auth.uid();
  v_result jsonb;
BEGIN
  IF v_driver_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF NOT public.has_role('driver', v_driver_id) THEN
    RAISE EXCEPTION 'Driver role required';
  END IF;

  UPDATE public.ride_driver_offers
  SET status = 'expired',
      responded_at = COALESCE(responded_at, now())
  WHERE driver_id = v_driver_id
    AND status = 'offered'
    AND expires_at <= now();

  SELECT jsonb_build_object(
    'offer_id', o.id,
    'ride_id', r.id,
    'status', o.status,
    'expires_at', o.expires_at,
    'driver_distance_km', o.driver_distance_km,
    'pickup_lat', r.pickup_lat,
    'pickup_lng', r.pickup_lng,
    'dropoff_lat', r.dropoff_lat,
    'dropoff_lng', r.dropoff_lng,
    'pickup_label', r.pickup_label,
    'dropoff_label', r.dropoff_label,
    'trip_distance_km', r.distance_km,
    'fare_estimate', r.fare_estimate,
    'passenger_name', p.full_name,
    'passenger_phone', p.phone
  )
  INTO v_result
  FROM public.ride_driver_offers AS o
  JOIN public.rides AS r ON r.id = o.ride_id
  JOIN public.profiles AS p ON p.id = r.passenger_id
  WHERE o.driver_id = v_driver_id
    AND o.status = 'offered'
    AND o.expires_at > now()
    AND r.status = 'pending'
  ORDER BY o.offered_at
  LIMIT 1;

  RETURN v_result;
END;
$$;

REVOKE ALL ON FUNCTION public.get_driver_pending_ride_offer() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_driver_pending_ride_offer() TO authenticated;

CREATE OR REPLACE FUNCTION public.driver_respond_taxi_offer(
  p_ride_id uuid,
  p_accept boolean
)
RETURNS public.rides
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_driver_id uuid := auth.uid();
  v_offer public.ride_driver_offers%ROWTYPE;
  v_ride public.rides%ROWTYPE;
BEGIN
  IF v_driver_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT *
  INTO v_offer
  FROM public.ride_driver_offers
  WHERE ride_id = p_ride_id
    AND driver_id = v_driver_id
    AND status = 'offered'
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'No active ride offer found';
  END IF;

  IF v_offer.expires_at <= now() THEN
    UPDATE public.ride_driver_offers
    SET status = 'expired',
        responded_at = now()
    WHERE id = v_offer.id;

    PERFORM public.dispatch_next_taxi_driver(p_ride_id);
    RAISE EXCEPTION 'Ride offer has expired';
  END IF;

  SELECT *
  INTO v_ride
  FROM public.rides
  WHERE id = p_ride_id
  FOR UPDATE;

  IF v_ride.status <> 'pending' OR v_ride.driver_id IS NOT NULL THEN
    UPDATE public.ride_driver_offers
    SET status = 'cancelled',
        responded_at = now()
    WHERE id = v_offer.id;
    RAISE EXCEPTION 'Ride is no longer available';
  END IF;

  IF NOT p_accept THEN
    UPDATE public.ride_driver_offers
    SET status = 'declined',
        responded_at = now()
    WHERE id = v_offer.id;

    PERFORM public.dispatch_next_taxi_driver(p_ride_id);

    SELECT * INTO v_ride
    FROM public.rides
    WHERE id = p_ride_id;

    RETURN v_ride;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.rides
    WHERE driver_id = v_driver_id
      AND status NOT IN ('completed', 'cancelled')
  ) THEN
    RAISE EXCEPTION 'Driver already has an active ride';
  END IF;

  UPDATE public.ride_driver_offers
  SET status = 'accepted',
      responded_at = now()
  WHERE id = v_offer.id;

  UPDATE public.ride_driver_offers
  SET status = 'cancelled',
      responded_at = COALESCE(responded_at, now())
  WHERE ride_id = p_ride_id
    AND id <> v_offer.id
    AND status = 'offered';

  UPDATE public.rides
  SET driver_id = v_driver_id,
      status = 'accepted',
      accepted_at = now()
  WHERE id = p_ride_id
  RETURNING * INTO v_ride;

  RETURN v_ride;
END;
$$;

REVOKE ALL ON FUNCTION public.driver_respond_taxi_offer(uuid, boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.driver_respond_taxi_offer(uuid, boolean)
TO authenticated;

CREATE OR REPLACE FUNCTION public.driver_update_taxi_status(
  p_ride_id uuid,
  p_status text
)
RETURNS public.rides
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_driver_id uuid := auth.uid();
  v_target text := lower(trim(COALESCE(p_status, '')));
  v_ride public.rides%ROWTYPE;
BEGIN
  SELECT *
  INTO v_ride
  FROM public.rides
  WHERE id = p_ride_id
    AND driver_id = v_driver_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Assigned ride not found';
  END IF;

  IF NOT (
    (v_ride.status = 'accepted' AND v_target = 'arriving')
    OR (v_ride.status = 'arriving' AND v_target = 'arrived')
    OR (v_ride.status = 'arrived' AND v_target = 'in_progress')
    OR (v_ride.status = 'in_progress' AND v_target = 'completed')
  ) THEN
    RAISE EXCEPTION 'Invalid ride status transition';
  END IF;

  UPDATE public.rides
  SET status = v_target,
      arrived_at = CASE
        WHEN v_target = 'arrived' THEN now()
        ELSE arrived_at
      END,
      started_at = CASE
        WHEN v_target = 'in_progress' THEN now()
        ELSE started_at
      END,
      completed_at = CASE
        WHEN v_target = 'completed' THEN now()
        ELSE completed_at
      END,
      final_fare = CASE
        WHEN v_target = 'completed' THEN COALESCE(final_fare, fare_estimate)
        ELSE final_fare
      END
  WHERE id = p_ride_id
  RETURNING * INTO v_ride;

  RETURN v_ride;
END;
$$;

REVOKE ALL ON FUNCTION public.driver_update_taxi_status(uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.driver_update_taxi_status(uuid, text)
TO authenticated;

CREATE OR REPLACE FUNCTION public.cancel_taxi_ride(
  p_ride_id uuid,
  p_reason text DEFAULT NULL
)
RETURNS public.rides
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_ride public.rides%ROWTYPE;
BEGIN
  SELECT *
  INTO v_ride
  FROM public.rides
  WHERE id = p_ride_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Ride not found';
  END IF;

  IF v_ride.passenger_id <> v_user_id
     AND v_ride.driver_id <> v_user_id
     AND NOT public.is_admin(v_user_id) THEN
    RAISE EXCEPTION 'Not authorized for this ride';
  END IF;

  IF v_ride.status IN ('completed', 'cancelled', 'in_progress') THEN
    RAISE EXCEPTION 'Ride cannot be cancelled in its current state';
  END IF;

  UPDATE public.rides
  SET status = 'cancelled',
      cancelled_at = now(),
      cancellation_reason = NULLIF(trim(p_reason), '')
  WHERE id = p_ride_id
  RETURNING * INTO v_ride;

  UPDATE public.ride_driver_offers
  SET status = 'cancelled',
      responded_at = COALESCE(responded_at, now())
  WHERE ride_id = p_ride_id
    AND status = 'offered';

  RETURN v_ride;
END;
$$;

REVOKE ALL ON FUNCTION public.cancel_taxi_ride(uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.cancel_taxi_ride(uuid, text)
TO authenticated;

CREATE OR REPLACE FUNCTION public.set_driver_online(
  p_lat double precision,
  p_lng double precision,
  p_heading double precision DEFAULT NULL,
  p_is_online boolean DEFAULT true
)
RETURNS public.driver_locations
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_driver_id uuid := auth.uid();
  v_location public.driver_locations%ROWTYPE;
BEGIN
  IF v_driver_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF NOT public.has_role('driver', v_driver_id)
     OR NOT EXISTS (
       SELECT 1
       FROM public.profiles
       WHERE id = v_driver_id
         AND is_driver = true
         AND is_driver_approved = true
     ) THEN
    RAISE EXCEPTION 'Approved driver role required';
  END IF;

  IF NOT (p_lat BETWEEN -90 AND 90)
     OR NOT (p_lng BETWEEN -180 AND 180) THEN
    RAISE EXCEPTION 'Invalid driver coordinates';
  END IF;

  INSERT INTO public.driver_locations (
    driver_id,
    lat,
    lng,
    heading,
    is_online,
    updated_at
  )
  VALUES (
    v_driver_id,
    p_lat,
    p_lng,
    p_heading,
    p_is_online,
    now()
  )
  ON CONFLICT (driver_id)
  DO UPDATE SET
    lat = EXCLUDED.lat,
    lng = EXCLUDED.lng,
    heading = EXCLUDED.heading,
    is_online = EXCLUDED.is_online,
    updated_at = now()
  RETURNING * INTO v_location;

  RETURN v_location;
END;
$$;

REVOKE ALL ON FUNCTION public.set_driver_online(
  double precision,
  double precision,
  double precision,
  boolean
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.set_driver_online(
  double precision,
  double precision,
  double precision,
  boolean
) TO authenticated;

CREATE OR REPLACE FUNCTION public.get_taxi_ride_details(p_ride_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_ride public.rides%ROWTYPE;
  v_is_offered_driver boolean := false;
  v_result jsonb;
BEGIN
  SELECT *
  INTO v_ride
  FROM public.rides
  WHERE id = p_ride_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Ride not found';
  END IF;

  SELECT EXISTS (
    SELECT 1
    FROM public.ride_driver_offers
    WHERE ride_id = p_ride_id
      AND driver_id = v_user_id
      AND status = 'offered'
      AND expires_at > now()
  ) INTO v_is_offered_driver;

  IF v_ride.passenger_id <> v_user_id
     AND v_ride.driver_id IS DISTINCT FROM v_user_id
     AND NOT v_is_offered_driver
     AND NOT public.is_admin(v_user_id) THEN
    RAISE EXCEPTION 'Not authorized for this ride';
  END IF;

  SELECT jsonb_build_object(
    'id', r.id,
    'passenger_id', r.passenger_id,
    'driver_id', r.driver_id,
    'status', r.status,
    'pickup_lat', r.pickup_lat,
    'pickup_lng', r.pickup_lng,
    'dropoff_lat', r.dropoff_lat,
    'dropoff_lng', r.dropoff_lng,
    'pickup_label', r.pickup_label,
    'dropoff_label', r.dropoff_label,
    'fare_estimate', r.fare_estimate,
    'final_fare', r.final_fare,
    'distance_km', r.distance_km,
    'created_at', r.created_at,
    'accepted_at', r.accepted_at,
    'arrived_at', r.arrived_at,
    'started_at', r.started_at,
    'completed_at', r.completed_at,
    'cancelled_at', r.cancelled_at,
    'passenger_name', passenger.full_name,
    'passenger_phone', passenger.phone,
    'driver_name', driver.full_name,
    'driver_phone', driver.phone,
    'vehicle_rego', dp.vehicle_rego,
    'vehicle_make', dp.vehicle_make,
    'vehicle_model', dp.vehicle_model,
    'vehicle_colour', dp.vehicle_colour,
    'vehicle_image_url', dp.vehicle_image_url,
    'driver_lat', dl.lat,
    'driver_lng', dl.lng,
    'driver_heading', dl.heading,
    'driver_location_updated_at', dl.updated_at
  )
  INTO v_result
  FROM public.rides AS r
  JOIN public.profiles AS passenger ON passenger.id = r.passenger_id
  LEFT JOIN public.profiles AS driver ON driver.id = r.driver_id
  LEFT JOIN public.driver_profiles AS dp ON dp.driver_id = r.driver_id
  LEFT JOIN public.driver_locations AS dl ON dl.driver_id = r.driver_id
  WHERE r.id = p_ride_id;

  RETURN v_result;
END;
$$;

REVOKE ALL ON FUNCTION public.get_taxi_ride_details(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_taxi_ride_details(uuid) TO authenticated;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'ride_driver_offers'
  ) THEN
    ALTER PUBLICATION supabase_realtime
      ADD TABLE public.ride_driver_offers;
  END IF;
END;
$$;
