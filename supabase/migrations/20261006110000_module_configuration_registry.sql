-- Wantok Service T2.2: versioned, typed module configuration.
-- Configuration values are isolated from secret values. Secret-bearing fields
-- store references only (for example env://NAME or vault://path/key).

CREATE TABLE public.technical_module_config_schema_versions (
  module_key text NOT NULL
    REFERENCES public.technical_modules(module_key) ON DELETE CASCADE,
  schema_version integer NOT NULL CHECK (schema_version > 0),
  title text NOT NULL,
  description text,
  status text NOT NULL DEFAULT 'draft'
    CHECK (status IN ('draft', 'active', 'retired')),
  created_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  activated_at timestamptz,
  PRIMARY KEY (module_key, schema_version)
);

CREATE UNIQUE INDEX technical_module_config_one_active_idx
  ON public.technical_module_config_schema_versions (module_key)
  WHERE status = 'active';

CREATE TABLE public.technical_module_config_fields (
  module_key text NOT NULL,
  schema_version integer NOT NULL,
  field_key text NOT NULL
    CHECK (field_key ~ '^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)*$'),
  field_type text NOT NULL
    CHECK (
      field_type IN (
        'string',
        'integer',
        'decimal',
        'boolean',
        'enum',
        'url',
        'string_list',
        'duration_seconds',
        'secret_reference'
      )
    ),
  group_key text NOT NULL DEFAULT 'general'
    CHECK (group_key ~ '^[a-z][a-z0-9_]*$'),
  group_label text NOT NULL DEFAULT 'General',
  label text NOT NULL,
  help_text text,
  sort_order integer NOT NULL DEFAULT 0,
  is_required boolean NOT NULL DEFAULT false,
  is_advanced boolean NOT NULL DEFAULT false,
  default_value jsonb,
  validation jsonb NOT NULL DEFAULT '{}'::jsonb,
  PRIMARY KEY (module_key, schema_version, field_key),
  FOREIGN KEY (module_key, schema_version)
    REFERENCES public.technical_module_config_schema_versions(
      module_key,
      schema_version
    )
    ON DELETE CASCADE,
  CHECK (
    field_type <> 'secret_reference'
    OR default_value IS NULL
  )
);

CREATE INDEX technical_module_config_fields_order_idx
  ON public.technical_module_config_fields (
    module_key,
    schema_version,
    group_key,
    sort_order,
    field_key
  );

CREATE TABLE public.technical_module_config_values (
  module_key text NOT NULL,
  schema_version integer NOT NULL,
  field_key text NOT NULL,
  value jsonb NOT NULL,
  updated_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (module_key, schema_version, field_key),
  FOREIGN KEY (module_key, schema_version, field_key)
    REFERENCES public.technical_module_config_fields(
      module_key,
      schema_version,
      field_key
    )
    ON DELETE CASCADE
);

CREATE INDEX technical_module_config_values_updated_idx
  ON public.technical_module_config_values (
    module_key,
    schema_version,
    updated_at DESC
  );

CREATE OR REPLACE FUNCTION public.validate_technical_config_value(
  p_field_type text,
  p_value jsonb,
  p_validation jsonb DEFAULT '{}'::jsonb,
  p_required boolean DEFAULT false
)
RETURNS boolean
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  v_type text;
  v_text text;
  v_number numeric;
  v_integer numeric;
  v_min numeric;
  v_max numeric;
  v_max_length integer;
  v_max_items integer;
BEGIN
  IF p_value IS NULL OR p_value = 'null'::jsonb THEN
    RETURN NOT p_required;
  END IF;

  v_type := jsonb_typeof(p_value);

  CASE p_field_type
    WHEN 'boolean' THEN
      RETURN v_type = 'boolean';

    WHEN 'integer', 'duration_seconds' THEN
      IF v_type <> 'number' THEN
        RETURN false;
      END IF;

      v_number := (p_value #>> '{}')::numeric;
      v_integer := trunc(v_number);

      IF v_number <> v_integer THEN
        RETURN false;
      END IF;

      IF p_field_type = 'duration_seconds' AND v_integer < 0 THEN
        RETURN false;
      END IF;

      IF p_validation ? 'min' THEN
        v_min := (p_validation ->> 'min')::numeric;
        IF v_integer < v_min THEN
          RETURN false;
        END IF;
      END IF;

      IF p_validation ? 'max' THEN
        v_max := (p_validation ->> 'max')::numeric;
        IF v_integer > v_max THEN
          RETURN false;
        END IF;
      END IF;

      RETURN true;

    WHEN 'decimal' THEN
      IF v_type <> 'number' THEN
        RETURN false;
      END IF;

      v_number := (p_value #>> '{}')::numeric;

      IF p_validation ? 'min' THEN
        v_min := (p_validation ->> 'min')::numeric;
        IF v_number < v_min THEN
          RETURN false;
        END IF;
      END IF;

      IF p_validation ? 'max' THEN
        v_max := (p_validation ->> 'max')::numeric;
        IF v_number > v_max THEN
          RETURN false;
        END IF;
      END IF;

      RETURN true;

    WHEN 'string', 'url', 'enum', 'secret_reference' THEN
      IF v_type <> 'string' THEN
        RETURN false;
      END IF;

      v_text := p_value #>> '{}';

      IF p_required AND btrim(v_text) = '' THEN
        RETURN false;
      END IF;

      IF p_validation ? 'max_length' THEN
        v_max_length := (p_validation ->> 'max_length')::integer;
        IF char_length(v_text) > v_max_length THEN
          RETURN false;
        END IF;
      END IF;

      IF p_validation ? 'pattern'
         AND v_text !~ (p_validation ->> 'pattern') THEN
        RETURN false;
      END IF;

      IF p_field_type = 'url'
         AND v_text !~ '^https?://[^[:space:]]+$' THEN
        RETURN false;
      END IF;

      IF p_field_type = 'enum'
         AND NOT EXISTS (
           SELECT 1
           FROM jsonb_array_elements_text(
             coalesce(p_validation -> 'allowed_values', '[]'::jsonb)
           ) allowed(value)
           WHERE allowed.value = v_text
         ) THEN
        RETURN false;
      END IF;

      IF p_field_type = 'secret_reference'
         AND v_text !~ '^(env|vault|external-secret|supabase)://[A-Za-z0-9._:/-]+$' THEN
        RETURN false;
      END IF;

      RETURN true;

    WHEN 'string_list' THEN
      IF v_type <> 'array' THEN
        RETURN false;
      END IF;

      IF EXISTS (
        SELECT 1
        FROM jsonb_array_elements(p_value) item(value)
        WHERE jsonb_typeof(item.value) <> 'string'
      ) THEN
        RETURN false;
      END IF;

      IF p_validation ? 'max_items' THEN
        v_max_items := (p_validation ->> 'max_items')::integer;
        IF jsonb_array_length(p_value) > v_max_items THEN
          RETURN false;
        END IF;
      END IF;

      IF p_validation ? 'max_length'
         AND EXISTS (
           SELECT 1
           FROM jsonb_array_elements_text(p_value) item(value)
           WHERE char_length(item.value) >
             (p_validation ->> 'max_length')::integer
         ) THEN
        RETURN false;
      END IF;

      RETURN true;

    ELSE
      RETURN false;
  END CASE;
END;
$$;

CREATE OR REPLACE FUNCTION public.redact_technical_config_audit_value(
  p_field_type text,
  p_value jsonb
)
RETURNS jsonb
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE
    WHEN p_field_type = 'secret_reference' THEN
      jsonb_build_object(
        'configured',
        p_value IS NOT NULL AND p_value <> 'null'::jsonb
      )
    ELSE p_value
  END;
$$;

CREATE OR REPLACE FUNCTION public.list_technical_module_configuration(
  p_module_key text
)
RETURNS TABLE (
  schema_version integer,
  schema_title text,
  schema_description text,
  field_key text,
  field_type text,
  group_key text,
  group_label text,
  label text,
  help_text text,
  sort_order integer,
  is_required boolean,
  is_advanced boolean,
  default_value jsonb,
  current_value jsonb,
  effective_value jsonb,
  is_overridden boolean,
  validation jsonb,
  updated_at timestamptz,
  updated_by_name text,
  can_configure boolean
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
    p_module_key,
    'module.view',
    auth.uid()
  ) THEN
    RAISE EXCEPTION 'Technical module view permission required';
  END IF;

  RETURN QUERY
  SELECT
    schema.schema_version,
    schema.title,
    schema.description,
    field.field_key,
    field.field_type,
    field.group_key,
    field.group_label,
    field.label,
    field.help_text,
    field.sort_order,
    field.is_required,
    field.is_advanced,
    field.default_value,
    value.value,
    coalesce(value.value, field.default_value),
    value.value IS NOT NULL,
    field.validation,
    value.updated_at,
    updater.full_name,
    public.has_technical_permission(
      p_module_key,
      'module.configure',
      auth.uid()
    )
  FROM public.technical_module_config_schema_versions schema
  JOIN public.technical_module_config_fields field
    ON field.module_key = schema.module_key
   AND field.schema_version = schema.schema_version
  LEFT JOIN public.technical_module_config_values value
    ON value.module_key = field.module_key
   AND value.schema_version = field.schema_version
   AND value.field_key = field.field_key
  LEFT JOIN public.profiles updater
    ON updater.id = value.updated_by
  WHERE schema.module_key = p_module_key
    AND schema.status = 'active'
  ORDER BY
    field.group_key,
    field.sort_order,
    field.field_key;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_technical_module_configuration(
  p_module_key text,
  p_schema_version integer,
  p_values jsonb
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_field record;
  v_entry record;
  v_before jsonb;
  v_after jsonb;
  v_audit_before jsonb := '{}'::jsonb;
  v_audit_after jsonb := '{}'::jsonb;
  v_changed_keys jsonb := '[]'::jsonb;
  v_changed integer := 0;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF NOT public.has_technical_permission(
    p_module_key,
    'module.configure',
    auth.uid()
  ) THEN
    RAISE EXCEPTION 'Technical module configuration permission required';
  END IF;

  IF jsonb_typeof(p_values) <> 'object' THEN
    RAISE EXCEPTION 'Configuration update must be a JSON object';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.technical_module_config_schema_versions schema
    WHERE schema.module_key = p_module_key
      AND schema.schema_version = p_schema_version
      AND schema.status = 'active'
  ) THEN
    RAISE EXCEPTION 'Active module configuration schema version mismatch';
  END IF;

  FOR v_entry IN
    SELECT key, value
    FROM jsonb_each(p_values)
  LOOP
    SELECT
      field.field_key,
      field.field_type,
      field.is_required,
      field.default_value,
      field.validation
    INTO v_field
    FROM public.technical_module_config_fields field
    WHERE field.module_key = p_module_key
      AND field.schema_version = p_schema_version
      AND field.field_key = v_entry.key;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Unknown configuration field: %', v_entry.key;
    END IF;

    SELECT value.value
    INTO v_before
    FROM public.technical_module_config_values value
    WHERE value.module_key = p_module_key
      AND value.schema_version = p_schema_version
      AND value.field_key = v_entry.key;

    IF v_entry.value = 'null'::jsonb THEN
      IF v_field.is_required
         AND v_field.default_value IS NULL THEN
        RAISE EXCEPTION 'Required configuration cannot be cleared: %', v_entry.key;
      END IF;

      DELETE FROM public.technical_module_config_values value
      WHERE value.module_key = p_module_key
        AND value.schema_version = p_schema_version
        AND value.field_key = v_entry.key;

      v_after := NULL;
    ELSE
      IF NOT public.validate_technical_config_value(
        v_field.field_type,
        v_entry.value,
        v_field.validation,
        v_field.is_required
      ) THEN
        RAISE EXCEPTION 'Invalid value for configuration field: %', v_entry.key;
      END IF;

      INSERT INTO public.technical_module_config_values (
        module_key,
        schema_version,
        field_key,
        value,
        updated_by
      )
      VALUES (
        p_module_key,
        p_schema_version,
        v_entry.key,
        v_entry.value,
        auth.uid()
      )
      ON CONFLICT (module_key, schema_version, field_key) DO UPDATE
      SET
        value = excluded.value,
        updated_by = excluded.updated_by,
        updated_at = now();

      v_after := v_entry.value;
    END IF;

    IF v_before IS DISTINCT FROM v_after THEN
      v_changed := v_changed + 1;
      v_changed_keys := v_changed_keys || jsonb_build_array(v_entry.key);
      v_audit_before := v_audit_before || jsonb_build_object(
        v_entry.key,
        public.redact_technical_config_audit_value(
          v_field.field_type,
          v_before
        )
      );
      v_audit_after := v_audit_after || jsonb_build_object(
        v_entry.key,
        public.redact_technical_config_audit_value(
          v_field.field_type,
          v_after
        )
      );
    END IF;
  END LOOP;

  IF v_changed > 0 THEN
    PERFORM public.write_audit_event(
      'technical_module_configuration_changed',
      'technical_module_configuration',
      NULL,
      jsonb_build_object(
        'module_key', p_module_key,
        'schema_version', p_schema_version,
        'changed_fields', v_changed_keys,
        'before', v_audit_before,
        'after', v_audit_after
      ),
      auth.uid()
    );
  END IF;

  RETURN v_changed;
END;
$$;

ALTER TABLE public.technical_module_config_schema_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.technical_module_config_fields ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.technical_module_config_values ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.technical_module_config_schema_versions
  FROM anon, authenticated;
REVOKE ALL ON TABLE public.technical_module_config_fields
  FROM anon, authenticated;
REVOKE ALL ON TABLE public.technical_module_config_values
  FROM anon, authenticated;

REVOKE ALL ON FUNCTION public.validate_technical_config_value(
  text, jsonb, jsonb, boolean
) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.redact_technical_config_audit_value(
  text, jsonb
) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.list_technical_module_configuration(
  text
) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.update_technical_module_configuration(
  text, integer, jsonb
) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.validate_technical_config_value(
  text, jsonb, jsonb, boolean
) TO authenticated;
GRANT EXECUTE ON FUNCTION public.redact_technical_config_audit_value(
  text, jsonb
) TO authenticated;
GRANT EXECUTE ON FUNCTION public.list_technical_module_configuration(
  text
) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_technical_module_configuration(
  text, integer, jsonb
) TO authenticated;

-- Initial safe v1 schemas. These values are operational configuration only.
-- Payment movement remains behind the separate Wantok Pay design gate.

INSERT INTO public.technical_module_config_schema_versions (
  module_key, schema_version, title, description, status, activated_at
)
VALUES
  ('mobility.taxi', 1, 'Taxi dispatch settings',
   'Safe dispatch, matching and integration-reference settings.', 'active', now()),
  ('mobility.water_transport', 1, 'Water transport settings',
   'Passenger booking and manifest settings.', 'active', now()),
  ('core.messaging', 1, 'Messaging settings',
   'Conversation limits, receipts and moderation controls.', 'active', now()),
  ('commerce.food', 1, 'Food ordering settings',
   'Food-order limits and fulfilment options.', 'active', now()),
  ('commerce.grocery', 1, 'Grocery ordering settings',
   'Grocery-order limits and fulfilment options.', 'active', now()),
  ('delivery', 1, 'Delivery settings',
   'Delivery matching and proof-of-delivery controls.', 'active', now()),
  ('notifications', 1, 'Notification settings',
   'Default notification routing and push availability.', 'active', now());

INSERT INTO public.technical_module_config_fields (
  module_key, schema_version, field_key, field_type,
  group_key, group_label, label, help_text, sort_order,
  is_required, is_advanced, default_value, validation
)
VALUES
  ('mobility.taxi', 1, 'dispatch.radius_km', 'decimal',
   'dispatch', 'Dispatch', 'Driver search radius (km)',
   'Initial radius used when searching for nearby available drivers.', 10,
   true, false, '8'::jsonb, '{"min":1,"max":50}'::jsonb),
  ('mobility.taxi', 1, 'dispatch.offer_timeout_seconds', 'duration_seconds',
   'dispatch', 'Dispatch', 'Driver offer timeout',
   'Seconds a driver has to accept a ride offer before redispatch.', 20,
   true, false, '25'::jsonb, '{"min":10,"max":120}'::jsonb),
  ('mobility.taxi', 1, 'dispatch.max_offer_drivers', 'integer',
   'dispatch', 'Dispatch', 'Maximum offered drivers',
   'Maximum number of drivers considered in an offer wave.', 30,
   true, true, '5'::jsonb, '{"min":1,"max":20}'::jsonb),
  ('mobility.taxi', 1, 'integrations.maps_secret_ref', 'secret_reference',
   'integrations', 'Integrations', 'Maps API secret reference',
   'Reference only. Never paste an API key here. Example: env://MAPS_API_KEY.', 100,
   false, true, NULL, '{}'::jsonb),

  ('mobility.water_transport', 1, 'booking.cutoff_minutes', 'integer',
   'booking', 'Booking', 'Booking cutoff (minutes)',
   'Minimum minutes before departure when new passenger bookings close.', 10,
   true, false, '30'::jsonb, '{"min":0,"max":1440}'::jsonb),
  ('mobility.water_transport', 1, 'booking.max_passengers_per_booking', 'integer',
   'booking', 'Booking', 'Maximum passengers per booking',
   'Largest passenger count allowed in one booking.', 20,
   true, false, '8'::jsonb, '{"min":1,"max":50}'::jsonb),
  ('mobility.water_transport', 1, 'operations.require_manifest', 'boolean',
   'operations', 'Operations', 'Require passenger manifest',
   'Require a manifest before a scheduled departure can be boarded.', 10,
   true, false, 'true'::jsonb, '{}'::jsonb),

  ('core.messaging', 1, 'messages.max_length', 'integer',
   'messages', 'Messages', 'Maximum message length',
   'Maximum number of characters accepted in one booking conversation message.', 10,
   true, false, '2000'::jsonb, '{"min":100,"max":10000}'::jsonb),
  ('core.messaging', 1, 'messages.read_receipts', 'boolean',
   'messages', 'Messages', 'Read receipts',
   'Allow participant read-state updates for booking conversations.', 20,
   true, false, 'true'::jsonb, '{}'::jsonb),
  ('core.messaging', 1, 'moderation.blocked_terms', 'string_list',
   'moderation', 'Moderation', 'Blocked terms',
   'Optional platform moderation terms. One value per list item.', 10,
   false, true, '[]'::jsonb, '{"max_items":100,"max_length":80}'::jsonb),

  ('commerce.food', 1, 'ordering.minimum_order_pgk', 'decimal',
   'ordering', 'Ordering', 'Minimum order (PGK)',
   'Minimum subtotal accepted for a food order.', 10,
   true, false, '0'::jsonb, '{"min":0,"max":10000}'::jsonb),
  ('commerce.food', 1, 'ordering.max_items', 'integer',
   'ordering', 'Ordering', 'Maximum items per order',
   'Maximum total line-item quantity allowed in one food order.', 20,
   true, false, '50'::jsonb, '{"min":1,"max":200}'::jsonb),
  ('commerce.food', 1, 'fulfilment.allow_pickup', 'boolean',
   'fulfilment', 'Fulfilment', 'Allow pickup',
   'Allow customer pickup where the vendor supports it.', 10,
   true, false, 'true'::jsonb, '{}'::jsonb),

  ('commerce.grocery', 1, 'ordering.minimum_order_pgk', 'decimal',
   'ordering', 'Ordering', 'Minimum order (PGK)',
   'Minimum subtotal accepted for a grocery order.', 10,
   true, false, '0'::jsonb, '{"min":0,"max":10000}'::jsonb),
  ('commerce.grocery', 1, 'ordering.max_items', 'integer',
   'ordering', 'Ordering', 'Maximum items per order',
   'Maximum total line-item quantity allowed in one grocery order.', 20,
   true, false, '80'::jsonb, '{"min":1,"max":300}'::jsonb),
  ('commerce.grocery', 1, 'fulfilment.allow_pickup', 'boolean',
   'fulfilment', 'Fulfilment', 'Allow pickup',
   'Allow customer pickup where the shop supports it.', 10,
   true, false, 'true'::jsonb, '{}'::jsonb),

  ('delivery', 1, 'matching.radius_km', 'decimal',
   'matching', 'Matching', 'Courier search radius (km)',
   'Initial radius used to find suitable courier providers.', 10,
   true, false, '10'::jsonb, '{"min":1,"max":100}'::jsonb),
  ('delivery', 1, 'proof_of_delivery.required', 'boolean',
   'proof_of_delivery', 'Proof of delivery', 'Require proof of delivery',
   'Require delivery completion evidence before a job can close.', 10,
   true, false, 'true'::jsonb, '{}'::jsonb),

  ('notifications', 1, 'delivery.default_channel', 'enum',
   'delivery', 'Delivery', 'Default channel',
   'Default notification channel when the user has not selected another preference.', 10,
   true, false, '"in_app"'::jsonb,
   '{"allowed_values":["in_app","push","email"]}'::jsonb),
  ('notifications', 1, 'delivery.push_enabled', 'boolean',
   'delivery', 'Delivery', 'Push notifications enabled',
   'Master switch for push delivery after a push provider is connected.', 20,
   true, false, 'false'::jsonb, '{}'::jsonb);
