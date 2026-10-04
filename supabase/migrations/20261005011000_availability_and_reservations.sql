-- Wantok Service availability and reservation integrity.

CREATE EXTENSION IF NOT EXISTS btree_gist WITH SCHEMA extensions;

CREATE TABLE public.provider_availability_rules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id uuid NOT NULL REFERENCES public.provider_profiles(provider_id) ON DELETE CASCADE,
  category_id uuid REFERENCES public.service_categories(id) ON DELETE CASCADE,
  resource_id uuid REFERENCES public.provider_resources(id) ON DELETE CASCADE,
  day_of_week smallint NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
  start_time time NOT NULL,
  end_time time NOT NULL,
  timezone text NOT NULL DEFAULT 'Pacific/Port_Moresby',
  effective_from date,
  effective_to date,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (end_time > start_time),
  CHECK (effective_to IS NULL OR effective_from IS NULL OR effective_to >= effective_from)
);

CREATE INDEX provider_availability_provider_idx
  ON public.provider_availability_rules (provider_id, day_of_week, is_active);
CREATE INDEX provider_availability_resource_idx
  ON public.provider_availability_rules (resource_id, day_of_week, is_active)
  WHERE resource_id IS NOT NULL;

CREATE TRIGGER provider_availability_rules_set_updated_at
BEFORE UPDATE ON public.provider_availability_rules
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TABLE public.provider_time_off (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id uuid NOT NULL REFERENCES public.provider_profiles(provider_id) ON DELETE CASCADE,
  resource_id uuid REFERENCES public.provider_resources(id) ON DELETE CASCADE,
  starts_at timestamptz NOT NULL,
  ends_at timestamptz NOT NULL,
  reason text,
  created_at timestamptz NOT NULL DEFAULT now(),
  CHECK (ends_at > starts_at)
);

CREATE INDEX provider_time_off_provider_idx
  ON public.provider_time_off (provider_id, starts_at, ends_at);
CREATE INDEX provider_time_off_resource_idx
  ON public.provider_time_off (resource_id, starts_at, ends_at)
  WHERE resource_id IS NOT NULL;

ALTER TABLE public.service_bookings
ADD CONSTRAINT service_bookings_no_resource_overlap
EXCLUDE USING gist (
  resource_id WITH =,
  tstzrange(scheduled_start, scheduled_end, '[)') WITH &&
)
WHERE (
  resource_id IS NOT NULL
  AND scheduled_start IS NOT NULL
  AND scheduled_end IS NOT NULL
  AND status IN ('confirmed', 'in_progress')
);

CREATE OR REPLACE FUNCTION public.is_resource_available(
  p_resource_id uuid,
  p_starts_at timestamptz,
  p_ends_at timestamptz,
  p_exclude_booking_id uuid DEFAULT NULL
)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    p_starts_at IS NOT NULL
    AND p_ends_at IS NOT NULL
    AND p_ends_at > p_starts_at
    AND EXISTS (
      SELECT 1 FROM public.provider_resources AS pr
      WHERE pr.id = p_resource_id
        AND pr.status = 'active'
    )
    AND NOT EXISTS (
      SELECT 1
      FROM public.service_bookings AS b
      WHERE b.resource_id = p_resource_id
        AND b.id IS DISTINCT FROM p_exclude_booking_id
        AND b.status IN ('confirmed', 'in_progress')
        AND tstzrange(b.scheduled_start, b.scheduled_end, '[)')
            && tstzrange(p_starts_at, p_ends_at, '[)')
    )
    AND NOT EXISTS (
      SELECT 1
      FROM public.provider_time_off AS pto
      WHERE (pto.resource_id = p_resource_id OR pto.resource_id IS NULL)
        AND pto.provider_id = (
          SELECT provider_id FROM public.provider_resources WHERE id = p_resource_id
        )
        AND tstzrange(pto.starts_at, pto.ends_at, '[)')
            && tstzrange(p_starts_at, p_ends_at, '[)')
    );
$$;

REVOKE ALL ON FUNCTION public.is_resource_available(uuid, timestamptz, timestamptz, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_resource_available(uuid, timestamptz, timestamptz, uuid)
  TO anon, authenticated;

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

  IF v_booking.status <> 'requested' THEN
    RAISE EXCEPTION 'Booking cannot be responded to in its current state';
  END IF;

  IF p_accept AND v_booking.resource_id IS NOT NULL THEN
    IF v_booking.scheduled_start IS NULL OR v_booking.scheduled_end IS NULL THEN
      RAISE EXCEPTION 'Resource bookings require a start and end time';
    END IF;

    IF NOT public.is_resource_available(
      v_booking.resource_id,
      v_booking.scheduled_start,
      v_booking.scheduled_end,
      v_booking.id
    ) THEN
      RAISE EXCEPTION 'Resource is not available for the requested time';
    END IF;
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

  SELECT * INTO v_booking
  FROM public.service_bookings
  WHERE id = v_quote.booking_id
  FOR UPDATE;

  IF v_booking.resource_id IS NOT NULL THEN
    IF v_booking.scheduled_start IS NULL OR v_booking.scheduled_end IS NULL THEN
      RAISE EXCEPTION 'Resource bookings require a start and end time';
    END IF;

    IF NOT public.is_resource_available(
      v_booking.resource_id,
      v_booking.scheduled_start,
      v_booking.scheduled_end,
      v_booking.id
    ) THEN
      RAISE EXCEPTION 'Resource is not available for the requested time';
    END IF;
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

ALTER TABLE public.provider_availability_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provider_time_off ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.provider_availability_rules FROM anon, authenticated;
REVOKE ALL ON TABLE public.provider_time_off FROM anon, authenticated;

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.provider_availability_rules TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.provider_time_off TO authenticated;

CREATE POLICY provider_availability_manage_own
ON public.provider_availability_rules
FOR ALL TO authenticated
USING (
  provider_id = auth.uid()
  OR public.is_admin(auth.uid())
  OR public.has_role('operations', auth.uid())
)
WITH CHECK (
  provider_id = auth.uid()
  OR public.is_admin(auth.uid())
  OR public.has_role('operations', auth.uid())
);

CREATE POLICY provider_time_off_manage_own
ON public.provider_time_off
FOR ALL TO authenticated
USING (
  provider_id = auth.uid()
  OR public.is_admin(auth.uid())
  OR public.has_role('operations', auth.uid())
)
WITH CHECK (
  provider_id = auth.uid()
  OR public.is_admin(auth.uid())
  OR public.has_role('operations', auth.uid())
);
