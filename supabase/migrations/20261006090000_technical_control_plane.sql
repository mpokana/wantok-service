-- Wantok Service technical control plane foundation.
-- Separates operations administration from technical platform authority and
-- introduces module-scoped technical access.

INSERT INTO public.app_roles (code, name, description, is_system)
VALUES
  ('tech_platform_admin', 'Technical Platform Administrator',
   'Highest technical authority across Wantok Service modules.', true),
  ('tech_admin', 'Technical Administrator',
   'Technical administrator for explicitly assigned modules.', true),
  ('tech_module_admin', 'Module Administrator',
   'Administrator for explicitly assigned technical modules.', true),
  ('tech_support', 'Technical Support',
   'Technical support/operator access for assigned modules.', true),
  ('tech_auditor', 'Technical Auditor',
   'Read-only technical audit and diagnostics access for assigned modules.', true)
ON CONFLICT (code) DO UPDATE
SET name = excluded.name,
    description = excluded.description;

CREATE TABLE public.technical_modules (
  module_key text PRIMARY KEY
    CHECK (module_key ~ '^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)*$'),
  name text NOT NULL,
  description text,
  group_code text NOT NULL
    CHECK (group_code ~ '^[a-z][a-z0-9_]*$'),
  sort_order integer NOT NULL DEFAULT 0,
  is_enabled boolean NOT NULL DEFAULT true,
  maintenance_mode boolean NOT NULL DEFAULT false,
  version text,
  health_status text NOT NULL DEFAULT 'unknown'
    CHECK (health_status IN ('unknown', 'healthy', 'degraded', 'down')),
  last_health_at timestamptz,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX technical_modules_group_sort_idx
  ON public.technical_modules (group_code, sort_order, module_key);

CREATE TRIGGER technical_modules_set_updated_at
BEFORE UPDATE ON public.technical_modules
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

INSERT INTO public.technical_modules (
  module_key, name, description, group_code, sort_order, is_enabled
)
VALUES
  ('core.identity', 'Identity & Access',
   'Authentication, RBAC and identity foundations.', 'core', 10, true),
  ('core.account', 'Accounts & Profiles',
   'Customer and provider account/profile services.', 'core', 20, true),
  ('core.catalog', 'Service Catalogue',
   'Service categories and shared marketplace catalogue.', 'core', 30, true),
  ('core.messaging', 'Messaging',
   'Booking-scoped customer/provider conversations.', 'core', 40, true),
  ('mobility.taxi', 'Taxi / Ride',
   'On-demand taxi dispatch and ride lifecycle.', 'mobility', 100, true),
  ('mobility.water_transport', 'Water Transport',
   'Scheduled boat and ship passenger transport.', 'mobility', 110, true),
  ('hire.vehicle', 'Vehicle Hire',
   'Scheduled vehicle-hire marketplace services.', 'hire', 200, true),
  ('hire.boat', 'Boat Hire',
   'Private boat-hire marketplace services.', 'hire', 210, true),
  ('marketplace.specialist', 'Specialist Services',
   'Trades, professional and specialist service marketplace.', 'marketplace', 300, true),
  ('marketplace.general_labour', 'General Labour',
   'General labour and people-hire marketplace.', 'marketplace', 310, true),
  ('places.venues', 'Venues',
   'Venue and place reservation services.', 'places', 400, true),
  ('events', 'Events',
   'Event discovery, registration and check-in.', 'events', 500, true),
  ('commerce.food', 'Food',
   'Food vendor catalogue and commerce workflow.', 'commerce', 600, true),
  ('commerce.grocery', 'Groceries / Shops',
   'Grocery and general shop commerce workflow.', 'commerce', 610, true),
  ('delivery', 'Delivery / Courier',
   'Delivery and courier service module.', 'logistics', 700, true),
  ('errands', 'Errands / Pabili',
   'Errand, purchase and collection service module.', 'logistics', 710, true),
  ('payments', 'Wantok Pay',
   'Payment intents, payment rails and settlement services.', 'platform', 800, false),
  ('notifications', 'Notifications',
   'In-app and future push-notification services.', 'platform', 810, true),
  ('audit', 'Audit',
   'Cross-platform operational and technical audit services.', 'platform', 820, true)
ON CONFLICT (module_key) DO UPDATE
SET name = excluded.name,
    description = excluded.description,
    group_code = excluded.group_code,
    sort_order = excluded.sort_order;

CREATE TABLE public.technical_permissions (
  code text PRIMARY KEY
    CHECK (code ~ '^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$'),
  name text NOT NULL,
  description text,
  scope text NOT NULL CHECK (scope IN ('module', 'platform')),
  risk_level text NOT NULL DEFAULT 'read'
    CHECK (risk_level IN ('read', 'operational', 'privileged', 'critical')),
  created_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO public.technical_permissions (
  code, name, description, scope, risk_level
)
VALUES
  ('module.view', 'View module', 'View module technical state.', 'module', 'read'),
  ('module.configure', 'Configure module', 'Change module configuration.', 'module', 'privileged'),
  ('module.enable', 'Enable module', 'Enable a disabled module.', 'module', 'critical'),
  ('module.disable', 'Disable module', 'Disable a module.', 'module', 'critical'),
  ('module.maintenance', 'Maintenance mode', 'Enter or leave module maintenance mode.', 'module', 'privileged'),
  ('module.diagnostics', 'Diagnostics', 'View or run module diagnostics.', 'module', 'read'),
  ('module.logs', 'Logs', 'View module technical logs.', 'module', 'read'),
  ('module.jobs', 'Jobs', 'View or operate module background jobs.', 'module', 'operational'),
  ('module.integrations', 'Integrations', 'Manage module integrations.', 'module', 'privileged'),
  ('module.permissions', 'Module access', 'Manage lower technical access for a module.', 'module', 'critical'),
  ('platform.users', 'Technical users', 'Manage technical staff identities.', 'platform', 'critical'),
  ('platform.roles', 'Technical roles', 'Manage technical role authority.', 'platform', 'critical'),
  ('platform.audit', 'Technical audit', 'View cross-platform technical audit.', 'platform', 'privileged'),
  ('platform.settings', 'Platform settings', 'Manage platform-wide technical settings.', 'platform', 'critical')
ON CONFLICT (code) DO UPDATE
SET name = excluded.name,
    description = excluded.description,
    scope = excluded.scope,
    risk_level = excluded.risk_level;

CREATE TABLE public.technical_access_levels (
  code text PRIMARY KEY
    CHECK (code ~ '^tech_[a-z][a-z0-9_]*$'),
  name text NOT NULL,
  description text,
  rank integer NOT NULL UNIQUE CHECK (rank > 0),
  created_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO public.technical_access_levels (code, name, description, rank)
VALUES
  ('tech_auditor', 'Technical Auditor',
   'Read-only module visibility, diagnostics and logs.', 10),
  ('tech_support', 'Technical Support',
   'Support/operator visibility with approved job operations.', 20),
  ('tech_module_admin', 'Module Administrator',
   'Configure and operate an assigned module.', 30),
  ('tech_admin', 'Technical Administrator',
   'Administer an assigned module and delegate lower module access.', 40)
ON CONFLICT (code) DO UPDATE
SET name = excluded.name,
    description = excluded.description,
    rank = excluded.rank;

CREATE TABLE public.technical_access_level_permissions (
  access_level_code text NOT NULL
    REFERENCES public.technical_access_levels(code) ON DELETE CASCADE,
  permission_code text NOT NULL
    REFERENCES public.technical_permissions(code) ON DELETE CASCADE,
  PRIMARY KEY (access_level_code, permission_code)
);

INSERT INTO public.technical_access_level_permissions (
  access_level_code, permission_code
)
VALUES
  ('tech_auditor', 'module.view'),
  ('tech_auditor', 'module.diagnostics'),
  ('tech_auditor', 'module.logs'),

  ('tech_support', 'module.view'),
  ('tech_support', 'module.diagnostics'),
  ('tech_support', 'module.logs'),
  ('tech_support', 'module.jobs'),

  ('tech_module_admin', 'module.view'),
  ('tech_module_admin', 'module.configure'),
  ('tech_module_admin', 'module.enable'),
  ('tech_module_admin', 'module.disable'),
  ('tech_module_admin', 'module.maintenance'),
  ('tech_module_admin', 'module.diagnostics'),
  ('tech_module_admin', 'module.logs'),
  ('tech_module_admin', 'module.jobs'),
  ('tech_module_admin', 'module.integrations'),

  ('tech_admin', 'module.view'),
  ('tech_admin', 'module.configure'),
  ('tech_admin', 'module.enable'),
  ('tech_admin', 'module.disable'),
  ('tech_admin', 'module.maintenance'),
  ('tech_admin', 'module.diagnostics'),
  ('tech_admin', 'module.logs'),
  ('tech_admin', 'module.jobs'),
  ('tech_admin', 'module.integrations'),
  ('tech_admin', 'module.permissions')
ON CONFLICT DO NOTHING;

CREATE TABLE public.technical_user_module_access (
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  module_key text NOT NULL REFERENCES public.technical_modules(module_key) ON DELETE CASCADE,
  access_level_code text NOT NULL
    REFERENCES public.technical_access_levels(code) ON DELETE RESTRICT,
  granted_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  granted_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz,
  notes text,
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, module_key),
  CHECK (expires_at IS NULL OR expires_at > granted_at)
);

CREATE INDEX technical_user_module_access_user_active_idx
  ON public.technical_user_module_access (user_id, module_key)
  WHERE expires_at IS NULL;

CREATE INDEX technical_user_module_access_module_active_idx
  ON public.technical_user_module_access (module_key, access_level_code, user_id)
  WHERE expires_at IS NULL;

CREATE TRIGGER technical_user_module_access_set_updated_at
BEFORE UPDATE ON public.technical_user_module_access
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE OR REPLACE FUNCTION public.is_technical_role(p_role_code text)
RETURNS boolean
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT p_role_code IN (
    'tech_platform_admin',
    'tech_admin',
    'tech_module_admin',
    'tech_support',
    'tech_auditor'
  );
$$;

CREATE OR REPLACE FUNCTION public.is_technical_platform_admin(
  p_user_id uuid DEFAULT auth.uid()
)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT public.has_role('tech_platform_admin', p_user_id);
$$;

CREATE OR REPLACE FUNCTION public.has_platform_permission(
  p_permission_code text,
  p_user_id uuid DEFAULT auth.uid()
)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT
    EXISTS (
      SELECT 1
      FROM public.technical_permissions permission
      WHERE permission.code = p_permission_code
        AND permission.scope = 'platform'
    )
    AND public.is_technical_platform_admin(p_user_id);
$$;

CREATE OR REPLACE FUNCTION public.effective_technical_access_level(
  p_module_key text,
  p_user_id uuid DEFAULT auth.uid()
)
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT CASE
    WHEN public.is_technical_platform_admin(p_user_id)
      THEN 'tech_platform_admin'
    ELSE (
      SELECT access.access_level_code
      FROM public.technical_user_module_access access
      WHERE access.user_id = p_user_id
        AND access.module_key = p_module_key
        AND (access.expires_at IS NULL OR access.expires_at > now())
      LIMIT 1
    )
  END;
$$;

CREATE OR REPLACE FUNCTION public.has_technical_permission(
  p_module_key text,
  p_permission_code text,
  p_user_id uuid DEFAULT auth.uid()
)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT
    EXISTS (
      SELECT 1
      FROM public.technical_permissions permission
      WHERE permission.code = p_permission_code
        AND permission.scope = 'module'
    )
    AND (
      public.is_technical_platform_admin(p_user_id)
      OR EXISTS (
        SELECT 1
        FROM public.technical_user_module_access access
        JOIN public.technical_access_level_permissions level_permission
          ON level_permission.access_level_code = access.access_level_code
        WHERE access.user_id = p_user_id
          AND access.module_key = p_module_key
          AND level_permission.permission_code = p_permission_code
          AND (access.expires_at IS NULL OR access.expires_at > now())
      )
    );
$$;

CREATE OR REPLACE FUNCTION public.can_access_technical_console(
  p_user_id uuid DEFAULT auth.uid()
)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT
    public.is_technical_platform_admin(p_user_id)
    OR EXISTS (
      SELECT 1
      FROM public.user_roles role
      WHERE role.user_id = p_user_id
        AND public.is_technical_role(role.role_code)
        AND (role.expires_at IS NULL OR role.expires_at > now())
    )
    OR EXISTS (
      SELECT 1
      FROM public.technical_user_module_access access
      WHERE access.user_id = p_user_id
        AND (access.expires_at IS NULL OR access.expires_at > now())
    );
$$;

CREATE OR REPLACE FUNCTION public.list_my_technical_modules()
RETURNS TABLE (
  module_key text,
  name text,
  description text,
  group_code text,
  sort_order integer,
  is_enabled boolean,
  maintenance_mode boolean,
  version text,
  health_status text,
  last_health_at timestamptz,
  access_level_code text,
  permission_codes text[]
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT
    module.module_key,
    module.name,
    module.description,
    module.group_code,
    module.sort_order,
    module.is_enabled,
    module.maintenance_mode,
    module.version,
    module.health_status,
    module.last_health_at,
    CASE
      WHEN public.is_technical_platform_admin(auth.uid())
        THEN 'tech_platform_admin'
      ELSE access.access_level_code
    END AS access_level_code,
    CASE
      WHEN public.is_technical_platform_admin(auth.uid())
        THEN ARRAY(
          SELECT permission.code
          FROM public.technical_permissions permission
          WHERE permission.scope = 'module'
          ORDER BY permission.code
        )
      ELSE ARRAY(
        SELECT level_permission.permission_code
        FROM public.technical_access_level_permissions level_permission
        WHERE level_permission.access_level_code = access.access_level_code
        ORDER BY level_permission.permission_code
      )
    END AS permission_codes
  FROM public.technical_modules module
  LEFT JOIN public.technical_user_module_access access
    ON access.module_key = module.module_key
   AND access.user_id = auth.uid()
   AND (access.expires_at IS NULL OR access.expires_at > now())
  WHERE auth.uid() IS NOT NULL
    AND (
      public.is_technical_platform_admin(auth.uid())
      OR access.user_id IS NOT NULL
    )
  ORDER BY module.group_code, module.sort_order, module.module_key;
$$;

CREATE OR REPLACE FUNCTION public.set_technical_module_state(
  p_module_key text,
  p_enabled boolean DEFAULT NULL,
  p_maintenance_mode boolean DEFAULT NULL
)
RETURNS public.technical_modules
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_module public.technical_modules%ROWTYPE;
  v_before jsonb;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT *
  INTO v_module
  FROM public.technical_modules
  WHERE module_key = p_module_key
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Technical module not found';
  END IF;

  IF p_enabled IS NOT NULL
     AND p_enabled IS DISTINCT FROM v_module.is_enabled THEN
    IF p_enabled
       AND NOT public.has_technical_permission(
         p_module_key, 'module.enable', auth.uid()
       ) THEN
      RAISE EXCEPTION 'Module enable permission required';
    END IF;

    IF NOT p_enabled
       AND NOT public.has_technical_permission(
         p_module_key, 'module.disable', auth.uid()
       ) THEN
      RAISE EXCEPTION 'Module disable permission required';
    END IF;
  END IF;

  IF p_maintenance_mode IS NOT NULL
     AND p_maintenance_mode IS DISTINCT FROM v_module.maintenance_mode
     AND NOT public.has_technical_permission(
       p_module_key, 'module.maintenance', auth.uid()
     ) THEN
    RAISE EXCEPTION 'Module maintenance permission required';
  END IF;

  v_before := jsonb_build_object(
    'is_enabled', v_module.is_enabled,
    'maintenance_mode', v_module.maintenance_mode
  );

  UPDATE public.technical_modules
  SET
    is_enabled = coalesce(p_enabled, is_enabled),
    maintenance_mode = coalesce(p_maintenance_mode, maintenance_mode)
  WHERE module_key = p_module_key
  RETURNING * INTO v_module;

  IF v_before IS DISTINCT FROM jsonb_build_object(
    'is_enabled', v_module.is_enabled,
    'maintenance_mode', v_module.maintenance_mode
  ) THEN
    PERFORM public.write_audit_event(
      'technical_module_state_changed',
      'technical_module',
      NULL,
      jsonb_build_object(
        'module_key', p_module_key,
        'before', v_before,
        'after', jsonb_build_object(
          'is_enabled', v_module.is_enabled,
          'maintenance_mode', v_module.maintenance_mode
        )
      ),
      auth.uid()
    );
  END IF;

  RETURN v_module;
END;
$$;

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

  IF NOT EXISTS (
    SELECT 1 FROM public.technical_modules WHERE module_key = p_module_key
  ) THEN
    RAISE EXCEPTION 'Technical module not found';
  END IF;

  SELECT rank INTO v_target_rank
  FROM public.technical_access_levels
  WHERE code = p_access_level_code;

  IF v_target_rank IS NULL THEN
    RAISE EXCEPTION 'Unknown technical access level';
  END IF;

  IF NOT public.is_technical_platform_admin(auth.uid()) THEN
    v_actor_level := public.effective_technical_access_level(
      p_module_key, auth.uid()
    );

    SELECT rank INTO v_actor_rank
    FROM public.technical_access_levels
    WHERE code = v_actor_level;

    IF v_actor_rank IS NULL
       OR NOT public.has_technical_permission(
         p_module_key, 'module.permissions', auth.uid()
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

CREATE OR REPLACE FUNCTION public.revoke_technical_module_access(
  p_user_id uuid,
  p_module_key text
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_actor_level text;
  v_actor_rank integer;
  v_target_level text;
  v_target_rank integer;
  v_deleted boolean;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT access_level_code
  INTO v_target_level
  FROM public.technical_user_module_access
  WHERE user_id = p_user_id
    AND module_key = p_module_key;

  IF v_target_level IS NULL THEN
    RETURN false;
  END IF;

  SELECT rank INTO v_target_rank
  FROM public.technical_access_levels
  WHERE code = v_target_level;

  IF NOT public.is_technical_platform_admin(auth.uid()) THEN
    v_actor_level := public.effective_technical_access_level(
      p_module_key, auth.uid()
    );

    SELECT rank INTO v_actor_rank
    FROM public.technical_access_levels
    WHERE code = v_actor_level;

    IF v_actor_rank IS NULL
       OR NOT public.has_technical_permission(
         p_module_key, 'module.permissions', auth.uid()
       )
       OR v_target_rank >= v_actor_rank THEN
      RAISE EXCEPTION 'Technical module access administration not permitted';
    END IF;
  END IF;

  DELETE FROM public.technical_user_module_access
  WHERE user_id = p_user_id
    AND module_key = p_module_key;
  v_deleted := FOUND;

  IF v_deleted THEN
    PERFORM public.write_audit_event(
      'technical_module_access_revoked',
      'technical_module_access',
      p_user_id,
      jsonb_build_object(
        'module_key', p_module_key,
        'access_level', v_target_level
      ),
      auth.uid()
    );
  END IF;

  RETURN v_deleted;
END;
$$;

-- Keep Operations Admin and Technical Platform Admin authority separate.
CREATE OR REPLACE FUNCTION public.grant_user_role(
  p_user_id uuid,
  p_role_code text,
  p_expires_at timestamptz DEFAULT NULL
)
RETURNS public.user_roles
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_role public.user_roles%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF public.is_technical_role(p_role_code) THEN
    IF NOT public.is_technical_platform_admin(auth.uid()) THEN
      RAISE EXCEPTION 'Technical platform admin access required';
    END IF;
  ELSIF NOT public.is_admin(auth.uid()) THEN
    RAISE EXCEPTION 'Operations admin access required';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.app_roles WHERE code = p_role_code
  ) THEN
    RAISE EXCEPTION 'Unknown role';
  END IF;

  INSERT INTO public.user_roles (
    user_id, role_code, granted_by, expires_at
  )
  VALUES (
    p_user_id, p_role_code, auth.uid(), p_expires_at
  )
  ON CONFLICT (user_id, role_code) DO UPDATE
  SET
    granted_by = excluded.granted_by,
    granted_at = now(),
    expires_at = excluded.expires_at
  RETURNING * INTO v_role;

  PERFORM public.write_audit_event(
    'role_granted',
    'user_role',
    p_user_id,
    jsonb_build_object(
      'role', p_role_code,
      'expires_at', p_expires_at
    ),
    auth.uid()
  );

  RETURN v_role;
END;
$$;

CREATE OR REPLACE FUNCTION public.revoke_user_role(
  p_user_id uuid,
  p_role_code text
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_deleted boolean;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF p_role_code = 'customer' THEN
    RAISE EXCEPTION 'The customer base role cannot be revoked';
  END IF;

  IF public.is_technical_role(p_role_code) THEN
    IF NOT public.is_technical_platform_admin(auth.uid()) THEN
      RAISE EXCEPTION 'Technical platform admin access required';
    END IF;

    IF p_role_code = 'tech_platform_admin'
       AND public.has_role(p_role_code, p_user_id)
       AND (
         SELECT count(*)
         FROM public.user_roles role
         WHERE role.role_code = 'tech_platform_admin'
           AND (role.expires_at IS NULL OR role.expires_at > now())
       ) <= 1 THEN
      RAISE EXCEPTION 'Cannot revoke the last technical platform administrator';
    END IF;
  ELSIF NOT public.is_admin(auth.uid()) THEN
    RAISE EXCEPTION 'Operations admin access required';
  END IF;

  DELETE FROM public.user_roles
  WHERE user_id = p_user_id
    AND role_code = p_role_code;
  v_deleted := FOUND;

  IF v_deleted THEN
    PERFORM public.write_audit_event(
      'role_revoked',
      'user_role',
      p_user_id,
      jsonb_build_object('role', p_role_code),
      auth.uid()
    );
  END IF;

  RETURN v_deleted;
END;
$$;

ALTER TABLE public.technical_modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.technical_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.technical_access_levels ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.technical_access_level_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.technical_user_module_access ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.technical_modules FROM anon, authenticated;
REVOKE ALL ON TABLE public.technical_permissions FROM anon, authenticated;
REVOKE ALL ON TABLE public.technical_access_levels FROM anon, authenticated;
REVOKE ALL ON TABLE public.technical_access_level_permissions FROM anon, authenticated;
REVOKE ALL ON TABLE public.technical_user_module_access FROM anon, authenticated;

REVOKE ALL ON FUNCTION public.is_technical_role(text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.is_technical_platform_admin(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.has_platform_permission(text, uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.effective_technical_access_level(text, uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.has_technical_permission(text, text, uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.can_access_technical_console(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.list_my_technical_modules() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.set_technical_module_state(text, boolean, boolean) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.grant_technical_module_access(
  uuid, text, text, timestamptz, text
) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.revoke_technical_module_access(uuid, text) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.is_technical_role(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_technical_platform_admin(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.has_platform_permission(text, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.effective_technical_access_level(text, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.has_technical_permission(text, text, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.can_access_technical_console(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.list_my_technical_modules() TO authenticated;
GRANT EXECUTE ON FUNCTION public.set_technical_module_state(text, boolean, boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.grant_technical_module_access(
  uuid, text, text, timestamptz, text
) TO authenticated;
GRANT EXECUTE ON FUNCTION public.revoke_technical_module_access(uuid, text) TO authenticated;

CREATE POLICY audit_events_technical_read
ON public.audit_events
FOR SELECT
TO authenticated
USING (
  public.has_platform_permission('platform.audit', auth.uid())
);
