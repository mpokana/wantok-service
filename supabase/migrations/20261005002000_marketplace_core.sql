-- Wantok Service shared marketplace core
-- Adds reusable service/provider/booking primitives beside specialised modules such as rides.

CREATE TABLE public.service_categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  parent_id uuid REFERENCES public.service_categories(id) ON DELETE SET NULL,
  slug text NOT NULL UNIQUE CHECK (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  name text NOT NULL,
  description text,
  vertical text NOT NULL CHECK (vertical IN (
    'mobility', 'delivery', 'hire', 'people', 'places', 'events',
    'food', 'shopping', 'travel', 'other'
  )),
  booking_mode text NOT NULL CHECK (booking_mode IN (
    'on_demand', 'scheduled', 'quote', 'reservation', 'commerce', 'ticketing', 'information'
  )),
  icon_key text,
  is_active boolean NOT NULL DEFAULT true,
  sort_order integer NOT NULL DEFAULT 0,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.provider_profiles (
  provider_id uuid PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  display_name text NOT NULL,
  provider_type text NOT NULL DEFAULT 'individual'
    CHECK (provider_type IN ('individual', 'business', 'organisation')),
  bio text,
  verification_status text NOT NULL DEFAULT 'pending'
    CHECK (verification_status IN ('pending', 'verified', 'rejected', 'suspended')),
  is_active boolean NOT NULL DEFAULT false,
  rating_average numeric(3,2) NOT NULL DEFAULT 0 CHECK (rating_average BETWEEN 0 AND 5),
  rating_count integer NOT NULL DEFAULT 0 CHECK (rating_count >= 0),
  base_address text,
  base_lat double precision CHECK (base_lat IS NULL OR base_lat BETWEEN -90 AND 90),
  base_lng double precision CHECK (base_lng IS NULL OR base_lng BETWEEN -180 AND 180),
  service_radius_km numeric(8,2) CHECK (service_radius_km IS NULL OR service_radius_km >= 0),
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.provider_services (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id uuid NOT NULL REFERENCES public.provider_profiles(provider_id) ON DELETE CASCADE,
  category_id uuid NOT NULL REFERENCES public.service_categories(id) ON DELETE RESTRICT,
  title text NOT NULL,
  description text,
  pricing_model text NOT NULL DEFAULT 'quote'
    CHECK (pricing_model IN ('fixed', 'hourly', 'daily', 'per_job', 'per_km', 'per_person', 'quote', 'free')),
  base_price numeric(12,2) CHECK (base_price IS NULL OR base_price >= 0),
  minimum_charge numeric(12,2) CHECK (minimum_charge IS NULL OR minimum_charge >= 0),
  currency text NOT NULL DEFAULT 'PGK' CHECK (char_length(currency) = 3),
  unit_label text,
  service_address text,
  lat double precision CHECK (lat IS NULL OR lat BETWEEN -90 AND 90),
  lng double precision CHECK (lng IS NULL OR lng BETWEEN -180 AND 180),
  service_radius_km numeric(8,2) CHECK (service_radius_km IS NULL OR service_radius_km >= 0),
  booking_notice_minutes integer NOT NULL DEFAULT 0 CHECK (booking_notice_minutes >= 0),
  status text NOT NULL DEFAULT 'draft'
    CHECK (status IN ('draft', 'pending_review', 'active', 'paused', 'rejected')),
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.provider_resources (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id uuid NOT NULL REFERENCES public.provider_profiles(provider_id) ON DELETE CASCADE,
  category_id uuid NOT NULL REFERENCES public.service_categories(id) ON DELETE RESTRICT,
  resource_type text NOT NULL,
  name text NOT NULL,
  description text,
  capacity integer CHECK (capacity IS NULL OR capacity >= 0),
  address_text text,
  lat double precision CHECK (lat IS NULL OR lat BETWEEN -90 AND 90),
  lng double precision CHECK (lng IS NULL OR lng BETWEEN -180 AND 180),
  status text NOT NULL DEFAULT 'draft'
    CHECK (status IN ('draft', 'pending_review', 'active', 'paused', 'rejected', 'unavailable')),
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.service_bookings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  category_id uuid NOT NULL REFERENCES public.service_categories(id) ON DELETE RESTRICT,
  provider_id uuid REFERENCES public.provider_profiles(provider_id) ON DELETE SET NULL,
  provider_service_id uuid REFERENCES public.provider_services(id) ON DELETE SET NULL,
  resource_id uuid REFERENCES public.provider_resources(id) ON DELETE SET NULL,
  status text NOT NULL DEFAULT 'requested'
    CHECK (status IN (
      'requested', 'quoted', 'accepted', 'confirmed', 'in_progress',
      'completed', 'cancelled', 'rejected', 'expired'
    )),
  scheduled_start timestamptz,
  scheduled_end timestamptz,
  quantity numeric(12,2) NOT NULL DEFAULT 1 CHECK (quantity > 0),
  service_address text,
  origin_address text,
  origin_lat double precision CHECK (origin_lat IS NULL OR origin_lat BETWEEN -90 AND 90),
  origin_lng double precision CHECK (origin_lng IS NULL OR origin_lng BETWEEN -180 AND 180),
  destination_address text,
  destination_lat double precision CHECK (destination_lat IS NULL OR destination_lat BETWEEN -90 AND 90),
  destination_lng double precision CHECK (destination_lng IS NULL OR destination_lng BETWEEN -180 AND 180),
  notes text,
  requested_amount numeric(12,2) CHECK (requested_amount IS NULL OR requested_amount >= 0),
  quoted_amount numeric(12,2) CHECK (quoted_amount IS NULL OR quoted_amount >= 0),
  final_amount numeric(12,2) CHECK (final_amount IS NULL OR final_amount >= 0),
  currency text NOT NULL DEFAULT 'PGK' CHECK (char_length(currency) = 3),
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  completed_at timestamptz,
  cancelled_at timestamptz,
  CHECK (scheduled_end IS NULL OR scheduled_start IS NULL OR scheduled_end > scheduled_start)
);

CREATE TABLE public.service_quotes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id uuid NOT NULL REFERENCES public.service_bookings(id) ON DELETE CASCADE,
  provider_id uuid NOT NULL REFERENCES public.provider_profiles(provider_id) ON DELETE CASCADE,
  amount numeric(12,2) NOT NULL CHECK (amount >= 0),
  currency text NOT NULL DEFAULT 'PGK' CHECK (char_length(currency) = 3),
  message text,
  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'accepted', 'rejected', 'withdrawn', 'expired')),
  expires_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (booking_id, provider_id)
);

CREATE TABLE public.service_reviews (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id uuid NOT NULL UNIQUE REFERENCES public.service_bookings(id) ON DELETE CASCADE,
  reviewer_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  provider_id uuid NOT NULL REFERENCES public.provider_profiles(provider_id) ON DELETE CASCADE,
  rating integer NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX service_categories_vertical_active_idx
  ON public.service_categories (vertical, is_active, sort_order);
CREATE INDEX provider_services_category_status_idx
  ON public.provider_services (category_id, status);
CREATE INDEX provider_services_provider_status_idx
  ON public.provider_services (provider_id, status);
CREATE INDEX provider_resources_category_status_idx
  ON public.provider_resources (category_id, status);
CREATE INDEX service_bookings_customer_created_idx
  ON public.service_bookings (customer_id, created_at DESC);
CREATE INDEX service_bookings_provider_status_idx
  ON public.service_bookings (provider_id, status, created_at DESC);
CREATE INDEX service_bookings_category_status_idx
  ON public.service_bookings (category_id, status, created_at DESC);
CREATE INDEX service_quotes_booking_idx
  ON public.service_quotes (booking_id, status);
CREATE INDEX service_reviews_provider_created_idx
  ON public.service_reviews (provider_id, created_at DESC);

CREATE TRIGGER service_categories_set_updated_at
BEFORE UPDATE ON public.service_categories
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER provider_profiles_set_updated_at
BEFORE UPDATE ON public.provider_profiles
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER provider_services_set_updated_at
BEFORE UPDATE ON public.provider_services
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER provider_resources_set_updated_at
BEFORE UPDATE ON public.provider_resources
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER service_bookings_set_updated_at
BEFORE UPDATE ON public.service_bookings
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER service_quotes_set_updated_at
BEFORE UPDATE ON public.service_quotes
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER service_reviews_set_updated_at
BEFORE UPDATE ON public.service_reviews
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

INSERT INTO public.service_categories (
  slug, name, description, vertical, booking_mode, icon_key, is_active, sort_order
)
VALUES
  ('taxi-ride', 'Taxi / Ride', 'On-demand passenger transport with approved drivers.', 'mobility', 'on_demand', 'car', true, 10),
  ('vehicle-hire', 'Hire Car / Vehicle', 'Scheduled vehicle hire for personal, business, NGO and project use.', 'hire', 'reservation', 'car-rental', true, 20),
  ('boat-hire', 'Boat Hire', 'Private boat and dinghy hire with approved operators.', 'hire', 'reservation', 'boat', true, 30),
  ('boat-ship-rides', 'Boat / Ship Rides', 'Passenger water transport, routes and scheduled services.', 'mobility', 'scheduled', 'ferry', true, 40),
  ('specialist-services', 'Specialist Services', 'Vetted trades and professionals such as electricians, plumbers, builders, IT, guides, translators, trainers, consultants and media crews.', 'people', 'quote', 'tools', true, 50),
  ('general-labour', 'People / General Labour', 'Hire available workers and helpers for short-term or scheduled work.', 'people', 'quote', 'people', true, 60),
  ('venue-booking', 'Venue Booking', 'Book halls, conference rooms, fields and other spaces.', 'places', 'reservation', 'venue', true, 70),
  ('events', 'Events', 'Discover local events and connect tickets, transport and venues.', 'events', 'ticketing', 'calendar', true, 80),
  ('delivery', 'Delivery / Courier', 'Point-to-point parcel, document and goods delivery.', 'delivery', 'on_demand', 'delivery', true, 90),
  ('errands', 'Errands / Pabili', 'Request a trusted provider to buy, collect or complete an errand.', 'delivery', 'quote', 'errand', true, 100),
  ('food', 'Food', 'Order meals and drinks from approved food vendors.', 'food', 'commerce', 'food', true, 110),
  ('groceries', 'Groceries / Shops', 'Order groceries and everyday goods from participating shops.', 'shopping', 'commerce', 'shop', true, 120),
  ('bus-coach', 'Bus / Coach', 'Scheduled road passenger transport and intercity services.', 'travel', 'scheduled', 'bus', false, 200),
  ('accommodation', 'Hotels / Accommodation', 'Accommodation discovery and reservations.', 'travel', 'reservation', 'hotel', false, 210),
  ('flights', 'Flights', 'Flight discovery and booking integrations.', 'travel', 'reservation', 'flight', false, 220)
ON CONFLICT (slug) DO UPDATE
SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  vertical = EXCLUDED.vertical,
  booking_mode = EXCLUDED.booking_mode,
  icon_key = EXCLUDED.icon_key,
  is_active = EXCLUDED.is_active,
  sort_order = EXCLUDED.sort_order,
  updated_at = now();

CREATE OR REPLACE FUNCTION public.provider_category_slug(p_service_type text)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE lower(trim(COALESCE(p_service_type, '')))
    WHEN 'driver' THEN 'taxi-ride'
    WHEN 'taxi' THEN 'taxi-ride'
    WHEN 'delivery' THEN 'delivery'
    WHEN 'food_vendor' THEN 'food'
    WHEN 'shop' THEN 'groceries'
    WHEN 'specialist' THEN 'specialist-services'
    WHEN 'general_labour' THEN 'general-labour'
    WHEN 'vehicle_hire' THEN 'vehicle-hire'
    WHEN 'boat_hire' THEN 'boat-hire'
    WHEN 'boat_operator' THEN 'boat-ship-rides'
    WHEN 'venue' THEN 'venue-booking'
    WHEN 'events' THEN 'events'
    ELSE NULL
  END;
$$;

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
  v_display_name text;
  v_category_slug text;
  v_category_id uuid;
BEGIN
  IF auth.uid() IS NULL OR NOT public.is_admin(auth.uid()) THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  IF v_decision NOT IN ('approved', 'rejected') THEN
    RAISE EXCEPTION 'Decision must be approved or rejected';
  END IF;

  SELECT * INTO v_application
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
  SET status = v_decision,
      reviewed_by = auth.uid(),
      reviewed_at = now()
  WHERE id = p_application_id
  RETURNING * INTO v_application;

  IF v_decision = 'approved' THEN
    UPDATE public.profiles AS p
    SET is_provider = true,
        is_driver = CASE
          WHEN lower(v_application.service_type) IN ('driver', 'taxi') THEN true
          ELSE p.is_driver
        END,
        is_driver_approved = CASE
          WHEN lower(v_application.service_type) IN ('driver', 'taxi') THEN true
          ELSE p.is_driver_approved
        END
    WHERE p.id = v_application.user_id;

    SELECT COALESCE(
      NULLIF(trim(v_application.company_name), ''),
      NULLIF(trim(p.full_name), ''),
      'Wantok Provider'
    )
    INTO v_display_name
    FROM public.profiles AS p
    WHERE p.id = v_application.user_id;

    INSERT INTO public.provider_profiles (
      provider_id,
      display_name,
      provider_type,
      verification_status,
      is_active
    )
    VALUES (
      v_application.user_id,
      v_display_name,
      CASE WHEN NULLIF(trim(v_application.company_name), '') IS NULL
        THEN 'individual' ELSE 'business' END,
      'verified',
      true
    )
    ON CONFLICT (provider_id) DO UPDATE
    SET display_name = EXCLUDED.display_name,
        verification_status = 'verified',
        is_active = true,
        updated_at = now();

    IF lower(v_application.service_type) IN ('driver', 'taxi') THEN
      INSERT INTO public.driver_profiles (
        driver_id, vehicle_rego, vehicle_make, vehicle_model, vehicle_colour
      )
      VALUES (
        v_application.user_id,
        v_application.vehicle_plate,
        v_application.vehicle_make,
        v_application.vehicle_model,
        v_application.vehicle_color
      )
      ON CONFLICT (driver_id) DO UPDATE
      SET vehicle_rego = EXCLUDED.vehicle_rego,
          vehicle_make = EXCLUDED.vehicle_make,
          vehicle_model = EXCLUDED.vehicle_model,
          vehicle_colour = EXCLUDED.vehicle_colour,
          updated_at = now();
    END IF;

    v_category_slug := public.provider_category_slug(v_application.service_type);
    IF v_category_slug IS NOT NULL THEN
      SELECT id INTO v_category_id
      FROM public.service_categories
      WHERE slug = v_category_slug;

      IF v_category_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM public.provider_services
        WHERE provider_id = v_application.user_id
          AND category_id = v_category_id
      ) THEN
        INSERT INTO public.provider_services (
          provider_id, category_id, title, pricing_model, status
        ) VALUES (
          v_application.user_id,
          v_category_id,
          v_display_name,
          'quote',
          'draft'
        );
      END IF;
    END IF;
  END IF;

  RETURN v_application;
END;
$$;

REVOKE ALL ON FUNCTION public.review_provider_application(uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.review_provider_application(uuid, text) TO authenticated;

CREATE OR REPLACE FUNCTION public.cancel_service_booking(p_booking_id uuid)
RETURNS public.service_bookings
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_booking public.service_bookings%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT * INTO v_booking
  FROM public.service_bookings
  WHERE id = p_booking_id
  FOR UPDATE;

  IF NOT FOUND OR v_booking.customer_id <> auth.uid() THEN
    RAISE EXCEPTION 'Booking not found';
  END IF;

  IF v_booking.status NOT IN ('requested', 'quoted', 'accepted', 'confirmed') THEN
    RAISE EXCEPTION 'Booking cannot be cancelled in its current state';
  END IF;

  UPDATE public.service_bookings
  SET status = 'cancelled', cancelled_at = now()
  WHERE id = p_booking_id
  RETURNING * INTO v_booking;

  RETURN v_booking;
END;
$$;

REVOKE ALL ON FUNCTION public.cancel_service_booking(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.cancel_service_booking(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.provider_respond_service_booking(
  p_booking_id uuid,
  p_accept boolean
)
RETURNS public.service_bookings
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_booking public.service_bookings%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT * INTO v_booking
  FROM public.service_bookings
  WHERE id = p_booking_id
  FOR UPDATE;

  IF NOT FOUND OR v_booking.provider_id <> auth.uid() THEN
    RAISE EXCEPTION 'Booking not found';
  END IF;

  IF v_booking.status NOT IN ('requested', 'accepted') THEN
    RAISE EXCEPTION 'Booking cannot be responded to in its current state';
  END IF;

  UPDATE public.service_bookings
  SET status = CASE WHEN p_accept THEN 'confirmed' ELSE 'rejected' END
  WHERE id = p_booking_id
  RETURNING * INTO v_booking;

  RETURN v_booking;
END;
$$;

REVOKE ALL ON FUNCTION public.provider_respond_service_booking(uuid, boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.provider_respond_service_booking(uuid, boolean) TO authenticated;

CREATE OR REPLACE FUNCTION public.accept_service_quote(p_quote_id uuid)
RETURNS public.service_bookings
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_quote public.service_quotes%ROWTYPE;
  v_booking public.service_bookings%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT q.* INTO v_quote
  FROM public.service_quotes AS q
  JOIN public.service_bookings AS b ON b.id = q.booking_id
  WHERE q.id = p_quote_id
    AND b.customer_id = auth.uid()
  FOR UPDATE OF q;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Quote not found';
  END IF;

  IF v_quote.status <> 'pending' THEN
    RAISE EXCEPTION 'Quote is not pending';
  END IF;

  IF v_quote.expires_at IS NOT NULL AND v_quote.expires_at <= now() THEN
    UPDATE public.service_quotes SET status = 'expired' WHERE id = p_quote_id;
    RAISE EXCEPTION 'Quote has expired';
  END IF;

  UPDATE public.service_quotes
  SET status = CASE WHEN id = p_quote_id THEN 'accepted' ELSE 'rejected' END
  WHERE booking_id = v_quote.booking_id
    AND status = 'pending';

  UPDATE public.service_bookings
  SET provider_id = v_quote.provider_id,
      quoted_amount = v_quote.amount,
      currency = v_quote.currency,
      status = 'confirmed'
  WHERE id = v_quote.booking_id
  RETURNING * INTO v_booking;

  RETURN v_booking;
END;
$$;

REVOKE ALL ON FUNCTION public.accept_service_quote(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.accept_service_quote(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.admin_set_provider_service_status(
  p_service_id uuid,
  p_status text
)
RETURNS public.provider_services
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_status text := lower(trim(p_status));
  v_service public.provider_services%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL OR NOT public.is_admin(auth.uid()) THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  IF v_status NOT IN ('draft', 'pending_review', 'active', 'paused', 'rejected') THEN
    RAISE EXCEPTION 'Invalid provider service status';
  END IF;

  UPDATE public.provider_services
  SET status = v_status
  WHERE id = p_service_id
  RETURNING * INTO v_service;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Provider service not found';
  END IF;

  RETURN v_service;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_set_provider_service_status(uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_set_provider_service_status(uuid, text) TO authenticated;

CREATE OR REPLACE FUNCTION public.refresh_provider_rating()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_provider_id uuid := COALESCE(NEW.provider_id, OLD.provider_id);
BEGIN
  UPDATE public.provider_profiles
  SET rating_average = COALESCE((
        SELECT round(avg(r.rating)::numeric, 2)
        FROM public.service_reviews AS r
        WHERE r.provider_id = v_provider_id
      ), 0),
      rating_count = (
        SELECT count(*)
        FROM public.service_reviews AS r
        WHERE r.provider_id = v_provider_id
      )
  WHERE provider_id = v_provider_id;

  RETURN COALESCE(NEW, OLD);
END;
$$;

CREATE TRIGGER service_reviews_refresh_provider_rating
AFTER INSERT OR UPDATE OR DELETE ON public.service_reviews
FOR EACH ROW EXECUTE FUNCTION public.refresh_provider_rating();

CREATE OR REPLACE FUNCTION public.submit_provider_service_for_review(p_service_id uuid)
RETURNS public.provider_services
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_service public.provider_services%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  UPDATE public.provider_services
  SET status = 'pending_review'
  WHERE id = p_service_id
    AND provider_id = auth.uid()
    AND status IN ('draft', 'rejected')
  RETURNING * INTO v_service;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Provider service is not available for review submission';
  END IF;

  RETURN v_service;
END;
$$;

REVOKE ALL ON FUNCTION public.submit_provider_service_for_review(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.submit_provider_service_for_review(uuid) TO authenticated;

ALTER TABLE public.service_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provider_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provider_services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provider_resources ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_quotes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_reviews ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.service_categories FROM anon, authenticated;
REVOKE ALL ON TABLE public.provider_profiles FROM anon, authenticated;
REVOKE ALL ON TABLE public.provider_services FROM anon, authenticated;
REVOKE ALL ON TABLE public.provider_resources FROM anon, authenticated;
REVOKE ALL ON TABLE public.service_bookings FROM anon, authenticated;
REVOKE ALL ON TABLE public.service_quotes FROM anon, authenticated;
REVOKE ALL ON TABLE public.service_reviews FROM anon, authenticated;

GRANT SELECT ON TABLE public.service_categories TO anon, authenticated;
GRANT SELECT ON TABLE public.provider_profiles TO anon, authenticated;
GRANT SELECT ON TABLE public.provider_services TO anon, authenticated;
GRANT SELECT ON TABLE public.provider_resources TO anon, authenticated;
GRANT SELECT ON TABLE public.service_reviews TO anon, authenticated;

GRANT INSERT (
  provider_id, display_name, provider_type, bio,
  base_address, base_lat, base_lng, service_radius_km, metadata
) ON TABLE public.provider_profiles TO authenticated;
GRANT UPDATE (
  display_name, provider_type, bio,
  base_address, base_lat, base_lng, service_radius_km, metadata
) ON TABLE public.provider_profiles TO authenticated;

GRANT INSERT (
  provider_id, category_id, title, description, pricing_model,
  base_price, minimum_charge, currency, unit_label,
  service_address, lat, lng, service_radius_km,
  booking_notice_minutes, metadata
) ON TABLE public.provider_services TO authenticated;
GRANT UPDATE (
  category_id, title, description, pricing_model,
  base_price, minimum_charge, currency, unit_label,
  service_address, lat, lng, service_radius_km,
  booking_notice_minutes, metadata
) ON TABLE public.provider_services TO authenticated;

GRANT INSERT (
  provider_id, category_id, resource_type, name, description,
  capacity, address_text, lat, lng, metadata
) ON TABLE public.provider_resources TO authenticated;
GRANT UPDATE (
  category_id, resource_type, name, description,
  capacity, address_text, lat, lng, metadata
) ON TABLE public.provider_resources TO authenticated;

GRANT SELECT ON TABLE public.service_bookings TO authenticated;
GRANT INSERT (
  customer_id, category_id, provider_id, provider_service_id, resource_id,
  scheduled_start, scheduled_end, quantity, service_address,
  origin_address, origin_lat, origin_lng,
  destination_address, destination_lat, destination_lng,
  notes, requested_amount, currency, metadata
) ON TABLE public.service_bookings TO authenticated;

GRANT SELECT ON TABLE public.service_quotes TO authenticated;
GRANT INSERT (
  booking_id, provider_id, amount, currency, message, expires_at
) ON TABLE public.service_quotes TO authenticated;

GRANT INSERT (
  booking_id, reviewer_id, provider_id, rating, comment
) ON TABLE public.service_reviews TO authenticated;

CREATE POLICY service_categories_public_read
ON public.service_categories
FOR SELECT
TO anon, authenticated
USING (is_active = true);

CREATE POLICY service_categories_admin_read_all
ON public.service_categories
FOR SELECT
TO authenticated
USING (public.is_admin(auth.uid()));

CREATE POLICY provider_profiles_public_read
ON public.provider_profiles
FOR SELECT
TO anon
USING (is_active = true AND verification_status = 'verified');

CREATE POLICY provider_profiles_authenticated_read
ON public.provider_profiles
FOR SELECT
TO authenticated
USING (
  provider_id = auth.uid()
  OR public.is_admin(auth.uid())
  OR (is_active = true AND verification_status = 'verified')
);

CREATE POLICY provider_profiles_insert_own
ON public.provider_profiles
FOR INSERT
TO authenticated
WITH CHECK (
  provider_id = auth.uid()
  AND EXISTS (
    SELECT 1 FROM public.profiles AS p
    WHERE p.id = auth.uid() AND p.is_provider = true
  )
);

CREATE POLICY provider_profiles_update_own
ON public.provider_profiles
FOR UPDATE
TO authenticated
USING (provider_id = auth.uid())
WITH CHECK (provider_id = auth.uid());

CREATE POLICY provider_services_public_read
ON public.provider_services
FOR SELECT
TO anon
USING (
  status = 'active'
  AND EXISTS (
    SELECT 1 FROM public.provider_profiles AS pp
    WHERE pp.provider_id = provider_services.provider_id
      AND pp.is_active = true
      AND pp.verification_status = 'verified'
  )
);

CREATE POLICY provider_services_authenticated_read
ON public.provider_services
FOR SELECT
TO authenticated
USING (
  provider_id = auth.uid()
  OR public.is_admin(auth.uid())
  OR (
    status = 'active'
    AND EXISTS (
      SELECT 1 FROM public.provider_profiles AS pp
      WHERE pp.provider_id = provider_services.provider_id
        AND pp.is_active = true
        AND pp.verification_status = 'verified'
    )
  )
);

CREATE POLICY provider_services_insert_own
ON public.provider_services
FOR INSERT
TO authenticated
WITH CHECK (
  provider_id = auth.uid()
  AND EXISTS (
    SELECT 1 FROM public.provider_profiles AS pp
    WHERE pp.provider_id = auth.uid()
      AND pp.verification_status = 'verified'
      AND pp.is_active = true
  )
);

CREATE POLICY provider_services_update_own
ON public.provider_services
FOR UPDATE
TO authenticated
USING (provider_id = auth.uid())
WITH CHECK (provider_id = auth.uid());

CREATE POLICY provider_resources_public_read
ON public.provider_resources
FOR SELECT
TO anon
USING (
  status = 'active'
  AND EXISTS (
    SELECT 1 FROM public.provider_profiles AS pp
    WHERE pp.provider_id = provider_resources.provider_id
      AND pp.is_active = true
      AND pp.verification_status = 'verified'
  )
);

CREATE POLICY provider_resources_authenticated_read
ON public.provider_resources
FOR SELECT
TO authenticated
USING (
  provider_id = auth.uid()
  OR public.is_admin(auth.uid())
  OR (
    status = 'active'
    AND EXISTS (
      SELECT 1 FROM public.provider_profiles AS pp
      WHERE pp.provider_id = provider_resources.provider_id
        AND pp.is_active = true
        AND pp.verification_status = 'verified'
    )
  )
);

CREATE POLICY provider_resources_insert_own
ON public.provider_resources
FOR INSERT
TO authenticated
WITH CHECK (
  provider_id = auth.uid()
  AND EXISTS (
    SELECT 1 FROM public.provider_profiles AS pp
    WHERE pp.provider_id = auth.uid()
      AND pp.verification_status = 'verified'
      AND pp.is_active = true
  )
);

CREATE POLICY provider_resources_update_own
ON public.provider_resources
FOR UPDATE
TO authenticated
USING (provider_id = auth.uid())
WITH CHECK (provider_id = auth.uid());

CREATE POLICY service_bookings_read_participants
ON public.service_bookings
FOR SELECT
TO authenticated
USING (
  customer_id = auth.uid()
  OR provider_id = auth.uid()
  OR public.is_admin(auth.uid())
);

CREATE POLICY service_bookings_insert_customer
ON public.service_bookings
FOR INSERT
TO authenticated
WITH CHECK (
  customer_id = auth.uid()
  AND EXISTS (
    SELECT 1 FROM public.service_categories AS c
    WHERE c.id = category_id AND c.is_active = true
  )
  AND (
    provider_id IS NULL
    OR EXISTS (
      SELECT 1 FROM public.provider_profiles AS pp
      WHERE pp.provider_id = service_bookings.provider_id
        AND pp.is_active = true
        AND pp.verification_status = 'verified'
    )
  )
  AND (
    provider_service_id IS NULL
    OR EXISTS (
      SELECT 1 FROM public.provider_services AS ps
      WHERE ps.id = service_bookings.provider_service_id
        AND ps.provider_id = service_bookings.provider_id
        AND ps.category_id = service_bookings.category_id
        AND ps.status = 'active'
    )
  )
  AND (
    resource_id IS NULL
    OR EXISTS (
      SELECT 1 FROM public.provider_resources AS pr
      WHERE pr.id = service_bookings.resource_id
        AND pr.provider_id = service_bookings.provider_id
        AND pr.category_id = service_bookings.category_id
        AND pr.status = 'active'
    )
  )
);

CREATE POLICY service_quotes_read_participants
ON public.service_quotes
FOR SELECT
TO authenticated
USING (
  provider_id = auth.uid()
  OR public.is_admin(auth.uid())
  OR EXISTS (
    SELECT 1 FROM public.service_bookings AS b
    WHERE b.id = service_quotes.booking_id
      AND b.customer_id = auth.uid()
  )
);

CREATE POLICY service_quotes_insert_provider
ON public.service_quotes
FOR INSERT
TO authenticated
WITH CHECK (
  provider_id = auth.uid()
  AND EXISTS (
    SELECT 1
    FROM public.service_bookings AS b
    JOIN public.provider_services AS ps
      ON ps.provider_id = auth.uid()
     AND ps.category_id = b.category_id
     AND ps.status = 'active'
    WHERE b.id = service_quotes.booking_id
      AND b.status IN ('requested', 'quoted')
      AND (b.provider_id IS NULL OR b.provider_id = auth.uid())
  )
);

CREATE POLICY service_reviews_public_read
ON public.service_reviews
FOR SELECT
TO anon, authenticated
USING (true);

CREATE POLICY service_reviews_insert_customer
ON public.service_reviews
FOR INSERT
TO authenticated
WITH CHECK (
  reviewer_id = auth.uid()
  AND EXISTS (
    SELECT 1 FROM public.service_bookings AS b
    WHERE b.id = service_reviews.booking_id
      AND b.customer_id = auth.uid()
      AND b.provider_id = service_reviews.provider_id
      AND b.status = 'completed'
  )
);

CREATE POLICY service_bookings_read_open_for_qualified_providers
ON public.service_bookings
FOR SELECT
TO authenticated
USING (
  provider_id IS NULL
  AND status IN ('requested', 'quoted')
  AND EXISTS (
    SELECT 1 FROM public.provider_services AS ps
    WHERE ps.provider_id = auth.uid()
      AND ps.category_id = service_bookings.category_id
      AND ps.status = 'active'
  )
);

CREATE OR REPLACE FUNCTION public.submit_service_quote(
  p_booking_id uuid,
  p_amount numeric,
  p_message text DEFAULT NULL,
  p_expires_at timestamptz DEFAULT NULL
)
RETURNS public.service_quotes
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_booking public.service_bookings%ROWTYPE;
  v_quote public.service_quotes%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF p_amount IS NULL OR p_amount < 0 THEN
    RAISE EXCEPTION 'Quote amount must be zero or greater';
  END IF;

  SELECT * INTO v_booking
  FROM public.service_bookings
  WHERE id = p_booking_id
  FOR UPDATE;

  IF NOT FOUND OR v_booking.status NOT IN ('requested', 'quoted') THEN
    RAISE EXCEPTION 'Booking is not available for quotes';
  END IF;

  IF v_booking.provider_id IS NOT NULL AND v_booking.provider_id <> auth.uid() THEN
    RAISE EXCEPTION 'Booking is assigned to another provider';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.provider_profiles AS pp
    JOIN public.provider_services AS ps ON ps.provider_id = pp.provider_id
    WHERE pp.provider_id = auth.uid()
      AND pp.is_active = true
      AND pp.verification_status = 'verified'
      AND ps.category_id = v_booking.category_id
      AND ps.status = 'active'
  ) THEN
    RAISE EXCEPTION 'Provider is not approved for this service category';
  END IF;

  INSERT INTO public.service_quotes (
    booking_id, provider_id, amount, currency, message, expires_at
  ) VALUES (
    p_booking_id, auth.uid(), p_amount, v_booking.currency, p_message, p_expires_at
  )
  ON CONFLICT (booking_id, provider_id) DO UPDATE
  SET amount = EXCLUDED.amount,
      currency = EXCLUDED.currency,
      message = EXCLUDED.message,
      expires_at = EXCLUDED.expires_at,
      status = 'pending',
      updated_at = now()
  RETURNING * INTO v_quote;

  IF v_booking.status = 'requested' THEN
    UPDATE public.service_bookings
    SET status = 'quoted'
    WHERE id = p_booking_id;
  END IF;

  RETURN v_quote;
END;
$$;

REVOKE INSERT ON TABLE public.service_quotes FROM authenticated;
REVOKE ALL ON FUNCTION public.submit_service_quote(uuid, numeric, text, timestamptz) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.submit_service_quote(uuid, numeric, text, timestamptz) TO authenticated;

CREATE OR REPLACE FUNCTION public.provider_advance_service_booking(
  p_booking_id uuid,
  p_status text
)
RETURNS public.service_bookings
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_booking public.service_bookings%ROWTYPE;
  v_status text := lower(trim(p_status));
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT * INTO v_booking
  FROM public.service_bookings
  WHERE id = p_booking_id
    AND provider_id = auth.uid()
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Booking not found';
  END IF;

  IF v_status = 'in_progress' AND v_booking.status <> 'confirmed' THEN
    RAISE EXCEPTION 'Only confirmed bookings can start';
  ELSIF v_status = 'completed' AND v_booking.status <> 'in_progress' THEN
    RAISE EXCEPTION 'Only in-progress bookings can complete';
  ELSIF v_status NOT IN ('in_progress', 'completed') THEN
    RAISE EXCEPTION 'Invalid provider booking transition';
  END IF;

  UPDATE public.service_bookings
  SET status = v_status,
      completed_at = CASE WHEN v_status = 'completed' THEN now() ELSE completed_at END
  WHERE id = p_booking_id
  RETURNING * INTO v_booking;

  RETURN v_booking;
END;
$$;

REVOKE ALL ON FUNCTION public.provider_advance_service_booking(uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.provider_advance_service_booking(uuid, text) TO authenticated;

CREATE OR REPLACE FUNCTION public.submit_provider_resource_for_review(p_resource_id uuid)
RETURNS public.provider_resources
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_resource public.provider_resources%ROWTYPE;
BEGIN
  UPDATE public.provider_resources
  SET status = 'pending_review'
  WHERE id = p_resource_id
    AND provider_id = auth.uid()
    AND status IN ('draft', 'rejected')
  RETURNING * INTO v_resource;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Provider resource is not available for review submission';
  END IF;

  RETURN v_resource;
END;
$$;

REVOKE ALL ON FUNCTION public.submit_provider_resource_for_review(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.submit_provider_resource_for_review(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.admin_set_provider_resource_status(
  p_resource_id uuid,
  p_status text
)
RETURNS public.provider_resources
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_status text := lower(trim(p_status));
  v_resource public.provider_resources%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL OR NOT public.is_admin(auth.uid()) THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  IF v_status NOT IN ('draft', 'pending_review', 'active', 'paused', 'rejected', 'unavailable') THEN
    RAISE EXCEPTION 'Invalid provider resource status';
  END IF;

  UPDATE public.provider_resources
  SET status = v_status
  WHERE id = p_resource_id
  RETURNING * INTO v_resource;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Provider resource not found';
  END IF;

  RETURN v_resource;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_set_provider_resource_status(uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_set_provider_resource_status(uuid, text) TO authenticated;
