-- T2.1 hardening: prevent a module-scoped technical administrator from
-- overwriting/downgrading an equal or higher existing assignment.

CREATE OR REPLACE FUNCTION public.grant_technical_module_access(
  p_user_id uuid,
  p_module_key text,
  p_access_level_code text,
  p_expires_at timestamptz DEFAULT NULL,
  p_notes text DEFAULT NULL
)
RETURNS public.technical_user_module_access
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_actor_level text;
  v_actor_rank integer;
  v_target_rank integer;
  v_existing_rank integer;
  v_access public.technical_user_module_access%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF p_expires_at IS NOT NULL AND p_expires_at <= now() THEN
    RAISE EXCEPTION 'Technical access expiry must be in the future';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.profiles WHERE id = p_user_id
  ) THEN
    RAISE EXCEPTION 'Target user not found';
  END IF;

  IF public.is_technical_platform_admin(p_user_id) THEN
    RAISE EXCEPTION 'Technical Platform Administrators do not require module assignments';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.technical_modules
    WHERE module_key = p_module_key
  ) THEN
    RAISE EXCEPTION 'Technical module not found';
  END IF;

  SELECT level.rank
  INTO v_target_rank
  FROM public.technical_access_levels level
  WHERE level.code = p_access_level_code;

  IF v_target_rank IS NULL THEN
    RAISE EXCEPTION 'Unknown technical access level';
  END IF;

  IF NOT public.is_technical_platform_admin(auth.uid()) THEN
    v_actor_level := public.effective_technical_access_level(
      p_module_key,
      auth.uid()
    );

    SELECT level.rank
    INTO v_actor_rank
    FROM public.technical_access_levels level
    WHERE level.code = v_actor_level;

    SELECT level.rank
    INTO v_existing_rank
    FROM public.technical_user_module_access access
    JOIN public.technical_access_levels level
      ON level.code = access.access_level_code
    WHERE access.user_id = p_user_id
      AND access.module_key = p_module_key
      AND (
        access.expires_at IS NULL
        OR access.expires_at > now()
      );

    IF v_actor_rank IS NULL
       OR NOT public.has_technical_permission(
         p_module_key,
         'module.permissions',
         auth.uid()
       )
       OR v_target_rank >= v_actor_rank
       OR (
         v_existing_rank IS NOT NULL
         AND v_existing_rank >= v_actor_rank
       ) THEN
      RAISE EXCEPTION 'Technical module access administration not permitted';
    END IF;
  END IF;

  INSERT INTO public.technical_user_module_access (
    user_id,
    module_key,
    access_level_code,
    granted_by,
    expires_at,
    notes
  )
  VALUES (
    p_user_id,
    p_module_key,
    p_access_level_code,
    auth.uid(),
    p_expires_at,
    nullif(btrim(coalesce(p_notes, '')), '')
  )
  ON CONFLICT (user_id, module_key) DO UPDATE
  SET
    access_level_code = excluded.access_level_code,
    granted_by = excluded.granted_by,
    granted_at = now(),
    expires_at = excluded.expires_at,
    notes = excluded.notes
  RETURNING * INTO v_access;

  PERFORM public.write_audit_event(
    'technical_module_access_granted',
    'technical_module_access',
    p_user_id,
    jsonb_build_object(
      'module_key', p_module_key,
      'access_level', p_access_level_code,
      'expires_at', p_expires_at
    ),
    auth.uid()
  );

  RETURN v_access;
END;
$$;
