-- Wantok Service baseline schema
-- Reconstructed from the application contract and hardened for local/hosted Supabase.

CREATE TABLE public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name text,
  phone text,
  is_provider boolean NOT NULL DEFAULT false,
  is_driver boolean NOT NULL DEFAULT false,
  is_driver_approved boolean NOT NULL DEFAULT false,
  is_admin boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.provider_applications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  service_type text NOT NULL CHECK (length(trim(service_type)) > 0),
  company_name text,
  vehicle_plate text,
  vehicle_make text,
  vehicle_model text,
  vehicle_color text,
  id_photo_url text,
  license_photo_url text,
  notes text,
  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'approved', 'rejected')),
  reviewed_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  reviewed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.driver_profiles (
  driver_id uuid PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  vehicle_rego text,
  vehicle_make text,
  vehicle_model text,
  vehicle_colour text,
  vehicle_image_url text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.driver_locations (
  driver_id uuid PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  lat double precision NOT NULL CHECK (lat BETWEEN -90 AND 90),
  lng double precision NOT NULL CHECK (lng BETWEEN -180 AND 180),
  heading double precision,
  is_online boolean NOT NULL DEFAULT false,
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.rides (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  passenger_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  driver_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  pickup_lat double precision NOT NULL CHECK (pickup_lat BETWEEN -90 AND 90),
  pickup_lng double precision NOT NULL CHECK (pickup_lng BETWEEN -180 AND 180),
  dropoff_lat double precision NOT NULL CHECK (dropoff_lat BETWEEN -90 AND 90),
  dropoff_lng double precision NOT NULL CHECK (dropoff_lng BETWEEN -180 AND 180),
  status text NOT NULL DEFAULT 'driver_assigned'
    CHECK (status IN (
      'pending',
      'driver_assigned',
      'accepted',
      'arriving',
      'arrived',
      'in_progress',
      'completed',
      'cancelled'
    )),
  fare_estimate numeric(10,2),
  distance_km numeric(10,3),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX provider_applications_user_created_idx
  ON public.provider_applications (user_id, created_at DESC);
CREATE INDEX provider_applications_status_created_idx
  ON public.provider_applications (status, created_at);
CREATE INDEX driver_locations_online_idx
  ON public.driver_locations (is_online) WHERE is_online = true;
CREATE INDEX rides_passenger_created_idx
  ON public.rides (passenger_id, created_at DESC);
CREATE INDEX rides_driver_status_idx
  ON public.rides (driver_id, status);

ALTER TABLE public.driver_locations REPLICA IDENTITY FULL;
ALTER TABLE public.rides REPLICA IDENTITY FULL;

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER profiles_set_updated_at
BEFORE UPDATE ON public.profiles
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER provider_applications_set_updated_at
BEFORE UPDATE ON public.provider_applications
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER driver_profiles_set_updated_at
BEFORE UPDATE ON public.driver_profiles
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER rides_set_updated_at
BEFORE UPDATE ON public.rides
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, phone)
  VALUES (
    NEW.id,
    COALESCE(NULLIF(NEW.raw_user_meta_data ->> 'full_name', ''), NEW.email),
    NEW.phone
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

CREATE OR REPLACE FUNCTION public.is_admin(p_user_id uuid DEFAULT auth.uid())
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = p_user_id
      AND is_admin = true
  );
$$;

REVOKE ALL ON FUNCTION public.is_admin(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_admin(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.haversine_km(
  p_lat1 double precision,
  p_lng1 double precision,
  p_lat2 double precision,
  p_lng2 double precision
)
RETURNS double precision
LANGUAGE sql
IMMUTABLE
STRICT
AS $$
  SELECT 6371.0 * 2.0 * asin(
    sqrt(
      power(sin(radians(p_lat2 - p_lat1) / 2.0), 2) +
      cos(radians(p_lat1)) *
      cos(radians(p_lat2)) *
      power(sin(radians(p_lng2 - p_lng1) / 2.0), 2)
    )
  );
$$;

REVOKE ALL ON FUNCTION public.haversine_km(
  double precision,
  double precision,
  double precision,
  double precision
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.haversine_km(
  double precision,
  double precision,
  double precision,
  double precision
) TO authenticated;

CREATE OR REPLACE FUNCTION public.list_available_drivers()
RETURNS TABLE (
  driver_id uuid,
  name text,
  vehicle_rego text,
  vehicle_model text,
  vehicle_colour text,
  vehicle_image_url text,
  lat double precision,
  lng double precision
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT
    dl.driver_id,
    p.full_name AS name,
    dp.vehicle_rego,
    dp.vehicle_model,
    dp.vehicle_colour,
    dp.vehicle_image_url,
    dl.lat,
    dl.lng
  FROM public.driver_locations AS dl
  JOIN public.profiles AS p
    ON p.id = dl.driver_id
  LEFT JOIN public.driver_profiles AS dp
    ON dp.driver_id = dl.driver_id
  WHERE auth.uid() IS NOT NULL
    AND dl.is_online = true
    AND p.is_driver = true
    AND p.is_driver_approved = true
    AND NOT EXISTS (
      SELECT 1
      FROM public.rides AS r
      WHERE r.driver_id = dl.driver_id
        AND r.status NOT IN ('completed', 'cancelled')
    );
$$;

REVOKE ALL ON FUNCTION public.list_available_drivers() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.list_available_drivers() TO authenticated;

CREATE OR REPLACE FUNCTION public.request_ride(
  p_pickup_lat double precision,
  p_pickup_lng double precision,
  p_dropoff_lat double precision,
  p_dropoff_lng double precision
)
RETURNS TABLE (
  ride_id uuid,
  driver_id uuid,
  driver_name text,
  driver_phone text,
  vehicle_rego text,
  vehicle_model text,
  vehicle_colour text,
  vehicle_image_url text,
  driver_distance_km double precision,
  trip_distance_km double precision,
  fare_estimate numeric
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_driver_id uuid;
  v_driver_name text;
  v_driver_phone text;
  v_vehicle_rego text;
  v_vehicle_model text;
  v_vehicle_colour text;
  v_vehicle_image_url text;
  v_driver_distance double precision;
  v_trip_distance double precision;
  v_fare numeric(10,2);
  v_ride_id uuid;
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

  IF EXISTS (
    SELECT 1
    FROM public.rides AS r
    WHERE r.passenger_id = v_user_id
      AND r.status NOT IN ('completed', 'cancelled')
  ) THEN
    RAISE EXCEPTION 'Passenger already has an active ride';
  END IF;

  SELECT
    dl.driver_id,
    p.full_name,
    p.phone,
    dp.vehicle_rego,
    dp.vehicle_model,
    dp.vehicle_colour,
    dp.vehicle_image_url,
    public.haversine_km(p_pickup_lat, p_pickup_lng, dl.lat, dl.lng)
  INTO
    v_driver_id,
    v_driver_name,
    v_driver_phone,
    v_vehicle_rego,
    v_vehicle_model,
    v_vehicle_colour,
    v_vehicle_image_url,
    v_driver_distance
  FROM public.driver_locations AS dl
  JOIN public.profiles AS p
    ON p.id = dl.driver_id
  LEFT JOIN public.driver_profiles AS dp
    ON dp.driver_id = dl.driver_id
  WHERE dl.is_online = true
    AND p.is_driver = true
    AND p.is_driver_approved = true
    AND NOT EXISTS (
      SELECT 1
      FROM public.rides AS r
      WHERE r.driver_id = dl.driver_id
        AND r.status NOT IN ('completed', 'cancelled')
    )
  ORDER BY public.haversine_km(
    p_pickup_lat,
    p_pickup_lng,
    dl.lat,
    dl.lng
  )
  FOR UPDATE OF dl SKIP LOCKED
  LIMIT 1;

  IF v_driver_id IS NULL THEN
    RAISE EXCEPTION 'No approved drivers are currently available';
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
    status,
    fare_estimate,
    distance_km
  )
  VALUES (
    v_user_id,
    v_driver_id,
    p_pickup_lat,
    p_pickup_lng,
    p_dropoff_lat,
    p_dropoff_lng,
    'driver_assigned',
    v_fare,
    v_trip_distance
  )
  RETURNING id INTO v_ride_id;

  RETURN QUERY
  SELECT
    v_ride_id,
    v_driver_id,
    v_driver_name,
    v_driver_phone,
    v_vehicle_rego,
    v_vehicle_model,
    v_vehicle_colour,
    v_vehicle_image_url,
    v_driver_distance,
    v_trip_distance,
    v_fare;
END;
$$;

REVOKE ALL ON FUNCTION public.request_ride(
  double precision,
  double precision,
  double precision,
  double precision
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.request_ride(
  double precision,
  double precision,
  double precision,
  double precision
) TO authenticated;

CREATE OR REPLACE FUNCTION public.review_provider_application(
  p_application_id uuid,
  p_decision text
)
RETURNS public.provider_applications
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_application public.provider_applications%ROWTYPE;
  v_decision text := lower(trim(p_decision));
BEGIN
  IF auth.uid() IS NULL OR NOT public.is_admin(auth.uid()) THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  IF v_decision NOT IN ('approved', 'rejected') THEN
    RAISE EXCEPTION 'Decision must be approved or rejected';
  END IF;

  SELECT *
  INTO v_application
  FROM public.provider_applications
  WHERE id = p_application_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Provider application not found';
  END IF;

  IF v_application.status <> 'pending' THEN
    RAISE EXCEPTION 'Provider application has already been reviewed';
  END IF;

  UPDATE public.provider_applications
  SET
    status = v_decision,
    reviewed_by = auth.uid(),
    reviewed_at = now()
  WHERE id = p_application_id
  RETURNING * INTO v_application;

  IF v_decision = 'approved' THEN
    UPDATE public.profiles AS p
    SET
      is_provider = true,
      is_driver = CASE
        WHEN lower(v_application.service_type) = 'driver' THEN true
        ELSE p.is_driver
      END,
      is_driver_approved = CASE
        WHEN lower(v_application.service_type) = 'driver' THEN true
        ELSE p.is_driver_approved
      END
    WHERE p.id = v_application.user_id;

    IF lower(v_application.service_type) = 'driver' THEN
      INSERT INTO public.driver_profiles (
        driver_id,
        vehicle_rego,
        vehicle_make,
        vehicle_model,
        vehicle_colour
      )
      VALUES (
        v_application.user_id,
        v_application.vehicle_plate,
        v_application.vehicle_make,
        v_application.vehicle_model,
        v_application.vehicle_color
      )
      ON CONFLICT (driver_id) DO UPDATE
      SET
        vehicle_rego = EXCLUDED.vehicle_rego,
        vehicle_make = EXCLUDED.vehicle_make,
        vehicle_model = EXCLUDED.vehicle_model,
        vehicle_colour = EXCLUDED.vehicle_colour,
        updated_at = now();
    END IF;
  END IF;

  RETURN v_application;
END;
$$;

REVOKE ALL ON FUNCTION public.review_provider_application(uuid, text)
  FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.review_provider_application(uuid, text)
  TO authenticated;

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provider_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.driver_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.driver_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rides ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.profiles FROM anon, authenticated;
REVOKE ALL ON TABLE public.provider_applications FROM anon, authenticated;
REVOKE ALL ON TABLE public.driver_profiles FROM anon, authenticated;
REVOKE ALL ON TABLE public.driver_locations FROM anon, authenticated;
REVOKE ALL ON TABLE public.rides FROM anon, authenticated;

GRANT SELECT ON TABLE public.profiles TO authenticated;
GRANT INSERT (id, full_name, phone)
  ON TABLE public.profiles TO authenticated;
GRANT UPDATE (full_name, phone)
  ON TABLE public.profiles TO authenticated;

GRANT SELECT ON TABLE public.provider_applications TO authenticated;
GRANT INSERT (
  user_id,
  service_type,
  company_name,
  vehicle_plate,
  vehicle_make,
  vehicle_model,
  vehicle_color,
  id_photo_url,
  license_photo_url,
  notes
) ON TABLE public.provider_applications TO authenticated;

GRANT SELECT ON TABLE public.driver_profiles TO authenticated;
GRANT UPDATE (
  vehicle_rego,
  vehicle_make,
  vehicle_model,
  vehicle_colour,
  vehicle_image_url
) ON TABLE public.driver_profiles TO authenticated;

GRANT SELECT, INSERT ON TABLE public.driver_locations TO authenticated;
GRANT UPDATE (lat, lng, heading, is_online, updated_at)
  ON TABLE public.driver_locations TO authenticated;

GRANT SELECT ON TABLE public.rides TO authenticated;
GRANT UPDATE (status) ON TABLE public.rides TO authenticated;

CREATE POLICY profiles_select_own_or_admin
ON public.profiles
FOR SELECT
TO authenticated
USING (
  id = auth.uid()
  OR public.is_admin(auth.uid())
);

CREATE POLICY profiles_insert_own
ON public.profiles
FOR INSERT
TO authenticated
WITH CHECK (id = auth.uid());

CREATE POLICY profiles_update_own
ON public.profiles
FOR UPDATE
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

CREATE POLICY provider_applications_select_own_or_admin
ON public.provider_applications
FOR SELECT
TO authenticated
USING (
  user_id = auth.uid()
  OR public.is_admin(auth.uid())
);

CREATE POLICY provider_applications_insert_own
ON public.provider_applications
FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

CREATE POLICY driver_profiles_select_own_or_admin
ON public.driver_profiles
FOR SELECT
TO authenticated
USING (
  driver_id = auth.uid()
  OR public.is_admin(auth.uid())
);

CREATE POLICY driver_profiles_update_own_approved
ON public.driver_profiles
FOR UPDATE
TO authenticated
USING (
  driver_id = auth.uid()
  AND EXISTS (
    SELECT 1
    FROM public.profiles AS p
    WHERE p.id = auth.uid()
      AND p.is_driver = true
      AND p.is_driver_approved = true
  )
)
WITH CHECK (
  driver_id = auth.uid()
  AND EXISTS (
    SELECT 1
    FROM public.profiles AS p
    WHERE p.id = auth.uid()
      AND p.is_driver = true
      AND p.is_driver_approved = true
  )
);

CREATE POLICY driver_locations_select_available
ON public.driver_locations
FOR SELECT
TO authenticated
USING (
  driver_id = auth.uid()
  OR public.is_admin(auth.uid())
  OR (
    is_online = true
    AND EXISTS (
      SELECT 1
      FROM public.profiles AS p
      WHERE p.id = driver_id
        AND p.is_driver = true
        AND p.is_driver_approved = true
    )
  )
);

CREATE POLICY driver_locations_insert_own_approved
ON public.driver_locations
FOR INSERT
TO authenticated
WITH CHECK (
  driver_id = auth.uid()
  AND EXISTS (
    SELECT 1
    FROM public.profiles AS p
    WHERE p.id = auth.uid()
      AND p.is_driver = true
      AND p.is_driver_approved = true
  )
);

CREATE POLICY driver_locations_update_own_approved
ON public.driver_locations
FOR UPDATE
TO authenticated
USING (
  driver_id = auth.uid()
  AND EXISTS (
    SELECT 1
    FROM public.profiles AS p
    WHERE p.id = auth.uid()
      AND p.is_driver = true
      AND p.is_driver_approved = true
  )
)
WITH CHECK (
  driver_id = auth.uid()
  AND EXISTS (
    SELECT 1
    FROM public.profiles AS p
    WHERE p.id = auth.uid()
      AND p.is_driver = true
      AND p.is_driver_approved = true
  )
);

CREATE POLICY rides_select_participants_or_admin
ON public.rides
FOR SELECT
TO authenticated
USING (
  passenger_id = auth.uid()
  OR driver_id = auth.uid()
  OR public.is_admin(auth.uid())
);

CREATE POLICY rides_update_passenger_cancel
ON public.rides
FOR UPDATE
TO authenticated
USING (passenger_id = auth.uid())
WITH CHECK (
  passenger_id = auth.uid()
  AND status = 'cancelled'
);

CREATE POLICY rides_update_driver_status
ON public.rides
FOR UPDATE
TO authenticated
USING (driver_id = auth.uid())
WITH CHECK (
  driver_id = auth.uid()
  AND status IN (
    'accepted',
    'arriving',
    'arrived',
    'in_progress',
    'completed',
    'cancelled'
  )
);

CREATE POLICY rides_update_admin
ON public.rides
FOR UPDATE
TO authenticated
USING (public.is_admin(auth.uid()))
WITH CHECK (public.is_admin(auth.uid()));

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'driver_locations'
  ) THEN
    ALTER PUBLICATION supabase_realtime
      ADD TABLE public.driver_locations;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'rides'
  ) THEN
    ALTER PUBLICATION supabase_realtime
      ADD TABLE public.rides;
  END IF;
END;
$$;

INSERT INTO storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
VALUES (
  'provider-documents',
  'provider-documents',
  false,
  10485760,
  ARRAY['image/jpeg', 'image/png', 'application/pdf']::text[]
)
ON CONFLICT (id) DO UPDATE
SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

CREATE POLICY provider_documents_select
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'provider-documents'
  AND (
    (storage.foldername(name))[1] = auth.uid()::text
    OR public.is_admin(auth.uid())
  )
);

CREATE POLICY provider_documents_insert
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'provider-documents'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

CREATE POLICY provider_documents_update
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'provider-documents'
  AND (storage.foldername(name))[1] = auth.uid()::text
)
WITH CHECK (
  bucket_id = 'provider-documents'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

CREATE POLICY provider_documents_delete
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'provider-documents'
  AND (storage.foldername(name))[1] = auth.uid()::text
);
