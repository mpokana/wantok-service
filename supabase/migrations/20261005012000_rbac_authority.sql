-- Make RBAC the authoritative authorization source while preserving legacy profile flags.

CREATE OR REPLACE FUNCTION public.is_admin(p_user_id uuid DEFAULT auth.uid())
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT public.has_role('admin', p_user_id);
$$;

REVOKE ALL ON FUNCTION public.is_admin(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_admin(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.sync_profile_roles()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.user_roles (user_id, role_code)
  VALUES (NEW.id, 'customer')
  ON CONFLICT (user_id, role_code) DO NOTHING;

  IF TG_OP = 'INSERT' THEN
    IF NEW.is_provider THEN
      INSERT INTO public.user_roles (user_id, role_code)
      VALUES (NEW.id, 'provider')
      ON CONFLICT (user_id, role_code) DO NOTHING;
    END IF;

    IF NEW.is_driver THEN
      INSERT INTO public.user_roles (user_id, role_code)
      VALUES (NEW.id, 'driver')
      ON CONFLICT (user_id, role_code) DO NOTHING;
    END IF;

    IF NEW.is_admin THEN
      INSERT INTO public.user_roles (user_id, role_code)
      VALUES (NEW.id, 'admin')
      ON CONFLICT (user_id, role_code) DO NOTHING;
    END IF;

    RETURN NEW;
  END IF;

  IF NEW.is_provider IS DISTINCT FROM OLD.is_provider THEN
    IF NEW.is_provider THEN
      INSERT INTO public.user_roles (user_id, role_code)
      VALUES (NEW.id, 'provider')
      ON CONFLICT (user_id, role_code) DO NOTHING;
    ELSE
      DELETE FROM public.user_roles
      WHERE user_id = NEW.id AND role_code = 'provider';
    END IF;
  END IF;

  IF NEW.is_driver IS DISTINCT FROM OLD.is_driver THEN
    IF NEW.is_driver THEN
      INSERT INTO public.user_roles (user_id, role_code)
      VALUES (NEW.id, 'driver')
      ON CONFLICT (user_id, role_code) DO NOTHING;
    ELSE
      DELETE FROM public.user_roles
      WHERE user_id = NEW.id AND role_code = 'driver';
    END IF;
  END IF;

  IF NEW.is_admin IS DISTINCT FROM OLD.is_admin THEN
    IF NEW.is_admin THEN
      INSERT INTO public.user_roles (user_id, role_code)
      VALUES (NEW.id, 'admin')
      ON CONFLICT (user_id, role_code) DO NOTHING;
    ELSE
      DELETE FROM public.user_roles
      WHERE user_id = NEW.id AND role_code = 'admin';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

-- Existing trigger definition remains valid and now uses the stricter function above.
