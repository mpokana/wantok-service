-- Wantok Service Events and ticketing core.
-- Approved Events provider services act as organiser identities.

CREATE TABLE public.events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id uuid NOT NULL REFERENCES public.provider_profiles(provider_id) ON DELETE CASCADE,
  provider_service_id uuid NOT NULL REFERENCES public.provider_services(id) ON DELETE CASCADE,
  title text NOT NULL CHECK (char_length(trim(title)) >= 3),
  description text,
  venue_name text,
  venue_address text,
  venue_lat double precision CHECK (venue_lat IS NULL OR venue_lat BETWEEN -90 AND 90),
  venue_lng double precision CHECK (venue_lng IS NULL OR venue_lng BETWEEN -180 AND 180),
  starts_at timestamptz NOT NULL,
  ends_at timestamptz,
  capacity integer CHECK (capacity IS NULL OR capacity > 0),
  status text NOT NULL DEFAULT 'draft'
    CHECK (status IN ('draft', 'published', 'cancelled', 'completed')),
  image_url text,
  is_featured boolean NOT NULL DEFAULT false,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (ends_at IS NULL OR ends_at > starts_at)
);

CREATE INDEX events_status_start_idx
  ON public.events (status, starts_at);
CREATE INDEX events_provider_idx
  ON public.events (provider_id, starts_at DESC);

CREATE TABLE public.event_ticket_types (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id uuid NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
  name text NOT NULL CHECK (char_length(trim(name)) >= 2),
  description text,
  price numeric(12,2) NOT NULL DEFAULT 0 CHECK (price >= 0),
  currency text NOT NULL DEFAULT 'PGK' CHECK (char_length(currency) = 3),
  capacity integer CHECK (capacity IS NULL OR capacity > 0),
  sales_start timestamptz,
  sales_end timestamptz,
  is_active boolean NOT NULL DEFAULT true,
  sort_order integer NOT NULL DEFAULT 0,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (sales_end IS NULL OR sales_start IS NULL OR sales_end > sales_start)
);

CREATE INDEX event_ticket_types_event_idx
  ON public.event_ticket_types (event_id, is_active, sort_order, name);

CREATE TABLE public.event_registrations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id uuid NOT NULL REFERENCES public.events(id) ON DELETE RESTRICT,
  ticket_type_id uuid NOT NULL REFERENCES public.event_ticket_types(id) ON DELETE RESTRICT,
  customer_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  quantity integer NOT NULL CHECK (quantity > 0),
  unit_price numeric(12,2) NOT NULL CHECK (unit_price >= 0),
  total_amount numeric(12,2) NOT NULL CHECK (total_amount >= 0),
  currency text NOT NULL DEFAULT 'PGK' CHECK (char_length(currency) = 3),
  status text NOT NULL DEFAULT 'reserved'
    CHECK (status IN ('reserved', 'cancelled', 'checked_in')),
  payment_status text NOT NULL DEFAULT 'unpaid'
    CHECK (payment_status IN ('unpaid', 'paid', 'refunded', 'not_required')),
  attendee_name text,
  attendee_contact text,
  note text,
  registered_at timestamptz NOT NULL DEFAULT now(),
  cancelled_at timestamptz,
  checked_in_at timestamptz,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX event_registrations_customer_idx
  ON public.event_registrations (customer_id, created_at DESC);
CREATE INDEX event_registrations_event_status_idx
  ON public.event_registrations (event_id, status, created_at);
CREATE INDEX event_registrations_ticket_status_idx
  ON public.event_registrations (ticket_type_id, status, created_at);

CREATE TRIGGER events_set_updated_at
BEFORE UPDATE ON public.events
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER event_ticket_types_set_updated_at
BEFORE UPDATE ON public.event_ticket_types
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER event_registrations_set_updated_at
BEFORE UPDATE ON public.event_registrations
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_ticket_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_registrations ENABLE ROW LEVEL SECURITY;

GRANT SELECT ON public.events TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON public.events TO authenticated;
GRANT SELECT ON public.event_ticket_types TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON public.event_ticket_types TO authenticated;
GRANT SELECT ON public.event_registrations TO authenticated;

REVOKE INSERT, UPDATE, DELETE ON public.event_registrations FROM anon, authenticated;

CREATE POLICY events_public_read
ON public.events
FOR SELECT
TO anon
USING (
  status = 'published'
  AND EXISTS (
    SELECT 1
    FROM public.provider_services AS ps
    JOIN public.service_categories AS sc ON sc.id = ps.category_id
    JOIN public.provider_profiles AS pp ON pp.provider_id = ps.provider_id
    WHERE ps.id = events.provider_service_id
      AND ps.provider_id = events.provider_id
      AND ps.status = 'active'
      AND sc.slug = 'events'
      AND sc.booking_mode = 'ticketing'
      AND pp.verification_status = 'verified'
      AND pp.is_active = true
  )
);

CREATE POLICY events_authenticated_read
ON public.events
FOR SELECT
TO authenticated
USING (
  provider_id = auth.uid()
  OR public.is_admin(auth.uid())
  OR public.has_role('operations', auth.uid())
  OR status = 'published'
);

CREATE POLICY events_insert_own
ON public.events
FOR INSERT
TO authenticated
WITH CHECK (
  provider_id = auth.uid()
  AND EXISTS (
    SELECT 1
    FROM public.provider_services AS ps
    JOIN public.service_categories AS sc ON sc.id = ps.category_id
    JOIN public.provider_profiles AS pp ON pp.provider_id = ps.provider_id
    WHERE ps.id = events.provider_service_id
      AND ps.provider_id = auth.uid()
      AND sc.slug = 'events'
      AND sc.booking_mode = 'ticketing'
      AND pp.verification_status = 'verified'
      AND pp.is_active = true
  )
);

CREATE POLICY events_update_own
ON public.events
FOR UPDATE
TO authenticated
USING (provider_id = auth.uid() OR public.is_admin(auth.uid()))
WITH CHECK (provider_id = auth.uid() OR public.is_admin(auth.uid()));

CREATE POLICY events_delete_own
ON public.events
FOR DELETE
TO authenticated
USING (provider_id = auth.uid() OR public.is_admin(auth.uid()));

CREATE POLICY event_ticket_types_public_read
ON public.event_ticket_types
FOR SELECT
TO anon
USING (
  is_active = true
  AND EXISTS (
    SELECT 1
    FROM public.events AS e
    WHERE e.id = event_ticket_types.event_id
      AND e.status = 'published'
  )
);

CREATE POLICY event_ticket_types_authenticated_read
ON public.event_ticket_types
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.events AS e
    WHERE e.id = event_ticket_types.event_id
      AND (
        e.status = 'published'
        OR e.provider_id = auth.uid()
        OR public.is_admin(auth.uid())
        OR public.has_role('operations', auth.uid())
      )
  )
);

CREATE POLICY event_ticket_types_insert_own
ON public.event_ticket_types
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.events AS e
    WHERE e.id = event_ticket_types.event_id
      AND (e.provider_id = auth.uid() OR public.is_admin(auth.uid()))
  )
);

CREATE POLICY event_ticket_types_update_own
ON public.event_ticket_types
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.events AS e
    WHERE e.id = event_ticket_types.event_id
      AND (e.provider_id = auth.uid() OR public.is_admin(auth.uid()))
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.events AS e
    WHERE e.id = event_ticket_types.event_id
      AND (e.provider_id = auth.uid() OR public.is_admin(auth.uid()))
  )
);

CREATE POLICY event_ticket_types_delete_own
ON public.event_ticket_types
FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.events AS e
    WHERE e.id = event_ticket_types.event_id
      AND (e.provider_id = auth.uid() OR public.is_admin(auth.uid()))
  )
);

CREATE POLICY event_registrations_participant_read
ON public.event_registrations
FOR SELECT
TO authenticated
USING (
  customer_id = auth.uid()
  OR EXISTS (
    SELECT 1
    FROM public.events AS e
    WHERE e.id = event_registrations.event_id
      AND e.provider_id = auth.uid()
  )
  OR public.is_admin(auth.uid())
  OR public.has_role('operations', auth.uid())
  OR public.has_role('support', auth.uid())
  OR public.has_role('finance', auth.uid())
);

CREATE OR REPLACE FUNCTION public.register_for_event(
  p_event_id uuid,
  p_ticket_type_id uuid,
  p_quantity integer DEFAULT 1,
  p_attendee_name text DEFAULT NULL,
  p_attendee_contact text DEFAULT NULL,
  p_note text DEFAULT NULL
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
    note
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
    NULLIF(trim(p_attendee_name), ''),
    NULLIF(trim(p_attendee_contact), ''),
    NULLIF(trim(p_note), '')
  )
  RETURNING * INTO v_registration;

  RETURN v_registration;
END;
$$;

REVOKE ALL ON FUNCTION public.register_for_event(
  uuid, uuid, integer, text, text, text
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.register_for_event(
  uuid, uuid, integer, text, text, text
) TO authenticated;

CREATE OR REPLACE FUNCTION public.cancel_event_registration(
  p_registration_id uuid
)
RETURNS public.event_registrations
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_registration public.event_registrations%ROWTYPE;
  v_event public.events%ROWTYPE;
BEGIN
  SELECT *
  INTO v_registration
  FROM public.event_registrations
  WHERE id = p_registration_id
    AND customer_id = auth.uid()
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Event registration not found';
  END IF;

  SELECT * INTO v_event
  FROM public.events
  WHERE id = v_registration.event_id;

  IF v_registration.status <> 'reserved' THEN
    RAISE EXCEPTION 'Registration can no longer be cancelled';
  END IF;

  IF v_event.starts_at <= now() THEN
    RAISE EXCEPTION 'Event has already started';
  END IF;

  UPDATE public.event_registrations
  SET status = 'cancelled',
      cancelled_at = now()
  WHERE id = p_registration_id
  RETURNING * INTO v_registration;

  RETURN v_registration;
END;
$$;

REVOKE ALL ON FUNCTION public.cancel_event_registration(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.cancel_event_registration(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.vendor_set_event_registration_status(
  p_registration_id uuid,
  p_status text
)
RETURNS public.event_registrations
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_target text := lower(trim(COALESCE(p_status, '')));
  v_registration public.event_registrations%ROWTYPE;
BEGIN
  SELECT er.*
  INTO v_registration
  FROM public.event_registrations AS er
  JOIN public.events AS e ON e.id = er.event_id
  WHERE er.id = p_registration_id
    AND (
      e.provider_id = auth.uid()
      OR public.is_admin(auth.uid())
      OR public.has_role('operations', auth.uid())
    )
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Event registration not found';
  END IF;

  IF NOT (
    (v_registration.status = 'reserved' AND v_target IN ('checked_in', 'cancelled'))
  ) THEN
    RAISE EXCEPTION 'Invalid event registration status transition';
  END IF;

  UPDATE public.event_registrations
  SET status = v_target,
      checked_in_at = CASE WHEN v_target = 'checked_in' THEN now() ELSE checked_in_at END,
      cancelled_at = CASE WHEN v_target = 'cancelled' THEN now() ELSE cancelled_at END
  WHERE id = p_registration_id
  RETURNING * INTO v_registration;

  RETURN v_registration;
END;
$$;

REVOKE ALL ON FUNCTION public.vendor_set_event_registration_status(uuid, text)
FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.vendor_set_event_registration_status(uuid, text)
TO authenticated;

ALTER TABLE public.events REPLICA IDENTITY FULL;
ALTER TABLE public.event_registrations REPLICA IDENTITY FULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'events'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.events;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'event_registrations'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.event_registrations;
  END IF;
END;
$$;
