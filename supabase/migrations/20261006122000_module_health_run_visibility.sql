-- T2.3 follow-up: expose probe-run capability from module.health_run.

CREATE OR REPLACE FUNCTION public.list_technical_module_health_probes(
  p_module_key text
)
RETURNS TABLE (
  probe_key text,
  name text,
  description text,
  probe_kind text,
  stale_after_seconds integer,
  is_required boolean,
  is_enabled boolean,
  current_status text,
  current_summary text,
  observed_at timestamptz,
  is_stale boolean,
  can_run boolean
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF NOT public.has_technical_permission(
    p_module_key, 'module.view', auth.uid()
  ) THEN
    RAISE EXCEPTION 'Technical module view permission required';
  END IF;

  RETURN QUERY
  SELECT
    probe.probe_key,
    probe.name,
    probe.description,
    probe.probe_kind,
    probe.stale_after_seconds,
    probe.is_required,
    probe.is_enabled,
    CASE
      WHEN report.observed_at IS NULL THEN 'unknown'
      WHEN probe.stale_after_seconds IS NOT NULL
       AND report.observed_at
             + make_interval(secs => probe.stale_after_seconds) < now()
        THEN 'unknown'
      ELSE report.status
    END AS current_status,
    report.summary,
    report.observed_at,
    (
      report.observed_at IS NULL
      OR (
        probe.stale_after_seconds IS NOT NULL
        AND report.observed_at
              + make_interval(secs => probe.stale_after_seconds) < now()
      )
    ) AS is_stale,
    public.has_technical_permission(
      p_module_key, 'module.health_run', auth.uid()
    ) AS can_run
  FROM public.technical_module_health_probes probe
  LEFT JOIN public.technical_module_health_reports report
    ON report.module_key = probe.module_key
   AND report.probe_key = probe.probe_key
  WHERE probe.module_key = p_module_key
  ORDER BY probe.is_required DESC, probe.probe_key;
END;
$$;

REVOKE ALL ON FUNCTION public.list_technical_module_health_probes(text)
FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.list_technical_module_health_probes(text)
TO authenticated;
