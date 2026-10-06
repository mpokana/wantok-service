-- CX1B delegated booking foundation.
-- The authenticated customer remains the booking owner/payer.
-- A selected trusted person is snapshotted as the service beneficiary only.

ALTER TABLE public.service_bookings
  ADD COLUMN trusted_person_id uuid
    REFERENCES public.trusted_people(id) ON DELETE SET NULL,
  ADD COLUMN beneficiary_name text,
  ADD COLUMN beneficiary_relationship text,
  ADD COLUMN beneficiary_phone text,
  ADD COLUMN beneficiary_email text;

ALTER TABLE public.service_bookings
  ADD CONSTRAINT service_bookings_beneficiary_name_not_blank
  CHECK (
    beneficiary_name IS NULL
    OR NULLIF(trim(beneficiary_name), '') IS NOT NULL
  );

CREATE INDEX service_bookings_customer_trusted_person_idx
  ON public.service_bookings (customer_id, trusted_person_id, created_at DESC)
  WHERE trusted_person_id IS NOT NULL;

COMMENT ON COLUMN public.service_bookings.trusted_person_id IS
  'Optional source Trusted person selected by the authenticated customer. ON DELETE SET NULL; snapshot fields preserve booking history.';

COMMENT ON COLUMN public.service_bookings.beneficiary_name IS
  'Immutable-at-booking-time display snapshot for the person receiving the service. NULL means the customer booked for themselves.';

COMMENT ON COLUMN public.service_bookings.beneficiary_relationship IS
  'Optional relationship snapshot copied from the customer-owned Trusted person record.';

COMMENT ON COLUMN public.service_bookings.beneficiary_phone IS
  'Optional contact snapshot copied from the customer-owned Trusted person record for service coordination.';

COMMENT ON COLUMN public.service_bookings.beneficiary_email IS
  'Optional email snapshot copied from the customer-owned Trusted person record for service coordination.';

CREATE OR REPLACE FUNCTION public.create_resource_reservation(
  p_provider_service_id uuid,
  p_resource_id uuid,
  p_starts_at timestamptz,
  p_ends_at timestamptz,
  p_quantity numeric DEFAULT 1,
  p_service_address text DEFAULT NULL,
  p_notes text DEFAULT NULL,
  p_trusted_person_id uuid DEFAULT NULL
)
RETURNS public.service_bookings
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_service public.provider_services%ROWTYPE;
  v_resource public.provider_resources%ROWTYPE;
  v_beneficiary public.trusted_people%ROWTYPE;
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

  IF p_trusted_person_id IS NOT NULL THEN
    SELECT *
    INTO v_beneficiary
    FROM public.trusted_people
    WHERE id = p_trusted_person_id
      AND owner_id = auth.uid()
      AND is_active = true;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Trusted person is not available';
    END IF;
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
    metadata,
    trusted_person_id,
    beneficiary_name,
    beneficiary_relationship,
    beneficiary_phone,
    beneficiary_email
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
    COALESCE(
      NULLIF(trim(p_service_address), ''),
      v_resource.address_text,
      v_service.service_address
    ),
    NULLIF(trim(p_notes), ''),
    CASE
      WHEN v_service.pricing_model IN ('fixed', 'per_job') THEN v_service.base_price
      ELSE NULL
    END,
    v_service.currency,
    jsonb_build_object(
      'source', 'wantok-flutter',
      'booking_mode', 'reservation',
      'booked_for', CASE
        WHEN p_trusted_person_id IS NULL THEN 'self'
        ELSE 'trusted_person'
      END
    ),
    p_trusted_person_id,
    CASE WHEN p_trusted_person_id IS NULL THEN NULL ELSE v_beneficiary.display_name END,
    CASE WHEN p_trusted_person_id IS NULL THEN NULL ELSE v_beneficiary.relationship END,
    CASE WHEN p_trusted_person_id IS NULL THEN NULL ELSE v_beneficiary.phone END,
    CASE WHEN p_trusted_person_id IS NULL THEN NULL ELSE v_beneficiary.email END
  )
  RETURNING * INTO v_booking;

  RETURN v_booking;
END;
$$;

DROP FUNCTION IF EXISTS public.create_resource_reservation(
  uuid, uuid, timestamptz, timestamptz, numeric, text, text
);

REVOKE ALL ON FUNCTION public.create_resource_reservation(
  uuid, uuid, timestamptz, timestamptz, numeric, text, text, uuid
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_resource_reservation(
  uuid, uuid, timestamptz, timestamptz, numeric, text, text, uuid
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
  p_metadata jsonb DEFAULT '{}'::jsonb,
  p_trusted_person_id uuid DEFAULT NULL
)
RETURNS public.service_bookings
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_slug text := lower(trim(COALESCE(p_category_slug, '')));
  v_category public.service_categories%ROWTYPE;
  v_beneficiary public.trusted_people%ROWTYPE;
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

  IF p_trusted_person_id IS NOT NULL THEN
    SELECT *
    INTO v_beneficiary
    FROM public.trusted_people
    WHERE id = p_trusted_person_id
      AND owner_id = auth.uid()
      AND is_active = true;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Trusted person is not available';
    END IF;
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
    metadata,
    trusted_person_id,
    beneficiary_name,
    beneficiary_relationship,
    beneficiary_phone,
    beneficiary_email
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
        'booking_mode', 'open_request',
        'booked_for', CASE
          WHEN p_trusted_person_id IS NULL THEN 'self'
          ELSE 'trusted_person'
        END
      ),
    p_trusted_person_id,
    CASE WHEN p_trusted_person_id IS NULL THEN NULL ELSE v_beneficiary.display_name END,
    CASE WHEN p_trusted_person_id IS NULL THEN NULL ELSE v_beneficiary.relationship END,
    CASE WHEN p_trusted_person_id IS NULL THEN NULL ELSE v_beneficiary.phone END,
    CASE WHEN p_trusted_person_id IS NULL THEN NULL ELSE v_beneficiary.email END
  )
  RETURNING * INTO v_booking;

  RETURN v_booking;
END;
$$;

DROP FUNCTION IF EXISTS public.create_open_service_request(
  text, text, text, text, timestamptz, text, numeric, numeric, jsonb
);

REVOKE ALL ON FUNCTION public.create_open_service_request(
  text, text, text, text, timestamptz, text, numeric, numeric, jsonb, uuid
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_open_service_request(
  text, text, text, text, timestamptz, text, numeric, numeric, jsonb, uuid
) TO authenticated;
