-- Wantok Service scheduled water passenger transport core.
-- Separate from private Boat Hire reservations.

CREATE TABLE public.water_routes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id uuid NOT NULL REFERENCES public.provider_profiles(provider_id) ON DELETE CASCADE,
  provider_service_id uuid NOT NULL REFERENCES public.provider_services(id) ON DELETE CASCADE,
  name text NOT NULL CHECK (char_length(trim(name)) >= 3),
  origin_name text NOT NULL CHECK (char_length(trim(origin_name)) >= 2),
  origin_address text,
  origin_lat double precision CHECK (origin_lat IS NULL OR origin_lat BETWEEN -90 AND 90),
  origin_lng double precision CHECK (origin_lng IS NULL OR origin_lng BETWEEN -180 AND 180),
  destination_name text NOT NULL CHECK (char_length(trim(destination_name)) >= 2),
  destination_address text,
  destination_lat double precision CHECK (destination_lat IS NULL OR destination_lat BETWEEN -90 AND 90),
  destination_lng double precision CHECK (destination_lng IS NULL OR destination_lng BETWEEN -180 AND 180),
  estimated_minutes integer CHECK (estimated_minutes IS NULL OR estimated_minutes > 0),
  status text NOT NULL DEFAULT 'draft'
    CHECK (status IN ('draft', 'active', 'paused', 'retired')),
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX water_routes_provider_status_idx
  ON public.water_routes (provider_id, status, name);
CREATE INDEX water_routes_public_idx
  ON public.water_routes (status, origin_name, destination_name);

CREATE TABLE public.water_vessels (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id uuid NOT NULL REFERENCES public.provider_profiles(provider_id) ON DELETE CASCADE,
  provider_service_id uuid NOT NULL REFERENCES public.provider_services(id) ON DELETE CASCADE,
  name text NOT NULL CHECK (char_length(trim(name)) >= 2),
  registration_number text,
  vessel_type text NOT NULL DEFAULT 'boat'
    CHECK (vessel_type IN ('dinghy', 'boat', 'ferry', 'ship', 'other')),
  total_capacity integer NOT NULL CHECK (total_capacity > 0),
  description text,
  status text NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'maintenance', 'inactive', 'retired')),
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX water_vessels_provider_status_idx
  ON public.water_vessels (provider_id, status, name);

CREATE TABLE public.water_departures (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id uuid NOT NULL REFERENCES public.provider_profiles(provider_id) ON DELETE CASCADE,
  provider_service_id uuid NOT NULL REFERENCES public.provider_services(id) ON DELETE CASCADE,
  route_id uuid NOT NULL REFERENCES public.water_routes(id) ON DELETE RESTRICT,
  vessel_id uuid NOT NULL REFERENCES public.water_vessels(id) ON DELETE RESTRICT,
  departs_at timestamptz NOT NULL,
  arrives_at timestamptz,
  status text NOT NULL DEFAULT 'scheduled'
    CHECK (status IN ('scheduled', 'boarding', 'departed', 'arrived', 'cancelled')),
  booking_open boolean NOT NULL DEFAULT true,
  boarding_point text,
  notes text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (arrives_at IS NULL OR arrives_at > departs_at)
);

CREATE INDEX water_departures_route_time_idx
  ON public.water_departures (route_id, departs_at);
CREATE INDEX water_departures_provider_status_idx
  ON public.water_departures (provider_id, status, departs_at);
CREATE INDEX water_departures_public_idx
  ON public.water_departures (status, booking_open, departs_at);

CREATE TABLE public.water_fare_classes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  departure_id uuid NOT NULL REFERENCES public.water_departures(id) ON DELETE CASCADE,
  name text NOT NULL CHECK (char_length(trim(name)) >= 2),
  description text,
  price numeric(12,2) NOT NULL DEFAULT 0 CHECK (price >= 0),
  currency text NOT NULL DEFAULT 'PGK' CHECK (char_length(currency) = 3),
  capacity integer NOT NULL CHECK (capacity > 0),
  is_active boolean NOT NULL DEFAULT true,
  sort_order integer NOT NULL DEFAULT 0,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX water_fare_classes_departure_idx
  ON public.water_fare_classes (departure_id, is_active, sort_order, name);

CREATE TABLE public.water_passenger_bookings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  departure_id uuid NOT NULL REFERENCES public.water_departures(id) ON DELETE RESTRICT,
  fare_class_id uuid NOT NULL REFERENCES public.water_fare_classes(id) ON DELETE RESTRICT,
  customer_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  provider_id uuid NOT NULL REFERENCES public.provider_profiles(provider_id) ON DELETE RESTRICT,
  passenger_count integer NOT NULL CHECK (passenger_count > 0),
  unit_fare numeric(12,2) NOT NULL CHECK (unit_fare >= 0),
  total_amount numeric(12,2) NOT NULL CHECK (total_amount >= 0),
  currency text NOT NULL DEFAULT 'PGK' CHECK (char_length(currency) = 3),
  status text NOT NULL DEFAULT 'booked'
    CHECK (status IN ('booked', 'cancelled', 'boarded', 'completed', 'no_show')),
  payment_status text NOT NULL DEFAULT 'unpaid'
    CHECK (payment_status IN ('unpaid', 'paid', 'refunded', 'not_required')),
  contact_phone text,
  note text,
  booked_at timestamptz NOT NULL DEFAULT now(),
  cancelled_at timestamptz,
  boarded_at timestamptz,
  completed_at timestamptz,
  no_show_at timestamptz,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX water_passenger_bookings_customer_idx
  ON public.water_passenger_bookings (customer_id, created_at DESC);
CREATE INDEX water_passenger_bookings_departure_status_idx
  ON public.water_passenger_bookings (departure_id, status, created_at);
CREATE INDEX water_passenger_bookings_provider_status_idx
  ON public.water_passenger_bookings (provider_id, status, created_at);

CREATE TABLE public.water_booking_passengers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id uuid NOT NULL REFERENCES public.water_passenger_bookings(id) ON DELETE CASCADE,
  full_name text NOT NULL CHECK (char_length(trim(full_name)) >= 2),
  phone text,
  passenger_type text NOT NULL DEFAULT 'adult'
    CHECK (passenger_type IN ('adult', 'child', 'infant')),
  document_reference text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX water_booking_passengers_booking_idx
  ON public.water_booking_passengers (booking_id, created_at);

CREATE TRIGGER water_routes_set_updated_at
BEFORE UPDATE ON public.water_routes
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER water_vessels_set_updated_at
BEFORE UPDATE ON public.water_vessels
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER water_departures_set_updated_at
BEFORE UPDATE ON public.water_departures
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER water_fare_classes_set_updated_at
BEFORE UPDATE ON public.water_fare_classes
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER water_passenger_bookings_set_updated_at
BEFORE UPDATE ON public.water_passenger_bookings
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.water_routes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.water_vessels ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.water_departures ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.water_fare_classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.water_passenger_bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.water_booking_passengers ENABLE ROW LEVEL SECURITY;

GRANT SELECT ON public.water_routes TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON public.water_routes TO authenticated;
GRANT SELECT ON public.water_vessels TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON public.water_vessels TO authenticated;
GRANT SELECT ON public.water_departures TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON public.water_departures TO authenticated;
GRANT SELECT ON public.water_fare_classes TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON public.water_fare_classes TO authenticated;
GRANT SELECT ON public.water_passenger_bookings TO authenticated;
GRANT SELECT ON public.water_booking_passengers TO authenticated;

REVOKE INSERT, UPDATE, DELETE ON public.water_passenger_bookings FROM anon, authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.water_booking_passengers FROM anon, authenticated;

CREATE POLICY water_routes_public_read
ON public.water_routes
FOR SELECT
TO anon
USING (
  status = 'active'
  AND EXISTS (
    SELECT 1
    FROM public.provider_services AS ps
    JOIN public.service_categories AS sc ON sc.id = ps.category_id
    JOIN public.provider_profiles AS pp ON pp.provider_id = ps.provider_id
    WHERE ps.id = water_routes.provider_service_id
      AND ps.provider_id = water_routes.provider_id
      AND ps.status = 'active'
      AND sc.slug = 'boat-ship-rides'
      AND sc.booking_mode = 'scheduled'
      AND pp.verification_status = 'verified'
      AND pp.is_active = true
  )
);

CREATE POLICY water_routes_authenticated_read
ON public.water_routes
FOR SELECT
TO authenticated
USING (
  provider_id = auth.uid()
  OR public.is_admin(auth.uid())
  OR public.has_role('operations', auth.uid())
  OR status = 'active'
);

CREATE POLICY water_routes_write_own
ON public.water_routes
FOR ALL
TO authenticated
USING (provider_id = auth.uid() OR public.is_admin(auth.uid()))
WITH CHECK (
  (provider_id = auth.uid() OR public.is_admin(auth.uid()))
  AND EXISTS (
    SELECT 1
    FROM public.provider_services AS ps
    JOIN public.service_categories AS sc ON sc.id = ps.category_id
    JOIN public.provider_profiles AS pp ON pp.provider_id = ps.provider_id
    WHERE ps.id = water_routes.provider_service_id
      AND ps.provider_id = water_routes.provider_id
      AND sc.slug = 'boat-ship-rides'
      AND sc.booking_mode = 'scheduled'
      AND pp.verification_status = 'verified'
      AND pp.is_active = true
  )
);

CREATE POLICY water_vessels_public_read
ON public.water_vessels
FOR SELECT
TO anon
USING (
  status = 'active'
  AND EXISTS (
    SELECT 1
    FROM public.provider_services AS ps
    JOIN public.service_categories AS sc ON sc.id = ps.category_id
    JOIN public.provider_profiles AS pp ON pp.provider_id = ps.provider_id
    WHERE ps.id = water_vessels.provider_service_id
      AND ps.provider_id = water_vessels.provider_id
      AND ps.status = 'active'
      AND sc.slug = 'boat-ship-rides'
      AND pp.verification_status = 'verified'
      AND pp.is_active = true
  )
);

CREATE POLICY water_vessels_authenticated_read
ON public.water_vessels
FOR SELECT
TO authenticated
USING (
  provider_id = auth.uid()
  OR public.is_admin(auth.uid())
  OR public.has_role('operations', auth.uid())
  OR status = 'active'
);

CREATE POLICY water_vessels_write_own
ON public.water_vessels
FOR ALL
TO authenticated
USING (provider_id = auth.uid() OR public.is_admin(auth.uid()))
WITH CHECK (
  (provider_id = auth.uid() OR public.is_admin(auth.uid()))
  AND EXISTS (
    SELECT 1
    FROM public.provider_services AS ps
    JOIN public.service_categories AS sc ON sc.id = ps.category_id
    JOIN public.provider_profiles AS pp ON pp.provider_id = ps.provider_id
    WHERE ps.id = water_vessels.provider_service_id
      AND ps.provider_id = water_vessels.provider_id
      AND sc.slug = 'boat-ship-rides'
      AND pp.verification_status = 'verified'
      AND pp.is_active = true
  )
);

CREATE POLICY water_departures_public_read
ON public.water_departures
FOR SELECT
TO anon
USING (
  status IN ('scheduled', 'boarding')
  AND departs_at > now()
  AND EXISTS (
    SELECT 1
    FROM public.water_routes AS wr
    WHERE wr.id = water_departures.route_id
      AND wr.status = 'active'
  )
);

CREATE POLICY water_departures_authenticated_read
ON public.water_departures
FOR SELECT
TO authenticated
USING (
  provider_id = auth.uid()
  OR public.is_admin(auth.uid())
  OR public.has_role('operations', auth.uid())
  OR (
    status IN ('scheduled', 'boarding')
    AND departs_at > now()
  )
);

CREATE POLICY water_departures_write_own
ON public.water_departures
FOR ALL
TO authenticated
USING (provider_id = auth.uid() OR public.is_admin(auth.uid()))
WITH CHECK (
  (provider_id = auth.uid() OR public.is_admin(auth.uid()))
  AND EXISTS (
    SELECT 1 FROM public.water_routes AS wr
    WHERE wr.id = water_departures.route_id
      AND wr.provider_id = water_departures.provider_id
  )
  AND EXISTS (
    SELECT 1 FROM public.water_vessels AS wv
    WHERE wv.id = water_departures.vessel_id
      AND wv.provider_id = water_departures.provider_id
  )
);

CREATE POLICY water_fare_classes_public_read
ON public.water_fare_classes
FOR SELECT
TO anon
USING (
  is_active = true
  AND EXISTS (
    SELECT 1 FROM public.water_departures AS wd
    WHERE wd.id = water_fare_classes.departure_id
      AND wd.status IN ('scheduled', 'boarding')
      AND wd.departs_at > now()
  )
);

CREATE POLICY water_fare_classes_authenticated_read
ON public.water_fare_classes
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.water_departures AS wd
    WHERE wd.id = water_fare_classes.departure_id
      AND (
        wd.provider_id = auth.uid()
        OR public.is_admin(auth.uid())
        OR public.has_role('operations', auth.uid())
        OR (
          water_fare_classes.is_active = true
          AND wd.status IN ('scheduled', 'boarding')
          AND wd.departs_at > now()
        )
      )
  )
);

CREATE POLICY water_fare_classes_write_own
ON public.water_fare_classes
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.water_departures AS wd
    WHERE wd.id = water_fare_classes.departure_id
      AND (wd.provider_id = auth.uid() OR public.is_admin(auth.uid()))
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.water_departures AS wd
    WHERE wd.id = water_fare_classes.departure_id
      AND (wd.provider_id = auth.uid() OR public.is_admin(auth.uid()))
  )
);

CREATE POLICY water_bookings_participant_read
ON public.water_passenger_bookings
FOR SELECT
TO authenticated
USING (
  customer_id = auth.uid()
  OR provider_id = auth.uid()
  OR public.is_admin(auth.uid())
  OR public.has_role('operations', auth.uid())
  OR public.has_role('support', auth.uid())
  OR public.has_role('finance', auth.uid())
);

CREATE POLICY water_booking_passengers_participant_read
ON public.water_booking_passengers
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.water_passenger_bookings AS wb
    WHERE wb.id = water_booking_passengers.booking_id
      AND (
        wb.customer_id = auth.uid()
        OR wb.provider_id = auth.uid()
        OR public.is_admin(auth.uid())
        OR public.has_role('operations', auth.uid())
        OR public.has_role('support', auth.uid())
      )
  )
);

CREATE OR REPLACE FUNCTION public.book_water_departure(
  p_departure_id uuid,
  p_fare_class_id uuid,
  p_passengers jsonb,
  p_contact_phone text DEFAULT NULL,
  p_note text DEFAULT NULL
)
RETURNS public.water_passenger_bookings
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_departure public.water_departures%ROWTYPE;
  v_vessel public.water_vessels%ROWTYPE;
  v_fare public.water_fare_classes%ROWTYPE;
  v_passenger jsonb;
  v_count integer;
  v_departure_reserved integer;
  v_class_reserved integer;
  v_booking public.water_passenger_bookings%ROWTYPE;
  v_name text;
  v_type text;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF jsonb_typeof(p_passengers) <> 'array' THEN
    RAISE EXCEPTION 'Passengers must be an array';
  END IF;

  v_count := jsonb_array_length(p_passengers);
  IF v_count < 1 OR v_count > 20 THEN
    RAISE EXCEPTION 'Passenger count must be between 1 and 20';
  END IF;

  SELECT *
  INTO v_departure
  FROM public.water_departures
  WHERE id = p_departure_id
  FOR UPDATE;

  IF NOT FOUND
     OR v_departure.status <> 'scheduled'
     OR v_departure.booking_open = false
     OR v_departure.departs_at <= now() THEN
    RAISE EXCEPTION 'Departure is not open for booking';
  END IF;

  SELECT *
  INTO v_vessel
  FROM public.water_vessels
  WHERE id = v_departure.vessel_id
    AND provider_id = v_departure.provider_id
    AND status = 'active';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Vessel is not available';
  END IF;

  SELECT *
  INTO v_fare
  FROM public.water_fare_classes
  WHERE id = p_fare_class_id
    AND departure_id = v_departure.id
    AND is_active = true
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Fare class is not available';
  END IF;

  SELECT COALESCE(sum(passenger_count), 0)::integer
  INTO v_departure_reserved
  FROM public.water_passenger_bookings
  WHERE departure_id = v_departure.id
    AND status IN ('booked', 'boarded');

  IF v_departure_reserved + v_count > v_vessel.total_capacity THEN
    RAISE EXCEPTION 'Vessel capacity exceeded';
  END IF;

  SELECT COALESCE(sum(passenger_count), 0)::integer
  INTO v_class_reserved
  FROM public.water_passenger_bookings
  WHERE fare_class_id = v_fare.id
    AND status IN ('booked', 'boarded');

  IF v_class_reserved + v_count > v_fare.capacity THEN
    RAISE EXCEPTION 'Fare class capacity exceeded';
  END IF;

  FOR v_passenger IN SELECT value FROM jsonb_array_elements(p_passengers)
  LOOP
    v_name := NULLIF(trim(v_passenger ->> 'full_name'), '');
    v_type := lower(trim(COALESCE(v_passenger ->> 'passenger_type', 'adult')));

    IF v_name IS NULL OR char_length(v_name) < 2 THEN
      RAISE EXCEPTION 'Every passenger requires a full name';
    END IF;

    IF v_type NOT IN ('adult', 'child', 'infant') THEN
      RAISE EXCEPTION 'Invalid passenger type';
    END IF;
  END LOOP;

  INSERT INTO public.water_passenger_bookings (
    departure_id,
    fare_class_id,
    customer_id,
    provider_id,
    passenger_count,
    unit_fare,
    total_amount,
    currency,
    status,
    payment_status,
    contact_phone,
    note
  )
  VALUES (
    v_departure.id,
    v_fare.id,
    v_user_id,
    v_departure.provider_id,
    v_count,
    v_fare.price,
    round(v_fare.price * v_count, 2),
    v_fare.currency,
    'booked',
    CASE WHEN v_fare.price = 0 THEN 'not_required' ELSE 'unpaid' END,
    NULLIF(trim(p_contact_phone), ''),
    NULLIF(trim(p_note), '')
  )
  RETURNING * INTO v_booking;

  FOR v_passenger IN SELECT value FROM jsonb_array_elements(p_passengers)
  LOOP
    INSERT INTO public.water_booking_passengers (
      booking_id,
      full_name,
      phone,
      passenger_type,
      document_reference
    )
    VALUES (
      v_booking.id,
      trim(v_passenger ->> 'full_name'),
      NULLIF(trim(v_passenger ->> 'phone'), ''),
      lower(trim(COALESCE(v_passenger ->> 'passenger_type', 'adult'))),
      NULLIF(trim(v_passenger ->> 'document_reference'), '')
    );
  END LOOP;

  RETURN v_booking;
END;
$$;

REVOKE ALL ON FUNCTION public.book_water_departure(
  uuid, uuid, jsonb, text, text
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.book_water_departure(
  uuid, uuid, jsonb, text, text
) TO authenticated;

CREATE OR REPLACE FUNCTION public.cancel_water_booking(
  p_booking_id uuid,
  p_reason text DEFAULT NULL
)
RETURNS public.water_passenger_bookings
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_booking public.water_passenger_bookings%ROWTYPE;
  v_departure public.water_departures%ROWTYPE;
BEGIN
  SELECT *
  INTO v_booking
  FROM public.water_passenger_bookings
  WHERE id = p_booking_id
    AND customer_id = auth.uid()
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Water passenger booking not found';
  END IF;

  SELECT * INTO v_departure
  FROM public.water_departures
  WHERE id = v_booking.departure_id;

  IF v_booking.status <> 'booked' THEN
    RAISE EXCEPTION 'Booking can no longer be cancelled';
  END IF;

  IF v_departure.status <> 'scheduled' OR v_departure.departs_at <= now() THEN
    RAISE EXCEPTION 'Departure is no longer cancellable';
  END IF;

  UPDATE public.water_passenger_bookings
  SET status = 'cancelled',
      cancelled_at = now(),
      metadata = metadata || jsonb_build_object(
        'cancellation_reason',
        NULLIF(trim(p_reason), '')
      )
  WHERE id = p_booking_id
  RETURNING * INTO v_booking;

  RETURN v_booking;
END;
$$;

REVOKE ALL ON FUNCTION public.cancel_water_booking(uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.cancel_water_booking(uuid, text) TO authenticated;

CREATE OR REPLACE FUNCTION public.vendor_set_water_departure_status(
  p_departure_id uuid,
  p_status text
)
RETURNS public.water_departures
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_target text := lower(trim(COALESCE(p_status, '')));
  v_departure public.water_departures%ROWTYPE;
BEGIN
  SELECT *
  INTO v_departure
  FROM public.water_departures
  WHERE id = p_departure_id
    AND (
      provider_id = auth.uid()
      OR public.is_admin(auth.uid())
      OR public.has_role('operations', auth.uid())
    )
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Water departure not found';
  END IF;

  IF NOT (
    (v_departure.status = 'scheduled' AND v_target IN ('boarding', 'cancelled'))
    OR (v_departure.status = 'boarding' AND v_target IN ('departed', 'cancelled'))
    OR (v_departure.status = 'departed' AND v_target = 'arrived')
  ) THEN
    RAISE EXCEPTION 'Invalid water departure status transition';
  END IF;

  UPDATE public.water_departures
  SET status = v_target,
      booking_open = CASE
        WHEN v_target IN ('boarding', 'departed', 'arrived', 'cancelled') THEN false
        ELSE booking_open
      END
  WHERE id = p_departure_id
  RETURNING * INTO v_departure;

  IF v_target = 'arrived' THEN
    UPDATE public.water_passenger_bookings
    SET status = CASE
          WHEN status = 'boarded' THEN 'completed'
          WHEN status = 'booked' THEN 'no_show'
          ELSE status
        END,
        completed_at = CASE WHEN status = 'boarded' THEN now() ELSE completed_at END,
        no_show_at = CASE WHEN status = 'booked' THEN now() ELSE no_show_at END
    WHERE departure_id = p_departure_id
      AND status IN ('booked', 'boarded');
  ELSIF v_target = 'cancelled' THEN
    UPDATE public.water_passenger_bookings
    SET status = 'cancelled',
        cancelled_at = now(),
        metadata = metadata || jsonb_build_object(
          'cancellation_reason',
          'Departure cancelled by operator'
        )
    WHERE departure_id = p_departure_id
      AND status = 'booked';
  END IF;

  RETURN v_departure;
END;
$$;

REVOKE ALL ON FUNCTION public.vendor_set_water_departure_status(uuid, text)
FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.vendor_set_water_departure_status(uuid, text)
TO authenticated;

CREATE OR REPLACE FUNCTION public.vendor_set_water_booking_status(
  p_booking_id uuid,
  p_status text
)
RETURNS public.water_passenger_bookings
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_target text := lower(trim(COALESCE(p_status, '')));
  v_booking public.water_passenger_bookings%ROWTYPE;
  v_departure public.water_departures%ROWTYPE;
BEGIN
  SELECT wb.*
  INTO v_booking
  FROM public.water_passenger_bookings AS wb
  JOIN public.water_departures AS wd ON wd.id = wb.departure_id
  WHERE wb.id = p_booking_id
    AND (
      wd.provider_id = auth.uid()
      OR public.is_admin(auth.uid())
      OR public.has_role('operations', auth.uid())
    )
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Water passenger booking not found';
  END IF;

  SELECT * INTO v_departure
  FROM public.water_departures
  WHERE id = v_booking.departure_id;

  IF v_booking.status <> 'booked'
     OR v_target NOT IN ('boarded', 'no_show') THEN
    RAISE EXCEPTION 'Invalid water booking status transition';
  END IF;

  IF v_target = 'boarded'
     AND v_departure.status NOT IN ('boarding', 'departed') THEN
    RAISE EXCEPTION 'Departure is not boarding';
  END IF;

  UPDATE public.water_passenger_bookings
  SET status = v_target,
      boarded_at = CASE WHEN v_target = 'boarded' THEN now() ELSE boarded_at END,
      no_show_at = CASE WHEN v_target = 'no_show' THEN now() ELSE no_show_at END
  WHERE id = p_booking_id
  RETURNING * INTO v_booking;

  RETURN v_booking;
END;
$$;

REVOKE ALL ON FUNCTION public.vendor_set_water_booking_status(uuid, text)
FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.vendor_set_water_booking_status(uuid, text)
TO authenticated;

ALTER TABLE public.water_departures REPLICA IDENTITY FULL;
ALTER TABLE public.water_passenger_bookings REPLICA IDENTITY FULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'water_departures'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.water_departures;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'water_passenger_bookings'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.water_passenger_bookings;
  END IF;
END;
$$;
