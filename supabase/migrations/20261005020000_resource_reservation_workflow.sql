-- Wantok Service resource reservation workflow.
-- Makes reservable assets safe for multi-client/mobile/web use and future horizontal scaling.

CREATE OR REPLACE FUNCTION public.is_resource_available(
  p_resource_id uuid,
  p_starts_at timestamptz,
  p_ends_at timestamptz,
  p_exclude_booking_id uuid DEFAULT NULL
)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_resource public.provider_resources%ROWTYPE;
BEGIN
  IF p_starts_at IS NULL OR p_ends_at IS NULL OR p_ends_at <= p_starts_at THEN
    RETURN false;
  END IF;

  SELECT *
  INTO v_resource
  FROM public.provider_resources
  WHERE id = p_resource_id
    AND status = 'active';

  IF NOT FOUND THEN
    RETURN false;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.service_bookings AS b
    WHERE b.resource_id = p_resource_id
      AND b.id IS DISTINCT FROM p_exclude_booking_id
      AND b.status IN ('confirmed', 'in_progress')
      AND tstzrange(b.scheduled_start, b.scheduled_end, '[)')
          && tstzrange(p_starts_at, p_ends_at, '[)')
  ) THEN
    RETURN false;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.provider_time_off AS pto
    WHERE pto.provider_id = v_resource.provider_id
      AND (pto.resource_id IS NULL OR pto.resource_id = p_resource_id)
      AND tstzrange(pto.starts_at, pto.ends_at, '[)')
          && tstzrange(p_starts_at, p_ends_at, '[)')
  ) THEN
    RETURN false;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.provider_availability_rules AS r
    WHERE r.provider_id = v_resource.provider_id
      AND r.is_active = true
      AND (r.category_id IS NULL OR r.category_id = v_resource.category_id)
      AND (r.resource_id IS NULL OR r.resource_id = p_resource_id)
      AND (r.effective_from IS NULL OR r.effective_from <= (p_starts_at AT TIME ZONE r.timezone)::date)
      AND (r.effective_to IS NULL OR r.effective_to >= (p_starts_at AT TIME ZONE r.timezone)::date)
  ) AND NOT EXISTS (
    SELECT 1
    FROM public.provider_availability_rules AS r
    WHERE r.provider_id = v_resource.provider_id
      AND r.is_active = true
      AND (r.category_id IS NULL OR r.category_id = v_resource.category_id)
      AND (r.resource_id IS NULL OR r.resource_id = p_resource_id)
      AND r.day_of_week = extract(dow FROM (p_starts_at AT TIME ZONE r.timezone))::smallint
      AND (r.effective_from IS NULL OR r.effective_from <= (p_starts_at AT TIME ZONE r.timezone)::date)
      AND (r.effective_to IS NULL OR r.effective_to >= (p_starts_at AT TIME ZONE r.timezone)::date)
      AND (p_starts_at AT TIME ZONE r.timezone)::date
          = ((p_ends_at - interval '1 microsecond') AT TIME ZONE r.timezone)::date
      AND (p_starts_at AT TIME ZONE r.timezone)::time >= r.start_time
      AND (p_ends_at AT TIME ZONE r.timezone)::time <= r.end_time
  ) THEN
    RETURN false;
  END IF;

  RETURN true;
END;
$$;

REVOKE ALL ON FUNCTION public.is_resource_available(uuid, timestamptz, timestamptz, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_resource_available(uuid, timestamptz, timestamptz, uuid)
  TO anon, authenticated;

CREATE OR REPLACE FUNCTION public.create_resource_reservation(
  p_provider_service_id uuid,
  p_resource_id uuid,
  p_starts_at timestamptz,
  p_ends_at timestamptz,
  p_quantity numeric DEFAULT 1,
  p_service_address text DEFAULT NULL,
  p_notes text DEFAULT NULL
)
RETURNS public.service_bookings
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_service public.provider_services%ROWTYPE;
  v_resource public.provider_resources%ROWTYPE;
  v_booking public.service_bookings%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF p_starts_at IS NULL OR p_ends_at IS NULL OR p_ends_at <= p_starts_at THEN
    RAISE EXCEPTION 'Reservation end time must be after start time';
  END IF;

  IF p_quantity IS NULL OR p_quantity <= 0 THEN
    RAISE EXCEPTION 'Reservation quantity must be greater than zero';
  END IF;

  SELECT ps.*
  INTO v_service
  FROM public.provider_services AS ps
  JOIN public.provider_profiles AS pp
    ON pp.provider_id = ps.provider_id
  JOIN public.service_categories AS sc
    ON sc.id = ps.category_id
  WHERE ps.id = p_provider_service_id
    AND ps.status = 'active'
    AND pp.is_active = true
    AND pp.verification_status = 'verified'
    AND sc.is_active = true;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Provider service is not available';
  END IF;

  SELECT *
  INTO v_resource
  FROM public.provider_resources
  WHERE id = p_resource_id
    AND provider_id = v_service.provider_id
    AND category_id = v_service.category_id
    AND status = 'active';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Resource is not available for this service';
  END IF;

  IF NOT public.is_resource_available(
    p_resource_id,
    p_starts_at,
    p_ends_at,
    NULL
  ) THEN
    RAISE EXCEPTION 'Resource is not available for the requested time';
  END IF;

  INSERT INTO public.service_bookings (
    customer_id,
    category_id,
    provider_id,
    provider_service_id,
    resource_id,
    status,
    scheduled_start,
    scheduled_end,
    quantity,
    service_address,
    notes,
    requested_amount,
    currency,
    metadata
  )
  VALUES (
    auth.uid(),
    v_service.category_id,
    v_service.provider_id,
    v_service.id,
    v_resource.id,
    'requested',
    p_starts_at,
    p_ends_at,
    p_quantity,
    COALESCE(NULLIF(trim(p_service_address), ''), v_resource.address_text, v_service.service_address),
    NULLIF(trim(p_notes), ''),
    CASE
      WHEN v_service.pricing_model IN ('fixed', 'per_job') THEN v_service.base_price
      ELSE NULL
    END,
    v_service.currency,
    jsonb_build_object('source', 'wantok-flutter', 'booking_mode', 'reservation')
  )
  RETURNING * INTO v_booking;

  RETURN v_booking;
END;
$$;

REVOKE ALL ON FUNCTION public.create_resource_reservation(
  uuid, uuid, timestamptz, timestamptz, numeric, text, text
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_resource_reservation(
  uuid, uuid, timestamptz, timestamptz, numeric, text, text
) TO authenticated;
