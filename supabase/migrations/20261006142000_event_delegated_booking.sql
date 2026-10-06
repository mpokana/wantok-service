-- CX1B delegated Events/ticketing registration.
-- The authenticated Wantok account remains event_registrations.customer_id
-- and therefore owns payment/cancellation authority. An optional active
-- Trusted person is snapshotted as the primary attendee.

ALTER TABLE public.event_registrations
  ADD COLUMN trusted_person_id uuid
    REFERENCES public.trusted_people(id) ON DELETE SET NULL,
  ADD COLUMN attendee_relationship text,
  ADD COLUMN attendee_phone text,
  ADD COLUMN attendee_email text;

CREATE INDEX event_registrations_customer_trusted_person_idx
  ON public.event_registrations (customer_id, trusted_person_id, created_at DESC)
  WHERE trusted_person_id IS NOT NULL;

COMMENT ON COLUMN public.event_registrations.trusted_person_id IS
  'Optional customer-owned Trusted person selected as primary attendee. ON DELETE SET NULL while attendee snapshot fields preserve history.';

COMMENT ON COLUMN public.event_registrations.attendee_relationship IS
  'Relationship snapshot copied from the selected Trusted person at registration time.';

COMMENT ON COLUMN public.event_registrations.attendee_phone IS
  'Primary attendee phone snapshot for event coordination/check-in.';

COMMENT ON COLUMN public.event_registrations.attendee_email IS
  'Primary attendee email snapshot for event coordination/check-in.';

CREATE OR REPLACE FUNCTION public.register_for_event(
  p_event_id uuid,
  p_ticket_type_id uuid,
  p_quantity integer DEFAULT 1,
  p_attendee_name text DEFAULT NULL,
  p_attendee_contact text DEFAULT NULL,
  p_note text DEFAULT NULL,
  p_trusted_person_id uuid DEFAULT NULL
)
RETURNS public.event_registrations
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_event public.events%ROWTYPE;
  v_ticket public.event_ticket_types%ROWTYPE;
  v_beneficiary public.trusted_people%ROWTYPE;
  v_event_reserved integer;
  v_ticket_reserved integer;
  v_registration public.event_registrations%ROWTYPE;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF p_quantity IS NULL OR p_quantity <= 0 OR p_quantity > 20 THEN
    RAISE EXCEPTION 'Registration quantity must be between 1 and 20';
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
  INTO v_event
  FROM public.events
  WHERE id = p_event_id
  FOR UPDATE;

  IF NOT FOUND OR v_event.status <> 'published' THEN
    RAISE EXCEPTION 'Event is not available for registration';
  END IF;

  IF v_event.starts_at <= now() THEN
    RAISE EXCEPTION 'Event registration has closed';
  END IF;

  SELECT *
  INTO v_ticket
  FROM public.event_ticket_types
  WHERE id = p_ticket_type_id
    AND event_id = v_event.id
  FOR UPDATE;

  IF NOT FOUND OR v_ticket.is_active = false THEN
    RAISE EXCEPTION 'Ticket type is not available';
  END IF;

  IF v_ticket.sales_start IS NOT NULL AND v_ticket.sales_start > now() THEN
    RAISE EXCEPTION 'Ticket sales have not started';
  END IF;

  IF v_ticket.sales_end IS NOT NULL AND v_ticket.sales_end <= now() THEN
    RAISE EXCEPTION 'Ticket sales have ended';
  END IF;

  SELECT COALESCE(sum(quantity), 0)::integer
  INTO v_event_reserved
  FROM public.event_registrations
  WHERE event_id = v_event.id
    AND status IN ('reserved', 'checked_in');

  IF v_event.capacity IS NOT NULL
     AND v_event_reserved + p_quantity > v_event.capacity THEN
    RAISE EXCEPTION 'Event capacity exceeded';
  END IF;

  SELECT COALESCE(sum(quantity), 0)::integer
  INTO v_ticket_reserved
  FROM public.event_registrations
  WHERE ticket_type_id = v_ticket.id
    AND status IN ('reserved', 'checked_in');

  IF v_ticket.capacity IS NOT NULL
     AND v_ticket_reserved + p_quantity > v_ticket.capacity THEN
    RAISE EXCEPTION 'Ticket type capacity exceeded';
  END IF;

  INSERT INTO public.event_registrations (
    event_id,
    ticket_type_id,
    customer_id,
    quantity,
    unit_price,
    total_amount,
    currency,
    status,
    payment_status,
    attendee_name,
    attendee_contact,
    attendee_relationship,
    attendee_phone,
    attendee_email,
    trusted_person_id,
    note,
    metadata
  )
  VALUES (
    v_event.id,
    v_ticket.id,
    v_user_id,
    p_quantity,
    v_ticket.price,
    round(v_ticket.price * p_quantity, 2),
    v_ticket.currency,
    'reserved',
    CASE WHEN v_ticket.price = 0 THEN 'not_required' ELSE 'unpaid' END,
    CASE
      WHEN p_trusted_person_id IS NULL THEN NULLIF(trim(p_attendee_name), '')
      ELSE v_beneficiary.display_name
    END,
    CASE
      WHEN p_trusted_person_id IS NULL THEN NULLIF(trim(p_attendee_contact), '')
      ELSE COALESCE(
        NULLIF(trim(v_beneficiary.phone), ''),
        NULLIF(trim(v_beneficiary.email), '')
      )
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
    END,
    p_trusted_person_id,
    NULLIF(trim(p_note), ''),
    jsonb_build_object(
      'source', 'wantok-flutter',
      'booked_for', CASE
        WHEN p_trusted_person_id IS NULL THEN 'self'
        ELSE 'trusted_person'
      END,
      'delegated_primary_attendee', (p_trusted_person_id IS NOT NULL)
    )
  )
  RETURNING * INTO v_registration;

  RETURN v_registration;
END;
$$;

DROP FUNCTION IF EXISTS public.register_for_event(
  uuid, uuid, integer, text, text, text
);

REVOKE ALL ON FUNCTION public.register_for_event(
  uuid, uuid, integer, text, text, text, uuid
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.register_for_event(
  uuid, uuid, integer, text, text, text, uuid
) TO authenticated;
