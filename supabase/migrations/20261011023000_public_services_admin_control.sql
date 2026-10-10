-- Module control: public-services only. No unguarded catalogue writes.
-- RBAC is checked server-side even if a client bypasses the admin UI.
CREATE OR REPLACE FUNCTION public.admin_set_public_services_enabled(
  p_enabled boolean
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_row public.service_categories%ROWTYPE;
BEGIN
  IF p_enabled IS NULL THEN
    RAISE EXCEPTION 'Enabled state is required';
  END IF;
  IF auth.uid() IS NULL OR NOT public.is_admin(auth.uid()) THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  SELECT * INTO STRICT v_row
  FROM public.service_categories
  WHERE slug = 'public-services'
  FOR UPDATE;

  IF v_row.is_active IS DISTINCT FROM p_enabled THEN
    UPDATE public.service_categories
       SET is_active = p_enabled
     WHERE id = v_row.id;

    PERFORM public.write_audit_event(
      'public_services_visibility_changed',
      'service_category',
      v_row.id,
      jsonb_build_object(
        'slug', 'public-services',
        'previous_enabled', v_row.is_active,
        'enabled', p_enabled
      )
    );
  END IF;

  RETURN p_enabled;
EXCEPTION
  WHEN no_data_found THEN
    RAISE EXCEPTION 'Public Services category is not installed';
END;
$$;

REVOKE ALL ON FUNCTION public.admin_set_public_services_enabled(boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_set_public_services_enabled(boolean) TO authenticated;
