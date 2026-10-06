-- CX1I foundation: Wantok AI Agent capability contract and human hand-off queue.
-- No model provider is enabled here. Wantok Services remains authoritative for
-- identity, provider approval, bookings, orders, payments and roles.

CREATE TABLE public.ai_agent_handoff_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  summary text NOT NULL
    CHECK (char_length(btrim(summary)) BETWEEN 1 AND 4000),
  context jsonb NOT NULL DEFAULT '{}'::jsonb
    CHECK (jsonb_typeof(context) = 'object'),
  status text NOT NULL DEFAULT 'open'
    CHECK (status IN ('open', 'assigned', 'resolved', 'closed')),
  assigned_to uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  resolution_note text
    CHECK (resolution_note IS NULL OR char_length(resolution_note) <= 4000),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  resolved_at timestamptz
);

CREATE INDEX ai_agent_handoff_user_created_idx
  ON public.ai_agent_handoff_requests (user_id, created_at DESC);
CREATE INDEX ai_agent_handoff_status_created_idx
  ON public.ai_agent_handoff_requests (status, created_at);

CREATE TRIGGER ai_agent_handoff_requests_set_updated_at
BEFORE UPDATE ON public.ai_agent_handoff_requests
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.ai_agent_handoff_requests ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.ai_agent_handoff_requests FROM anon, authenticated;
GRANT SELECT ON TABLE public.ai_agent_handoff_requests TO authenticated;
GRANT UPDATE (status, assigned_to, resolution_note, resolved_at)
  ON TABLE public.ai_agent_handoff_requests TO authenticated;

CREATE POLICY ai_agent_handoff_owner_read
ON public.ai_agent_handoff_requests
FOR SELECT
TO authenticated
USING (
  user_id = auth.uid()
  OR public.is_admin(auth.uid())
  OR public.has_role('support', auth.uid())
  OR public.has_role('operations', auth.uid())
);

CREATE POLICY ai_agent_handoff_staff_update
ON public.ai_agent_handoff_requests
FOR UPDATE
TO authenticated
USING (
  public.is_admin(auth.uid())
  OR public.has_role('support', auth.uid())
  OR public.has_role('operations', auth.uid())
)
WITH CHECK (
  public.is_admin(auth.uid())
  OR public.has_role('support', auth.uid())
  OR public.has_role('operations', auth.uid())
);

CREATE OR REPLACE FUNCTION public.get_wantok_ai_agent_capabilities()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'Authentication required';
  END IF;

  RETURN jsonb_build_object(
    'enabled', false,
    'chat_enabled', false,
    'provider_configured', false,
    'handoff_capture_enabled', true,
    'human_live_chat_enabled', false,
    'tools', jsonb_build_array(
      'provider_search',
      'service_search',
      'product_search',
      'listing_help',
      'booking_status'
    ),
    'restricted_actions', jsonb_build_array(
      'provider_approval',
      'payment_movement',
      'privileged_role_changes',
      'workflow_bypass'
    )
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.request_wantok_ai_handoff(
  p_summary text,
  p_context jsonb DEFAULT '{}'::jsonb
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_summary text := btrim(coalesce(p_summary, ''));
  v_context jsonb := coalesce(p_context, '{}'::jsonb);
  v_id uuid;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'Authentication required';
  END IF;

  IF char_length(v_summary) < 1 OR char_length(v_summary) > 4000 THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'Help request must contain 1 to 4000 characters';
  END IF;

  IF jsonb_typeof(v_context) <> 'object' THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'AI handoff context must be a JSON object';
  END IF;

  IF octet_length(v_context::text) > 16384 THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'AI handoff context is too large';
  END IF;

  INSERT INTO public.ai_agent_handoff_requests (
    user_id,
    summary,
    context
  ) VALUES (
    v_user_id,
    v_summary,
    v_context
  )
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;

REVOKE ALL ON FUNCTION public.get_wantok_ai_agent_capabilities() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_wantok_ai_agent_capabilities() FROM anon;
GRANT EXECUTE ON FUNCTION public.get_wantok_ai_agent_capabilities()
  TO authenticated;

REVOKE ALL ON FUNCTION public.request_wantok_ai_handoff(text, jsonb)
  FROM PUBLIC;
REVOKE ALL ON FUNCTION public.request_wantok_ai_handoff(text, jsonb)
  FROM anon;
GRANT EXECUTE ON FUNCTION public.request_wantok_ai_handoff(text, jsonb)
  TO authenticated;

COMMENT ON TABLE public.ai_agent_handoff_requests IS
  'Human-help requests created from the Wantok AI Agent surface. This table does not enable model chat.';
COMMENT ON FUNCTION public.get_wantok_ai_agent_capabilities() IS
  'Provider-agnostic Wantok AI Agent capability contract. Model chat remains disabled until a controlled gateway is configured.';
