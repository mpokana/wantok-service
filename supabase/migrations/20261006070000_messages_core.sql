-- Wantok Service booking-scoped client/provider messaging.

CREATE TABLE public.conversation_threads (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id uuid NOT NULL UNIQUE
    REFERENCES public.service_bookings(id) ON DELETE CASCADE,
  customer_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  provider_id uuid NOT NULL
    REFERENCES public.provider_profiles(provider_id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  last_message_at timestamptz,
  CONSTRAINT conversation_threads_distinct_participants
    CHECK (customer_id <> provider_id)
);

CREATE TABLE public.conversation_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  thread_id uuid NOT NULL
    REFERENCES public.conversation_threads(id) ON DELETE CASCADE,
  sender_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  body text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  read_at timestamptz,
  CONSTRAINT conversation_messages_body_length
    CHECK (char_length(btrim(body)) BETWEEN 1 AND 2000)
);

CREATE INDEX conversation_threads_customer_idx
  ON public.conversation_threads(customer_id, last_message_at DESC NULLS LAST);
CREATE INDEX conversation_threads_provider_idx
  ON public.conversation_threads(provider_id, last_message_at DESC NULLS LAST);
CREATE INDEX conversation_messages_thread_created_idx
  ON public.conversation_messages(thread_id, created_at);

ALTER TABLE public.conversation_threads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversation_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "conversation participants can read threads"
ON public.conversation_threads
FOR SELECT
TO authenticated
USING (auth.uid() = customer_id OR auth.uid() = provider_id);

CREATE POLICY "conversation participants can read messages"
ON public.conversation_messages
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.conversation_threads thread
    WHERE thread.id = conversation_messages.thread_id
      AND (thread.customer_id = auth.uid() OR thread.provider_id = auth.uid())
  )
);

REVOKE INSERT, UPDATE, DELETE ON public.conversation_threads
  FROM anon, authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.conversation_messages
  FROM anon, authenticated;
GRANT SELECT ON public.conversation_threads TO authenticated;
GRANT SELECT ON public.conversation_messages TO authenticated;

CREATE OR REPLACE FUNCTION public.ensure_booking_conversation(
  p_booking_id uuid
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_customer_id uuid;
  v_provider_id uuid;
  v_thread_id uuid;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'Authentication required';
  END IF;

  SELECT booking.customer_id, booking.provider_id
  INTO v_customer_id, v_provider_id
  FROM public.service_bookings booking
  WHERE booking.id = p_booking_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'Booking not found';
  END IF;

  IF v_provider_id IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'A provider must be assigned before messaging is available';
  END IF;

  IF v_user_id <> v_customer_id AND v_user_id <> v_provider_id THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'You are not a participant in this booking';
  END IF;

  INSERT INTO public.conversation_threads (
    booking_id,
    customer_id,
    provider_id
  ) VALUES (
    p_booking_id,
    v_customer_id,
    v_provider_id
  )
  ON CONFLICT (booking_id) DO NOTHING
  RETURNING id INTO v_thread_id;

  IF v_thread_id IS NULL THEN
    SELECT thread.id
    INTO v_thread_id
    FROM public.conversation_threads thread
    WHERE thread.booking_id = p_booking_id;
  END IF;

  RETURN v_thread_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.send_conversation_message(
  p_thread_id uuid,
  p_body text
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_body text := btrim(coalesce(p_body, ''));
  v_message_id uuid;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'Authentication required';
  END IF;

  IF char_length(v_body) < 1 THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'Message cannot be empty';
  END IF;

  IF char_length(v_body) > 2000 THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'Message cannot exceed 2000 characters';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.conversation_threads thread
    WHERE thread.id = p_thread_id
      AND (thread.customer_id = v_user_id OR thread.provider_id = v_user_id)
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'You are not a participant in this conversation';
  END IF;

  INSERT INTO public.conversation_messages (
    thread_id,
    sender_id,
    body
  ) VALUES (
    p_thread_id,
    v_user_id,
    v_body
  )
  RETURNING id INTO v_message_id;

  UPDATE public.conversation_threads
  SET
    updated_at = now(),
    last_message_at = now()
  WHERE id = p_thread_id;

  RETURN v_message_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.mark_conversation_read(
  p_thread_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_user_id uuid := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'Authentication required';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.conversation_threads thread
    WHERE thread.id = p_thread_id
      AND (thread.customer_id = v_user_id OR thread.provider_id = v_user_id)
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'You are not a participant in this conversation';
  END IF;

  UPDATE public.conversation_messages
  SET read_at = coalesce(read_at, now())
  WHERE thread_id = p_thread_id
    AND sender_id <> v_user_id
    AND read_at IS NULL;
END;
$$;

CREATE OR REPLACE FUNCTION public.list_my_booking_conversations()
RETURNS TABLE (
  thread_id uuid,
  booking_id uuid,
  other_user_id uuid,
  other_display_name text,
  category_name text,
  booking_status text,
  last_message text,
  last_message_at timestamptz,
  unread_count bigint
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT
    thread.id AS thread_id,
    thread.booking_id,
    CASE
      WHEN thread.customer_id = auth.uid() THEN thread.provider_id
      ELSE thread.customer_id
    END AS other_user_id,
    CASE
      WHEN thread.customer_id = auth.uid()
        THEN coalesce(provider.display_name, 'Provider')
      ELSE coalesce(
        nullif(customer.raw_user_meta_data ->> 'full_name', ''),
        nullif(split_part(customer.email, '@', 1), ''),
        'Customer'
      )
    END AS other_display_name,
    category.name AS category_name,
    booking.status AS booking_status,
    latest.body AS last_message,
    latest.created_at AS last_message_at,
    (
      SELECT count(*)
      FROM public.conversation_messages unread
      WHERE unread.thread_id = thread.id
        AND unread.sender_id <> auth.uid()
        AND unread.read_at IS NULL
    ) AS unread_count
  FROM public.conversation_threads thread
  JOIN public.service_bookings booking
    ON booking.id = thread.booking_id
  JOIN public.service_categories category
    ON category.id = booking.category_id
  LEFT JOIN public.provider_profiles provider
    ON provider.provider_id = thread.provider_id
  LEFT JOIN auth.users customer
    ON customer.id = thread.customer_id
  LEFT JOIN LATERAL (
    SELECT message.body, message.created_at
    FROM public.conversation_messages message
    WHERE message.thread_id = thread.id
    ORDER BY message.created_at DESC
    LIMIT 1
  ) latest ON true
  WHERE auth.uid() IS NOT NULL
    AND (thread.customer_id = auth.uid() OR thread.provider_id = auth.uid())
  ORDER BY coalesce(thread.last_message_at, thread.created_at) DESC;
$$;

REVOKE ALL ON FUNCTION public.ensure_booking_conversation(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.send_conversation_message(uuid, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.mark_conversation_read(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.list_my_booking_conversations() FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.ensure_booking_conversation(uuid)
  TO authenticated;
GRANT EXECUTE ON FUNCTION public.send_conversation_message(uuid, text)
  TO authenticated;
GRANT EXECUTE ON FUNCTION public.mark_conversation_read(uuid)
  TO authenticated;
GRANT EXECUTE ON FUNCTION public.list_my_booking_conversations()
  TO authenticated;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime'
  ) AND NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'conversation_messages'
  ) THEN
    EXECUTE 'ALTER PUBLICATION supabase_realtime ADD TABLE public.conversation_messages';
  END IF;
END;
$$;
