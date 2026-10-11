-- T2.4: real, aggregate-only notification-outbox queue observation.
-- NOT a job runner, consumer-health probe, or recipient/message search.
-- Adapter scope is explicitly restricted to the Messaging technical module.
CREATE OR REPLACE FUNCTION public.get_technical_messaging_queue_snapshot(
  p_module_key text
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $function$
DECLARE
  v_counts record;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF p_module_key IS DISTINCT FROM 'core.messaging' THEN
    RAISE EXCEPTION 'Queue adapter not available for this module';
  END IF;

  IF NOT (
    public.has_technical_permission(p_module_key, 'module.view', auth.uid())
    AND public.has_technical_permission(p_module_key, 'module.jobs', auth.uid())
  ) THEN
    RAISE EXCEPTION 'Technical module jobs permission required';
  END IF;

  SELECT
    count(*)::bigint AS total,
    count(*) FILTER (WHERE status = 'pending')::bigint AS pending,
    count(*) FILTER (WHERE status = 'processing')::bigint AS processing,
    count(*) FILTER (WHERE status = 'sent')::bigint AS sent,
    count(*) FILTER (WHERE status = 'failed')::bigint AS failed,
    count(*) FILTER (WHERE status = 'cancelled')::bigint AS cancelled,
    max(updated_at) AS last_activity_at
  INTO v_counts
  FROM public.notification_outbox;

  RETURN jsonb_build_object(
    'module_key', 'core.messaging',
    'adapter_key', 'notification_outbox_status',
    'observed_at', now(),
    'last_activity_at', v_counts.last_activity_at,
    'total', v_counts.total,
    'pending', v_counts.pending,
    'processing', v_counts.processing,
    'sent', v_counts.sent,
    'failed', v_counts.failed,
    'cancelled', v_counts.cancelled
  );
END;
$function$;

REVOKE ALL ON FUNCTION public.get_technical_messaging_queue_snapshot(text)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_technical_messaging_queue_snapshot(text)
  TO authenticated;

COMMENT ON FUNCTION public.get_technical_messaging_queue_snapshot(text)
  IS 'T2.4 read-only core.messaging notification outbox status aggregates, module.view plus module.jobs. No recipient, message payload, worker-health claim or execution.';
