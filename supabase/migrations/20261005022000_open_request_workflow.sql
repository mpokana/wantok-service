-- Wantok Service open marketplace request workflow.
-- Supports quote/on-demand work such as delivery, errands, specialists and labour.

CREATE OR REPLACE FUNCTION public.provider_category_slug(p_service_type text)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE lower(trim(COALESCE(p_service_type, '')))
    WHEN 'driver' THEN 'taxi-ride'
    WHEN 'taxi' THEN 'taxi-ride'
    WHEN 'delivery' THEN 'delivery'
    WHEN 'errands' THEN 'errands'
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

CREATE OR REPLACE FUNCTION public.submit_provider_application(
  p_service_type text,
  p_company_name text DEFAULT NULL,
  p_vehicle_plate text DEFAULT NULL,
  p_vehicle_make text DEFAULT NULL,
  p_vehicle_model text DEFAULT NULL,
  p_vehicle_color text DEFAULT NULL,
  p_notes text DEFAULT NULL
)
RETURNS public.provider_applications
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_service_type text := lower(trim(COALESCE(p_service_type, '')));
  v_application public.provider_applications%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF v_service_type NOT IN (
    'driver',
    'vehicle_hire',
    'boat_hire',
    'boat_operator',
    'delivery',
    'errands',
    'food_vendor',
    'shop',
    'specialist',
    'general_labour',
    'venue',
    'events'
  ) THEN
    RAISE EXCEPTION 'Unsupported provider service type';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.provider_applications AS pa
    WHERE pa.user_id = auth.uid()
      AND lower(pa.service_type) = v_service_type
      AND pa.status IN ('pending', 'approved')
  ) THEN
    RAISE EXCEPTION 'An application already exists for this service';
  END IF;

  INSERT INTO public.provider_applications (
    user_id,
    service_type,
    company_name,
    vehicle_plate,
    vehicle_make,
    vehicle_model,
    vehicle_color,
    notes
  )
  VALUES (
    auth.uid(),
    v_service_type,
    NULLIF(trim(p_company_name), ''),
    NULLIF(trim(p_vehicle_plate), ''),
    NULLIF(trim(p_vehicle_make), ''),
    NULLIF(trim(p_vehicle_model), ''),
    NULLIF(trim(p_vehicle_color), ''),
    NULLIF(trim(p_notes), '')
  )
  RETURNING * INTO v_application;

  RETURN v_application;
END;
$$;

REVOKE ALL ON FUNCTION public.submit_provider_application(
  text, text, text, text, text, text, text
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.submit_provider_application(
  text, text, text, text, text, text, text
) TO authenticated;

CREATE OR REPLACE FUNCTION public.create_open_service_request(
  p_category_slug text,
  p_service_address text DEFAULT NULL,
  p_origin_address text DEFAULT NULL,
  p_destination_address text DEFAULT NULL,
  p_scheduled_start timestamptz DEFAULT NULL,
  p_notes text DEFAULT NULL,
  p_requested_amount numeric DEFAULT NULL,
  p_quantity numeric DEFAULT 1,
  p_metadata jsonb DEFAULT '{}'::jsonb
)
RETURNS public.service_bookings
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_slug text := lower(trim(COALESCE(p_category_slug, '')));
  v_category public.service_categories%ROWTYPE;
  v_booking public.service_bookings%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF v_slug NOT IN (
    'delivery',
    'errands',
    'specialist-services',
    'general-labour'
  ) THEN
    RAISE EXCEPTION 'This service does not use the open-request workflow';
  END IF;

  IF p_quantity IS NULL OR p_quantity <= 0 THEN
    RAISE EXCEPTION 'Quantity must be greater than zero';
  END IF;

  IF p_requested_amount IS NOT NULL AND p_requested_amount < 0 THEN
    RAISE EXCEPTION 'Requested amount must be zero or greater';
  END IF;

  IF v_slug = 'delivery'
     AND (
       NULLIF(trim(p_origin_address), '') IS NULL
       OR NULLIF(trim(p_destination_address), '') IS NULL
     ) THEN
    RAISE EXCEPTION 'Delivery requires pickup and destination addresses';
  END IF;

  SELECT *
  INTO v_category
  FROM public.service_categories
  WHERE slug = v_slug
    AND is_active = true;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Service category is not available';
  END IF;

  INSERT INTO public.service_bookings (
    customer_id,
    category_id,
    status,
    scheduled_start,
    quantity,
    service_address,
    origin_address,
    destination_address,
    notes,
    requested_amount,
    currency,
    metadata
  )
  VALUES (
    auth.uid(),
    v_category.id,
    'requested',
    p_scheduled_start,
    p_quantity,
    NULLIF(trim(p_service_address), ''),
    NULLIF(trim(p_origin_address), ''),
    NULLIF(trim(p_destination_address), ''),
    NULLIF(trim(p_notes), ''),
    p_requested_amount,
    'PGK',
    COALESCE(p_metadata, '{}'::jsonb)
      || jsonb_build_object(
        'source', 'wantok-flutter',
        'booking_mode', 'open_request'
      )
  )
  RETURNING * INTO v_booking;

  RETURN v_booking;
END;
$$;

REVOKE ALL ON FUNCTION public.create_open_service_request(
  text, text, text, text, timestamptz, text, numeric, numeric, jsonb
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_open_service_request(
  text, text, text, text, timestamptz, text, numeric, numeric, jsonb
) TO authenticated;
