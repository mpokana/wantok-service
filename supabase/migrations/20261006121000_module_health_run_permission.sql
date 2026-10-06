-- T2.3 follow-up: separate read-only diagnostics from health-probe execution.

INSERT INTO public.technical_permissions (
  code, name, description, scope, risk_level
)
VALUES (
  'module.health_run',
  'Run health probes',
  'Run registered non-arbitrary module health probes.',
  'module',
  'operational'
)
ON CONFLICT (code) DO UPDATE
SET name = excluded.name,
    description = excluded.description,
    scope = excluded.scope,
    risk_level = excluded.risk_level;

INSERT INTO public.technical_access_level_permissions (
  access_level_code, permission_code
)
VALUES
  ('tech_support', 'module.health_run'),
  ('tech_module_admin', 'module.health_run'),
  ('tech_admin', 'module.health_run')
ON CONFLICT DO NOTHING;

CREATE OR REPLACE FUNCTION public.run_technical_module_health_probe(
  p_module_key text,
  p_probe_key text DEFAULT 'control.state'
)
RETURNS TABLE (
  module_key text,
  reported_status text,
  effective_status text,
  last_report_at timestamptz,
  last_evaluated_at timestamptz,
  summary text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_module public.technical_modules%ROWTYPE;
  v_probe public.technical_module_health_probes%ROWTYPE;
  v_status text;
  v_summary text;
  v_state public.technical_module_health_state%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF NOT public.has_technical_permission(
    p_module_key, 'module.health_run', auth.uid()
  ) THEN
    RAISE EXCEPTION 'Technical module health-run permission required';
  END IF;

  SELECT *
  INTO v_module
  FROM public.technical_modules
  WHERE technical_modules.module_key = p_module_key;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Technical module not found';
  END IF;

  SELECT *
  INTO v_probe
  FROM public.technical_module_health_probes
  WHERE technical_module_health_probes.module_key = p_module_key
    AND technical_module_health_probes.probe_key = p_probe_key
    AND technical_module_health_probes.is_enabled;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Technical module health probe not found or disabled';
  END IF;

  IF v_probe.probe_kind <> 'control_state' THEN
    RAISE EXCEPTION 'This health probe requires an external reporter adapter';
  END IF;

  IF NOT v_module.is_enabled THEN
    v_status := 'unknown';
    v_summary := 'Module is disabled; runtime health is not being asserted.';
  ELSIF v_module.maintenance_mode THEN
    v_status := 'degraded';
    v_summary := 'Module is in maintenance mode.';
  ELSE
    v_status := 'healthy';
    v_summary := 'Control-plane state is available.';
  END IF;

  v_state := public.record_technical_module_health_report_internal(
    p_module_key,
    p_probe_key,
    v_status,
    v_summary,
    jsonb_build_object(
      'is_enabled', v_module.is_enabled,
      'maintenance_mode', v_module.maintenance_mode,
      'probe_kind', v_probe.probe_kind
    ),
    now(),
    auth.uid()
  );

  RETURN QUERY
  SELECT
    v_state.module_key,
    v_state.reported_status,
    v_state.effective_status,
    v_state.last_report_at,
    v_state.last_evaluated_at,
    v_state.summary;
END;
$$;

REVOKE ALL ON FUNCTION public.run_technical_module_health_probe(text, text)
FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.run_technical_module_health_probe(text, text)
TO authenticated;
