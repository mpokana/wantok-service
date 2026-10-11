-- T2.4: dedicated safe read adapter for module health transition logs.
-- Do NOT grant direct SELECT on health-history, audit or untrusted raw logs.
-- Narrower than the pre-existing module.view health-history RPC by design.
CREATE OR REPLACE FUNCTION public.list_technical_module_log_events(
  p_module_key text,
  p_limit integer DEFAULT 30
)
RETURNS TABLE (
  id bigint,
  previous_reported_status text,
  reported_status text,
  previous_effective_status text,
  effective_status text,
  transition_reason text,
  source_probe_key text,
  summary text,
  observed_at timestamptz,
  recorded_at timestamptz
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $function$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF NOT (
    public.has_technical_permission(p_module_key, 'module.view', auth.uid())
    AND public.has_technical_permission(p_module_key, 'module.logs', auth.uid())
  ) THEN
    RAISE EXCEPTION 'Technical module log permission required';
  END IF;

  RETURN QUERY
  SELECT
    history.id,
    history.previous_reported_status,
    history.reported_status,
    history.previous_effective_status,
    history.effective_status,
    CASE
      WHEN history.transition_reason ~ '^[a-z][a-z0-9_]{0,63}$'
        THEN history.transition_reason
      ELSE 'other_health_transition'
    END,
    NULL::text AS source_probe_key,
    NULL::text AS summary,
    history.observed_at,
    history.recorded_at
  FROM public.technical_module_health_history AS history
  WHERE history.module_key = p_module_key
  ORDER BY history.recorded_at DESC, history.id DESC
  LIMIT GREATEST(1, LEAST(COALESCE(p_limit, 30), 30));
END;
$function$;

REVOKE ALL ON FUNCTION public.list_technical_module_log_events(text, integer)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.list_technical_module_log_events(text, integer)
  TO authenticated;

COMMENT ON FUNCTION public.list_technical_module_log_events(text, integer)
  IS 'Read-only T2.4 health-transition log adapter: module.view AND module.logs, up to 30 rows, excludes summary/probe keys. Not a central log provider.';
