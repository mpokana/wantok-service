-- T2.3 privacy follow-up: do not reveal dependency descriptions
-- for modules outside the caller's visible technical scope.

CREATE OR REPLACE FUNCTION public.list_technical_module_dependencies(
  p_module_key text
)
RETURNS TABLE (
  dependency_module_key text,
  dependency_name text,
  is_visible boolean,
  dependency_type text,
  failure_effect text,
  description text,
  is_enabled boolean,
  maintenance_mode boolean,
  reported_status text,
  effective_status text,
  last_report_at timestamptz
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
    CASE WHEN visible.can_see THEN dependency.depends_on_module_key ELSE NULL END,
    CASE WHEN visible.can_see THEN dependency_module.name ELSE NULL END,
    visible.can_see,
    dependency.dependency_type,
    dependency.failure_effect,
    CASE WHEN visible.can_see THEN dependency.description ELSE NULL END,
    CASE WHEN visible.can_see THEN dependency_module.is_enabled ELSE NULL END,
    CASE WHEN visible.can_see THEN dependency_module.maintenance_mode ELSE NULL END,
    CASE
      WHEN visible.can_see
        THEN public.technical_module_reported_health(
          dependency.depends_on_module_key
        )
      ELSE NULL
    END,
    CASE
      WHEN visible.can_see
        THEN public.technical_module_effective_health(
          dependency.depends_on_module_key
        )
      ELSE NULL
    END,
    CASE
      WHEN visible.can_see
        THEN public.technical_module_last_health_at(
          dependency.depends_on_module_key
        )
      ELSE NULL
    END
  FROM public.technical_module_dependencies dependency
  JOIN public.technical_modules dependency_module
    ON dependency_module.module_key = dependency.depends_on_module_key
  CROSS JOIN LATERAL (
    SELECT (
      public.is_technical_platform_admin(auth.uid())
      OR public.has_technical_permission(
        dependency.depends_on_module_key,
        'module.view',
        auth.uid()
      )
    ) AS can_see
  ) visible
  WHERE dependency.module_key = p_module_key
  ORDER BY
    dependency.dependency_type DESC,
    dependency_module.group_code,
    dependency_module.sort_order,
    dependency.depends_on_module_key;
END;
$$;

REVOKE ALL ON FUNCTION public.list_technical_module_dependencies(text)
FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.list_technical_module_dependencies(text)
TO authenticated;
