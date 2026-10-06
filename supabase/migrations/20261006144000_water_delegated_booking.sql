-- CX1B delegated scheduled Boat/Ship passenger booking.
-- The authenticated Wantok account remains the booking owner/payer.
-- An optional customer-owned Trusted person is snapshotted as the primary
-- passenger while the existing multi-passenger manifest remains intact.

ALTER TABLE public.water_passenger_bookings
  ADD COLUMN trusted_person_id uuid
    REFERENCES public.trusted_people(id) ON DELETE SET NULL,
  ADD COLUMN beneficiary_name text,
  ADD COLUMN beneficiary_relationship text,
  ADD COLUMN beneficiary_phone text,
  ADD COLUMN beneficiary_email text;

ALTER TABLE public.water_passenger_bookings
  ADD CONSTRAINT water_bookings_beneficiary_name_not_blank
  CHECK (
    beneficiary_name IS NULL
    OR NULLIF(trim(beneficiary_name), '') IS NOT NULL
  );

CREATE INDEX water_bookings_customer_trusted_person_idx
  ON public.water_passenger_bookings (
    customer_id,
    trusted_person_id,
    created_at DESC
  )
  WHERE trusted_person_id IS NOT NULL;

COMMENT ON COLUMN public.water_passenger_bookings.trusted_person_id IS
  'Optional customer-owned Trusted person selected as the primary passenger. ON DELETE SET NULL while beneficiary and manifest snapshots preserve history.';

COMMENT ON COLUMN public.water_passenger_bookings.beneficiary_name IS
  'Primary passenger name snapshot for delegated scheduled water transport. NULL means the booking uses only the manually entered manifest.';

CREATE OR REPLACE FUNCTION public.book_water_departure(
  p_departure_id uuid,
  p_fare_class_id uuid,
  p_passengers jsonb,
  p_contact_phone text DEFAULT NULL,
  p_note text DEFAULT NULL,
  p_trusted_person_id uuid DEFAULT NULL
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
  v_beneficiary public.trusted_people%ROWTYPE;
  v_passenger jsonb;
  v_ordinality bigint;
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

  FOR v_passenger, v_ordinality IN
    SELECT value, ordinality
    FROM jsonb_array_elements(p_passengers) WITH ORDINALITY
  LOOP
    v_name := CASE
      WHEN p_trusted_person_id IS NOT NULL AND v_ordinality = 1
        THEN v_beneficiary.display_name
      ELSE NULLIF(trim(v_passenger ->> 'full_name'), '')
    END;
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
    note,
    metadata,
    trusted_person_id,
    beneficiary_name,
    beneficiary_relationship,
    beneficiary_phone,
    beneficiary_email
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
    COALESCE(
      NULLIF(trim(p_contact_phone), ''),
      CASE
        WHEN p_trusted_person_id IS NULL THEN NULL
        ELSE NULLIF(trim(v_beneficiary.phone), '')
      END
    ),
    NULLIF(trim(p_note), ''),
    jsonb_build_object(
      'source', 'wantok-flutter',
      'booked_for', CASE
        WHEN p_trusted_person_id IS NULL THEN 'self'
        ELSE 'trusted_person'
      END
    ),
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
  RETURNING * INTO v_booking;

  FOR v_passenger, v_ordinality IN
    SELECT value, ordinality
    FROM jsonb_array_elements(p_passengers) WITH ORDINALITY
  LOOP
    INSERT INTO public.water_booking_passengers (
      booking_id,
      full_name,
      phone,
      passenger_type,
      document_reference,
      metadata
    )
    VALUES (
      v_booking.id,
      CASE
        WHEN p_trusted_person_id IS NOT NULL AND v_ordinality = 1
          THEN v_beneficiary.display_name
        ELSE trim(v_passenger ->> 'full_name')
      END,
      CASE
        WHEN p_trusted_person_id IS NOT NULL AND v_ordinality = 1
          THEN COALESCE(
            NULLIF(trim(v_beneficiary.phone), ''),
            NULLIF(trim(v_passenger ->> 'phone'), '')
          )
        ELSE NULLIF(trim(v_passenger ->> 'phone'), '')
      END,
      lower(trim(COALESCE(v_passenger ->> 'passenger_type', 'adult'))),
      NULLIF(trim(v_passenger ->> 'document_reference'), ''),
      CASE
        WHEN p_trusted_person_id IS NOT NULL AND v_ordinality = 1
          THEN jsonb_build_object(
            'trusted_person_primary', true,
            'trusted_person_relationship', v_beneficiary.relationship
          )
        ELSE '{}'::jsonb
      END
    );
  END LOOP;

  RETURN v_booking;
END;
$$;

DROP FUNCTION IF EXISTS public.book_water_departure(
  uuid, uuid, jsonb, text, text
);

REVOKE ALL ON FUNCTION public.book_water_departure(
  uuid, uuid, jsonb, text, text, uuid
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.book_water_departure(
  uuid, uuid, jsonb, text, text, uuid
) TO authenticated;
