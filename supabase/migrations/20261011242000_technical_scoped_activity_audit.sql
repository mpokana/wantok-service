-- T2.4: privacy-minimised, module-scoped read adapter for existing audit_events.
-- This is technical change-history provenance, NOT central application logging.
-- Deliberately excludes actor, target, UUID, request ID, all metadata and raw text.
CREATE OR REPLACE FUNCTION public.list_technical_module_activity(
  p_module_key text,
  p_limit integer DEFAULT 30
)
RETURNS TABLE (
  id bigint,
  occurred_at timestamptz,
  action_code text
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
    RAISE EXCEPTION 'Technical module activity permission required';
  END IF;

  RETURN QUERY
  SELECT
    evt.id,
    evt.occurred_at,
    evt.action AS action_code
  FROM public.audit_events AS evt
  WHERE (evt.metadata ->> 'module_key') = p_module_key
    AND (
      (evt.action = 'technical_module_state_changed'
       AND evt.entity_type = 'technical_module')
      OR (evt.action = 'technical_module_configuration_changed'
       AND evt.entity_type = 'technical_module_configuration')
      OR (evt.action IN (
            'technical_module_access_granted',
            'technical_module_access_revoked'
          )
          AND evt.entity_type = 'technical_module_access')
    )
  ORDER BY evt.occurred_at DESC, evt.id DESC
  LIMIT GREATEST(1, LEAST(COALESCE(p_limit, 30), 30));
END;
$function$;

REVOKE ALL ON FUNCTION public.list_technical_module_activity(text, integer)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.list_technical_module_activity(text, integer)
  TO authenticated;

COMMENT ON FUNCTION public.list_technical_module_activity(text, integer) IS
  'Read-only bounded per-module Technical change-action audit, requires module.view AND module.logs. Only id, UTC-able timestamp and allowlisted action; no people, targets, raw metadata or operational audit records.';
