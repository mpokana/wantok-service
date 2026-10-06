-- CX1B delegated Taxi / Ride booking.
-- The authenticated Wantok account remains rides.passenger_id (owner/payer).
-- Optional Trusted-person details are snapshotted as the actual rider.

ALTER TABLE public.rides
  ADD COLUMN trusted_person_id uuid
    REFERENCES public.trusted_people(id) ON DELETE SET NULL,
  ADD COLUMN beneficiary_name text,
  ADD COLUMN beneficiary_relationship text,
  ADD COLUMN beneficiary_phone text,
  ADD COLUMN beneficiary_email text;

ALTER TABLE public.rides
  ADD CONSTRAINT rides_beneficiary_name_not_blank
  CHECK (
    beneficiary_name IS NULL
    OR NULLIF(trim(beneficiary_name), '') IS NOT NULL
  );

CREATE INDEX rides_passenger_trusted_person_idx
  ON public.rides (passenger_id, trusted_person_id, created_at DESC)
  WHERE trusted_person_id IS NOT NULL;

COMMENT ON COLUMN public.rides.trusted_person_id IS
  'Optional customer-owned Trusted person selected as the actual rider. ON DELETE SET NULL; beneficiary snapshot fields preserve history.';

COMMENT ON COLUMN public.rides.beneficiary_name IS
  'Actual rider name snapshot for delegated Taxi/Ride bookings. NULL means the account holder is riding.';

CREATE OR REPLACE FUNCTION public.request_taxi_ride(
  p_pickup_lat double precision,
  p_pickup_lng double precision,
  p_dropoff_lat double precision,
  p_dropoff_lng double precision,
  p_pickup_label text DEFAULT NULL,
  p_dropoff_label text DEFAULT NULL,
  p_trusted_person_id uuid DEFAULT NULL
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
  v_beneficiary public.trusted_people%ROWTYPE;
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

  IF p_trusted_person_id IS NOT NULL THEN
    SELECT *
    INTO v_beneficiary
    FROM public.trusted_people
    WHERE id = p_trusted_person_id
      AND owner_id = v_user_id
      AND is_active = true;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Trusted person is not available';
    END IF;
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
    distance_km,
    trusted_person_id,
    beneficiary_name,
    beneficiary_relationship,
    beneficiary_phone,
    beneficiary_email
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
    v_trip_distance,
    p_trusted_person_id,
    CASE
      WHEN p_trusted_person_id IS NULL THEN NULL
      ELSE v_beneficiary.display_name
    END,
    CASE
      WHEN p_trusted_person_id IS NULL THEN NULL
      ELSE v_beneficiary.relationship
    END,
    CASE
      WHEN p_trusted_person_id IS NULL THEN NULL
      ELSE v_beneficiary.phone
    END,
    CASE
      WHEN p_trusted_person_id IS NULL THEN NULL
      ELSE v_beneficiary.email
    END
  )
  RETURNING * INTO v_ride;

  PERFORM public.dispatch_next_taxi_driver(v_ride.id);

  RETURN v_ride;
END;
$$;

DROP FUNCTION IF EXISTS public.request_taxi_ride(
  double precision,
  double precision,
  double precision,
  double precision,
  text,
  text
);

REVOKE ALL ON FUNCTION public.request_taxi_ride(
  double precision,
  double precision,
  double precision,
  double precision,
  text,
  text,
  uuid
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.request_taxi_ride(
  double precision,
  double precision,
  double precision,
  double precision,
  text,
  text,
  uuid
) TO authenticated;

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
    'passenger_name', COALESCE(r.beneficiary_name, p.full_name),
    'passenger_phone', COALESCE(r.beneficiary_phone, p.phone),
    'booked_by_name', p.full_name,
    'beneficiary_relationship', r.beneficiary_relationship,
    'is_delegated', (r.beneficiary_name IS NOT NULL)
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
    'trusted_person_id', r.trusted_person_id,
    'beneficiary_name', r.beneficiary_name,
    'beneficiary_relationship', r.beneficiary_relationship,
    'beneficiary_phone', r.beneficiary_phone,
    'beneficiary_email', r.beneficiary_email,
    'is_delegated', (r.beneficiary_name IS NOT NULL),
    'booked_by_name', passenger.full_name,
    'passenger_name', COALESCE(r.beneficiary_name, passenger.full_name),
    'passenger_phone', COALESCE(r.beneficiary_phone, passenger.phone),
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
