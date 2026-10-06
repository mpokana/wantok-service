-- Wantok Service T2.1: technical staff and module-access management.
-- Exposes only controlled RPCs required by the Technical Control Panel.
-- auth.users remains private and no raw user directory is granted to clients.

CREATE OR REPLACE FUNCTION public.can_manage_technical_module_access(
  p_module_key text,
  p_user_id uuid DEFAULT auth.uid()
)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT
    p_user_id IS NOT NULL
    AND EXISTS (
      SELECT 1
      FROM public.technical_modules module
      WHERE module.module_key = p_module_key
    )
    AND (
      public.is_technical_platform_admin(p_user_id)
      OR public.has_technical_permission(
        p_module_key,
        'module.permissions',
        p_user_id
      )
    );
$$;

CREATE OR REPLACE FUNCTION public.list_assignable_technical_access_levels(
  p_module_key text
)
RETURNS TABLE (
  code text,
  name text,
  description text,
  rank integer
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_actor_level text;
  v_actor_rank integer;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF NOT public.can_manage_technical_module_access(
    p_module_key,
    auth.uid()
  ) THEN
    RAISE EXCEPTION 'Technical module access administration not permitted';
  END IF;

  IF public.is_technical_platform_admin(auth.uid()) THEN
    RETURN QUERY
    SELECT
      level.code,
      level.name,
      level.description,
      level.rank
    FROM public.technical_access_levels level
    ORDER BY level.rank DESC;
    RETURN;
  END IF;

  v_actor_level := public.effective_technical_access_level(
    p_module_key,
    auth.uid()
  );

  SELECT level.rank
  INTO v_actor_rank
  FROM public.technical_access_levels level
  WHERE level.code = v_actor_level;

  IF v_actor_rank IS NULL THEN
    RAISE EXCEPTION 'Technical module access administration not permitted';
  END IF;

  RETURN QUERY
  SELECT
    level.code,
    level.name,
    level.description,
    level.rank
  FROM public.technical_access_levels level
  WHERE level.rank < v_actor_rank
  ORDER BY level.rank DESC;
END;
$$;

CREATE OR REPLACE FUNCTION public.list_technical_module_staff(
  p_module_key text
)
RETURNS TABLE (
  user_id uuid,
  full_name text,
  email text,
  access_level_code text,
  access_level_name text,
  access_rank integer,
  granted_by uuid,
  granted_by_name text,
  granted_at timestamptz,
  expires_at timestamptz,
  notes text
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

  IF NOT public.can_manage_technical_module_access(
    p_module_key,
    auth.uid()
  ) THEN
    RAISE EXCEPTION 'Technical module access administration not permitted';
  END IF;

  RETURN QUERY
  SELECT
    access.user_id,
    profile.full_name,
    account.email::text,
    access.access_level_code,
    level.name,
    level.rank,
    access.granted_by,
    grantor.full_name,
    access.granted_at,
    access.expires_at,
    access.notes
  FROM public.technical_user_module_access access
  JOIN public.profiles profile
    ON profile.id = access.user_id
  LEFT JOIN auth.users account
    ON account.id = access.user_id
  JOIN public.technical_access_levels level
    ON level.code = access.access_level_code
  LEFT JOIN public.profiles grantor
    ON grantor.id = access.granted_by
  WHERE access.module_key = p_module_key
    AND (
      access.expires_at IS NULL
      OR access.expires_at > now()
    )
  ORDER BY
    level.rank DESC,
    lower(profile.full_name),
    access.user_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.search_technical_accounts(
  p_module_key text,
  p_query text
)
RETURNS TABLE (
  user_id uuid,
  full_name text,
  email text,
  current_access_level_code text,
  current_access_level_name text,
  is_platform_admin boolean
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_query text := btrim(coalesce(p_query, ''));
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF NOT public.can_manage_technical_module_access(
    p_module_key,
    auth.uid()
  ) THEN
    RAISE EXCEPTION 'Technical module access administration not permitted';
  END IF;

  IF char_length(v_query) < 2 THEN
    RAISE EXCEPTION 'Search requires at least 2 characters';
  END IF;

  RETURN QUERY
  SELECT
    profile.id,
    profile.full_name,
    account.email::text,
    access.access_level_code,
    level.name,
    public.is_technical_platform_admin(profile.id)
  FROM public.profiles profile
  JOIN auth.users account
    ON account.id = profile.id
  LEFT JOIN public.technical_user_module_access access
    ON access.user_id = profile.id
   AND access.module_key = p_module_key
   AND (
     access.expires_at IS NULL
     OR access.expires_at > now()
   )
  LEFT JOIN public.technical_access_levels level
    ON level.code = access.access_level_code
  WHERE
    lower(profile.full_name) LIKE '%' || lower(v_query) || '%'
    OR lower(coalesce(account.email, '')) LIKE '%' || lower(v_query) || '%'
  ORDER BY
    CASE
      WHEN lower(coalesce(account.email, '')) = lower(v_query) THEN 0
      WHEN lower(profile.full_name) = lower(v_query) THEN 1
      ELSE 2
    END,
    lower(profile.full_name),
    profile.id
  LIMIT 20;
END;
$$;

-- Refine the existing grant path so global Technical Platform Administrators
-- are never converted into redundant module assignments.
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

    IF v_actor_rank IS NULL
       OR NOT public.has_technical_permission(
         p_module_key,
         'module.permissions',
         auth.uid()
       )
       OR v_target_rank >= v_actor_rank THEN
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

REVOKE ALL ON FUNCTION public.can_manage_technical_module_access(
  text, uuid
) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.list_assignable_technical_access_levels(
  text
) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.list_technical_module_staff(
  text
) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.search_technical_accounts(
  text, text
) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.can_manage_technical_module_access(
  text, uuid
) TO authenticated;
GRANT EXECUTE ON FUNCTION public.list_assignable_technical_access_levels(
  text
) TO authenticated;
GRANT EXECUTE ON FUNCTION public.list_technical_module_staff(
  text
) TO authenticated;
GRANT EXECUTE ON FUNCTION public.search_technical_accounts(
  text, text
) TO authenticated;
