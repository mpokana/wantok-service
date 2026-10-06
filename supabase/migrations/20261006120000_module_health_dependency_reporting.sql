-- T2.3: module health and dependency reporting.
-- Adds an explicit dependency graph, registered health probes/reporters,
-- current health state, transition history, impact previews, and secured
-- Technical Control read/run RPCs.

CREATE TABLE public.technical_module_dependencies (
  module_key text NOT NULL
    REFERENCES public.technical_modules(module_key) ON DELETE CASCADE,
  depends_on_module_key text NOT NULL
    REFERENCES public.technical_modules(module_key) ON DELETE RESTRICT,
  dependency_type text NOT NULL DEFAULT 'required'
    CHECK (dependency_type IN ('required', 'optional')),
  failure_effect text NOT NULL DEFAULT 'degraded'
    CHECK (failure_effect IN ('degraded', 'down')),
  description text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (module_key, depends_on_module_key),
  CHECK (module_key <> depends_on_module_key)
);

CREATE INDEX technical_module_dependencies_reverse_idx
  ON public.technical_module_dependencies (depends_on_module_key, module_key);

CREATE TRIGGER technical_module_dependencies_set_updated_at
BEFORE UPDATE ON public.technical_module_dependencies
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE OR REPLACE FUNCTION public.prevent_technical_module_dependency_cycle()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF EXISTS (
    WITH RECURSIVE upstream(module_key, path) AS (
      SELECT
        NEW.depends_on_module_key,
        ARRAY[NEW.depends_on_module_key]::text[]
      UNION ALL
      SELECT
        dependency.depends_on_module_key,
        upstream.path || dependency.depends_on_module_key
      FROM public.technical_module_dependencies dependency
      JOIN upstream
        ON dependency.module_key = upstream.module_key
      WHERE NOT dependency.depends_on_module_key = ANY(upstream.path)
    )
    SELECT 1
    FROM upstream
    WHERE module_key = NEW.module_key
  ) THEN
    RAISE EXCEPTION 'Technical module dependency cycle detected';
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER technical_module_dependencies_no_cycles
BEFORE INSERT OR UPDATE OF module_key, depends_on_module_key
ON public.technical_module_dependencies
FOR EACH ROW EXECUTE FUNCTION public.prevent_technical_module_dependency_cycle();

INSERT INTO public.technical_module_dependencies (
  module_key,
  depends_on_module_key,
  dependency_type,
  failure_effect,
  description
)
VALUES
  ('core.account', 'core.identity', 'required', 'down',
   'Profiles require the identity and access foundation.'),

  ('core.messaging', 'core.account', 'required', 'down',
   'Booking conversations require account identities.'),
  ('core.messaging', 'notifications', 'optional', 'degraded',
   'Notification delivery improves message awareness.'),

  ('mobility.taxi', 'core.account', 'required', 'down',
   'Taxi dispatch requires customer and provider accounts.'),
  ('mobility.taxi', 'core.catalog', 'required', 'down',
   'Taxi service availability is published through the service catalogue.'),
  ('mobility.taxi', 'core.messaging', 'optional', 'degraded',
   'Booking messaging is useful during live taxi work.'),
  ('mobility.taxi', 'notifications', 'optional', 'degraded',
   'Ride status notifications are supplementary.'),
  ('mobility.taxi', 'audit', 'optional', 'degraded',
   'Technical and operational audit improves traceability.'),

  ('mobility.water_transport', 'core.account', 'required', 'down',
   'Passenger bookings require account identities.'),
  ('mobility.water_transport', 'core.catalog', 'required', 'down',
   'Water transport is discovered through the service catalogue.'),
  ('mobility.water_transport', 'notifications', 'optional', 'degraded',
   'Trip notifications are supplementary.'),
  ('mobility.water_transport', 'audit', 'optional', 'degraded',
   'Technical and operational audit improves traceability.'),

  ('hire.vehicle', 'core.account', 'required', 'down',
   'Vehicle reservations require account identities.'),
  ('hire.vehicle', 'core.catalog', 'required', 'down',
   'Vehicle hire is discovered through the service catalogue.'),
  ('hire.vehicle', 'notifications', 'optional', 'degraded',
   'Reservation notifications are supplementary.'),
  ('hire.vehicle', 'audit', 'optional', 'degraded',
   'Technical and operational audit improves traceability.'),

  ('hire.boat', 'core.account', 'required', 'down',
   'Boat reservations require account identities.'),
  ('hire.boat', 'core.catalog', 'required', 'down',
   'Boat hire is discovered through the service catalogue.'),
  ('hire.boat', 'notifications', 'optional', 'degraded',
   'Reservation notifications are supplementary.'),
  ('hire.boat', 'audit', 'optional', 'degraded',
   'Technical and operational audit improves traceability.'),

  ('marketplace.specialist', 'core.account', 'required', 'down',
   'Specialist requests require account identities.'),
  ('marketplace.specialist', 'core.catalog', 'required', 'down',
   'Specialist services are discovered through the service catalogue.'),
  ('marketplace.specialist', 'core.messaging', 'optional', 'degraded',
   'Provider/customer messaging is supplementary.'),
  ('marketplace.specialist', 'notifications', 'optional', 'degraded',
   'Request notifications are supplementary.'),
  ('marketplace.specialist', 'audit', 'optional', 'degraded',
   'Technical and operational audit improves traceability.'),

  ('marketplace.general_labour', 'core.account', 'required', 'down',
   'General-labour requests require account identities.'),
  ('marketplace.general_labour', 'core.catalog', 'required', 'down',
   'General labour is discovered through the service catalogue.'),
  ('marketplace.general_labour', 'core.messaging', 'optional', 'degraded',
   'Provider/customer messaging is supplementary.'),
  ('marketplace.general_labour', 'notifications', 'optional', 'degraded',
   'Request notifications are supplementary.'),
  ('marketplace.general_labour', 'audit', 'optional', 'degraded',
   'Technical and operational audit improves traceability.'),

  ('places.venues', 'core.account', 'required', 'down',
   'Venue reservations require account identities.'),
  ('places.venues', 'core.catalog', 'required', 'down',
   'Venues are discovered through the service catalogue.'),
  ('places.venues', 'notifications', 'optional', 'degraded',
   'Reservation notifications are supplementary.'),
  ('places.venues', 'audit', 'optional', 'degraded',
   'Technical and operational audit improves traceability.'),

  ('events', 'core.account', 'required', 'down',
   'Event registrations require account identities.'),
  ('events', 'core.catalog', 'required', 'down',
   'Events participate in the shared service catalogue.'),
  ('events', 'notifications', 'optional', 'degraded',
   'Event notifications are supplementary.'),
  ('events', 'audit', 'optional', 'degraded',
   'Technical and operational audit improves traceability.'),

  ('commerce.food', 'core.account', 'required', 'down',
   'Food ordering requires account identities.'),
  ('commerce.food', 'core.catalog', 'required', 'down',
   'Food vendors are discovered through the shared catalogue.'),
  ('commerce.food', 'notifications', 'optional', 'degraded',
   'Order notifications are supplementary.'),
  ('commerce.food', 'audit', 'optional', 'degraded',
   'Technical and operational audit improves traceability.'),

  ('commerce.grocery', 'core.account', 'required', 'down',
   'Grocery ordering requires account identities.'),
  ('commerce.grocery', 'core.catalog', 'required', 'down',
   'Shops are discovered through the shared catalogue.'),
  ('commerce.grocery', 'notifications', 'optional', 'degraded',
   'Order notifications are supplementary.'),
  ('commerce.grocery', 'audit', 'optional', 'degraded',
   'Technical and operational audit improves traceability.'),

  ('delivery', 'core.account', 'required', 'down',
   'Delivery requests require account identities.'),
  ('delivery', 'core.catalog', 'required', 'down',
   'Delivery is discovered through the shared catalogue.'),
  ('delivery', 'core.messaging', 'optional', 'degraded',
   'Courier/customer messaging is supplementary.'),
  ('delivery', 'notifications', 'optional', 'degraded',
   'Delivery notifications are supplementary.'),
  ('delivery', 'audit', 'optional', 'degraded',
   'Technical and operational audit improves traceability.'),

  ('errands', 'core.account', 'required', 'down',
   'Errand requests require account identities.'),
  ('errands', 'core.catalog', 'required', 'down',
   'Errands are discovered through the shared catalogue.'),
  ('errands', 'core.messaging', 'optional', 'degraded',
   'Runner/customer messaging is supplementary.'),
  ('errands', 'notifications', 'optional', 'degraded',
   'Errand notifications are supplementary.'),
  ('errands', 'audit', 'optional', 'degraded',
   'Technical and operational audit improves traceability.'),

  ('payments', 'core.account', 'required', 'down',
   'Future payment movement requires account identities.'),
  ('payments', 'audit', 'required', 'down',
   'Payment movement requires an audit trail.'),
  ('payments', 'notifications', 'optional', 'degraded',
   'Payment notifications are supplementary.'),

  ('notifications', 'core.account', 'required', 'down',
   'User-directed notifications require account identities.')
ON CONFLICT (module_key, depends_on_module_key) DO UPDATE
SET dependency_type = excluded.dependency_type,
    failure_effect = excluded.failure_effect,
    description = excluded.description;

CREATE TABLE public.technical_module_health_probes (
  module_key text NOT NULL
    REFERENCES public.technical_modules(module_key) ON DELETE CASCADE,
  probe_key text NOT NULL
    CHECK (probe_key ~ '^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)*$'),
  name text NOT NULL,
  description text,
  probe_kind text NOT NULL
    CHECK (probe_kind IN (
      'control_state', 'heartbeat', 'database', 'integration', 'runtime'
    )),
  stale_after_seconds integer
    CHECK (stale_after_seconds IS NULL OR stale_after_seconds >= 30),
  is_required boolean NOT NULL DEFAULT true,
  is_enabled boolean NOT NULL DEFAULT true,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (module_key, probe_key)
);

CREATE TRIGGER technical_module_health_probes_set_updated_at
BEFORE UPDATE ON public.technical_module_health_probes
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TABLE public.technical_module_health_reports (
  module_key text NOT NULL,
  probe_key text NOT NULL,
  status text NOT NULL
    CHECK (status IN ('unknown', 'healthy', 'degraded', 'down')),
  summary text,
  details jsonb NOT NULL DEFAULT '{}'::jsonb,
  observed_at timestamptz NOT NULL DEFAULT now(),
  reported_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (module_key, probe_key),
  FOREIGN KEY (module_key, probe_key)
    REFERENCES public.technical_module_health_probes(module_key, probe_key)
    ON DELETE CASCADE
);

CREATE INDEX technical_module_health_reports_observed_idx
  ON public.technical_module_health_reports (module_key, observed_at DESC);

CREATE TABLE public.technical_module_health_state (
  module_key text PRIMARY KEY
    REFERENCES public.technical_modules(module_key) ON DELETE CASCADE,
  reported_status text NOT NULL DEFAULT 'unknown'
    CHECK (reported_status IN ('unknown', 'healthy', 'degraded', 'down')),
  effective_status text NOT NULL DEFAULT 'unknown'
    CHECK (effective_status IN ('unknown', 'healthy', 'degraded', 'down')),
  last_report_at timestamptz,
  last_evaluated_at timestamptz NOT NULL DEFAULT now(),
  summary text
);

CREATE TABLE public.technical_module_health_history (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  module_key text NOT NULL
    REFERENCES public.technical_modules(module_key) ON DELETE CASCADE,
  previous_reported_status text
    CHECK (
      previous_reported_status IS NULL OR
      previous_reported_status IN ('unknown', 'healthy', 'degraded', 'down')
    ),
  reported_status text NOT NULL
    CHECK (reported_status IN ('unknown', 'healthy', 'degraded', 'down')),
  previous_effective_status text
    CHECK (
      previous_effective_status IS NULL OR
      previous_effective_status IN ('unknown', 'healthy', 'degraded', 'down')
    ),
  effective_status text NOT NULL
    CHECK (effective_status IN ('unknown', 'healthy', 'degraded', 'down')),
  transition_reason text NOT NULL,
  source_probe_key text,
  summary text,
  observed_at timestamptz,
  recorded_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX technical_module_health_history_module_time_idx
  ON public.technical_module_health_history (module_key, recorded_at DESC);

INSERT INTO public.technical_module_health_probes (
  module_key,
  probe_key,
  name,
  description,
  probe_kind,
  stale_after_seconds,
  is_required,
  is_enabled
)
SELECT
  module.module_key,
  'control.state',
  'Control-plane state',
  'Built-in probe that reflects enabled/maintenance state only.',
  'control_state',
  NULL,
  true,
  true
FROM public.technical_modules module
ON CONFLICT (module_key, probe_key) DO NOTHING;

INSERT INTO public.technical_module_health_reports (
  module_key,
  probe_key,
  status,
  summary,
  details,
  observed_at,
  reported_by
)
SELECT
  module.module_key,
  'control.state',
  CASE
    WHEN NOT module.is_enabled THEN 'unknown'
    WHEN module.maintenance_mode THEN 'degraded'
    ELSE 'healthy'
  END,
  CASE
    WHEN NOT module.is_enabled
      THEN 'Module is disabled; runtime health is not being asserted.'
    WHEN module.maintenance_mode
      THEN 'Module is in maintenance mode.'
    ELSE 'Control-plane state is available.'
  END,
  jsonb_build_object(
    'is_enabled', module.is_enabled,
    'maintenance_mode', module.maintenance_mode
  ),
  now(),
  NULL
FROM public.technical_modules module
ON CONFLICT (module_key, probe_key) DO UPDATE
SET status = excluded.status,
    summary = excluded.summary,
    details = excluded.details,
    observed_at = excluded.observed_at,
    reported_by = excluded.reported_by,
    updated_at = now();

CREATE OR REPLACE FUNCTION public.technical_health_rank(p_status text)
RETURNS integer
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE p_status
    WHEN 'healthy' THEN 0
    WHEN 'unknown' THEN 1
    WHEN 'degraded' THEN 2
    WHEN 'down' THEN 3
    ELSE 1
  END;
$$;

CREATE OR REPLACE FUNCTION public.technical_health_from_rank(p_rank integer)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE
    WHEN p_rank >= 3 THEN 'down'
    WHEN p_rank = 2 THEN 'degraded'
    WHEN p_rank = 1 THEN 'unknown'
    ELSE 'healthy'
  END;
$$;

CREATE OR REPLACE FUNCTION public.technical_module_reported_health(
  p_module_key text
)
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT public.technical_health_from_rank(
    coalesce(
      max(
        public.technical_health_rank(
          CASE
            WHEN report.observed_at IS NULL THEN 'unknown'
            WHEN probe.stale_after_seconds IS NOT NULL
             AND report.observed_at
                   + make_interval(secs => probe.stale_after_seconds) < now()
              THEN 'unknown'
            ELSE report.status
          END
        )
      ),
      1
    )
  )
  FROM public.technical_module_health_probes probe
  LEFT JOIN public.technical_module_health_reports report
    ON report.module_key = probe.module_key
   AND report.probe_key = probe.probe_key
  WHERE probe.module_key = p_module_key
    AND probe.is_enabled;
$$;

CREATE OR REPLACE FUNCTION public.technical_module_last_health_at(
  p_module_key text
)
RETURNS timestamptz
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT max(report.observed_at)
  FROM public.technical_module_health_reports report
  JOIN public.technical_module_health_probes probe
    ON probe.module_key = report.module_key
   AND probe.probe_key = report.probe_key
  WHERE report.module_key = p_module_key
    AND probe.is_enabled;
$$;

CREATE OR REPLACE FUNCTION public.technical_module_effective_health(
  p_module_key text
)
RETURNS text
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_module public.technical_modules%ROWTYPE;
  v_rank integer;
  v_dependency_rank integer := 0;
BEGIN
  SELECT *
  INTO v_module
  FROM public.technical_modules
  WHERE module_key = p_module_key;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Technical module not found';
  END IF;

  v_rank := public.technical_health_rank(
    public.technical_module_reported_health(p_module_key)
  );

  IF NOT v_module.is_enabled THEN
    v_rank := greatest(v_rank, 3);
  ELSIF v_module.maintenance_mode THEN
    v_rank := greatest(v_rank, 2);
  END IF;

  WITH RECURSIVE dependency_tree AS (
    SELECT
      dependency.depends_on_module_key AS dependency_key,
      dependency.failure_effect AS path_effect,
      ARRAY[p_module_key, dependency.depends_on_module_key]::text[] AS path
    FROM public.technical_module_dependencies dependency
    WHERE dependency.module_key = p_module_key

    UNION ALL

    SELECT
      dependency.depends_on_module_key,
      CASE
        WHEN dependency_tree.path_effect = 'degraded'
          OR dependency.failure_effect = 'degraded'
          THEN 'degraded'
        ELSE 'down'
      END,
      dependency_tree.path || dependency.depends_on_module_key
    FROM dependency_tree
    JOIN public.technical_module_dependencies dependency
      ON dependency.module_key = dependency_tree.dependency_key
    WHERE NOT dependency.depends_on_module_key = ANY(dependency_tree.path)
  )
  SELECT coalesce(
    max(
      CASE
        WHEN NOT dependency_module.is_enabled THEN
          CASE
            WHEN dependency_tree.path_effect = 'down' THEN 3
            ELSE 2
          END
        WHEN dependency_module.maintenance_mode THEN 2
        WHEN public.technical_module_reported_health(
               dependency_module.module_key
             ) = 'down' THEN
          CASE
            WHEN dependency_tree.path_effect = 'down' THEN 3
            ELSE 2
          END
        WHEN public.technical_module_reported_health(
               dependency_module.module_key
             ) = 'degraded' THEN 2
        WHEN public.technical_module_reported_health(
               dependency_module.module_key
             ) = 'unknown' THEN 1
        ELSE 0
      END
    ),
    0
  )
  INTO v_dependency_rank
  FROM dependency_tree
  JOIN public.technical_modules dependency_module
    ON dependency_module.module_key = dependency_tree.dependency_key;

  RETURN public.technical_health_from_rank(
    greatest(v_rank, v_dependency_rank)
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.refresh_technical_module_health_state_internal(
  p_module_key text,
  p_reason text,
  p_source_probe_key text DEFAULT NULL,
  p_observed_at timestamptz DEFAULT now(),
  p_cascade boolean DEFAULT true
)
RETURNS public.technical_module_health_state
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_had_old boolean;
  v_old public.technical_module_health_state%ROWTYPE;
  v_state public.technical_module_health_state%ROWTYPE;
  v_reported text;
  v_effective text;
  v_last_report_at timestamptz;
  v_summary text;
  v_dependent record;
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM public.technical_modules
    WHERE module_key = p_module_key
  ) THEN
    RAISE EXCEPTION 'Technical module not found';
  END IF;

  SELECT EXISTS (
    SELECT 1
    FROM public.technical_module_health_state
    WHERE module_key = p_module_key
  )
  INTO v_had_old;

  IF v_had_old THEN
    SELECT *
    INTO v_old
    FROM public.technical_module_health_state
    WHERE module_key = p_module_key;
  END IF;

  v_reported := public.technical_module_reported_health(p_module_key);
  v_effective := public.technical_module_effective_health(p_module_key);
  v_last_report_at := public.technical_module_last_health_at(p_module_key);

  SELECT CASE
    WHEN NOT module.is_enabled THEN
      'Module is disabled.'
    WHEN module.maintenance_mode THEN
      'Module is in maintenance mode.'
    WHEN v_effective IS DISTINCT FROM v_reported THEN
      'Dependency state is affecting effective module health.'
    WHEN v_reported = 'healthy' THEN
      'Registered health reporters are healthy.'
    WHEN v_reported = 'degraded' THEN
      'One or more registered health reporters are degraded.'
    WHEN v_reported = 'down' THEN
      'One or more registered health reporters are down.'
    ELSE
      'Health has not been fully established.'
  END
  INTO v_summary
  FROM public.technical_modules module
  WHERE module.module_key = p_module_key;

  INSERT INTO public.technical_module_health_state (
    module_key,
    reported_status,
    effective_status,
    last_report_at,
    last_evaluated_at,
    summary
  ) VALUES (
    p_module_key,
    v_reported,
    v_effective,
    v_last_report_at,
    now(),
    v_summary
  )
  ON CONFLICT (module_key) DO UPDATE
  SET reported_status = excluded.reported_status,
      effective_status = excluded.effective_status,
      last_report_at = excluded.last_report_at,
      last_evaluated_at = excluded.last_evaluated_at,
      summary = excluded.summary
  RETURNING * INTO v_state;

  IF NOT v_had_old
     OR v_old.reported_status IS DISTINCT FROM v_state.reported_status
     OR v_old.effective_status IS DISTINCT FROM v_state.effective_status THEN
    INSERT INTO public.technical_module_health_history (
      module_key,
      previous_reported_status,
      reported_status,
      previous_effective_status,
      effective_status,
      transition_reason,
      source_probe_key,
      summary,
      observed_at
    ) VALUES (
      p_module_key,
      CASE WHEN v_had_old THEN v_old.reported_status ELSE NULL END,
      v_state.reported_status,
      CASE WHEN v_had_old THEN v_old.effective_status ELSE NULL END,
      v_state.effective_status,
      p_reason,
      p_source_probe_key,
      v_state.summary,
      p_observed_at
    );
  END IF;

  IF p_cascade THEN
    FOR v_dependent IN
      WITH RECURSIVE dependents(module_key, path) AS (
        SELECT
          dependency.module_key,
          ARRAY[p_module_key, dependency.module_key]::text[]
        FROM public.technical_module_dependencies dependency
        WHERE dependency.depends_on_module_key = p_module_key

        UNION ALL

        SELECT
          dependency.module_key,
          dependents.path || dependency.module_key
        FROM dependents
        JOIN public.technical_module_dependencies dependency
          ON dependency.depends_on_module_key = dependents.module_key
        WHERE NOT dependency.module_key = ANY(dependents.path)
      )
      SELECT DISTINCT module_key
      FROM dependents
    LOOP
      PERFORM public.refresh_technical_module_health_state_internal(
        v_dependent.module_key,
        'dependency:' || p_module_key,
        p_source_probe_key,
        p_observed_at,
        false
      );
    END LOOP;
  END IF;

  RETURN v_state;
END;
$$;

CREATE OR REPLACE FUNCTION public.record_technical_module_health_report_internal(
  p_module_key text,
  p_probe_key text,
  p_status text,
  p_summary text,
  p_details jsonb,
  p_observed_at timestamptz,
  p_reported_by uuid
)
RETURNS public.technical_module_health_state
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_state public.technical_module_health_state%ROWTYPE;
  v_reported text;
BEGIN
  IF p_status NOT IN ('unknown', 'healthy', 'degraded', 'down') THEN
    RAISE EXCEPTION 'Invalid technical module health status';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.technical_module_health_probes probe
    WHERE probe.module_key = p_module_key
      AND probe.probe_key = p_probe_key
      AND probe.is_enabled
  ) THEN
    RAISE EXCEPTION 'Technical module health probe not found or disabled';
  END IF;

  IF p_details IS NULL OR jsonb_typeof(p_details) <> 'object' THEN
    RAISE EXCEPTION 'Health report details must be a JSON object';
  END IF;

  IF octet_length(p_details::text) > 32768 THEN
    RAISE EXCEPTION 'Health report details are too large';
  END IF;

  IF p_observed_at > now() + interval '5 minutes' THEN
    RAISE EXCEPTION 'Health report observation time is in the future';
  END IF;

  INSERT INTO public.technical_module_health_reports (
    module_key,
    probe_key,
    status,
    summary,
    details,
    observed_at,
    reported_by,
    updated_at
  ) VALUES (
    p_module_key,
    p_probe_key,
    p_status,
    nullif(left(coalesce(p_summary, ''), 500), ''),
    p_details,
    p_observed_at,
    p_reported_by,
    now()
  )
  ON CONFLICT (module_key, probe_key) DO UPDATE
  SET status = excluded.status,
      summary = excluded.summary,
      details = excluded.details,
      observed_at = excluded.observed_at,
      reported_by = excluded.reported_by,
      updated_at = now();

  v_reported := public.technical_module_reported_health(p_module_key);

  UPDATE public.technical_modules
  SET health_status = v_reported,
      last_health_at = public.technical_module_last_health_at(p_module_key)
  WHERE module_key = p_module_key;

  v_state := public.refresh_technical_module_health_state_internal(
    p_module_key,
    'probe:' || p_probe_key,
    p_probe_key,
    p_observed_at,
    true
  );

  RETURN v_state;
END;
$$;

UPDATE public.technical_modules module
SET health_status = public.technical_module_reported_health(module.module_key),
    last_health_at = public.technical_module_last_health_at(module.module_key);

DO $$
DECLARE
  v_module record;
BEGIN
  FOR v_module IN
    SELECT module_key
    FROM public.technical_modules
    ORDER BY module_key
  LOOP
    PERFORM public.refresh_technical_module_health_state_internal(
      v_module.module_key,
      'initialised',
      'control.state',
      now(),
      false
    );
  END LOOP;
END;
$$;

CREATE OR REPLACE FUNCTION public.sync_technical_module_control_state_health()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_status text;
  v_summary text;
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM public.technical_module_health_probes
    WHERE module_key = NEW.module_key
      AND probe_key = 'control.state'
      AND is_enabled
  ) THEN
    RETURN NEW;
  END IF;

  IF NOT NEW.is_enabled THEN
    v_status := 'unknown';
    v_summary := 'Module is disabled; runtime health is not being asserted.';
  ELSIF NEW.maintenance_mode THEN
    v_status := 'degraded';
    v_summary := 'Module is in maintenance mode.';
  ELSE
    v_status := 'healthy';
    v_summary := 'Control-plane state is available.';
  END IF;

  PERFORM public.record_technical_module_health_report_internal(
    NEW.module_key,
    'control.state',
    v_status,
    v_summary,
    jsonb_build_object(
      'is_enabled', NEW.is_enabled,
      'maintenance_mode', NEW.maintenance_mode
    ),
    now(),
    auth.uid()
  );

  RETURN NEW;
END;
$$;

CREATE TRIGGER technical_modules_sync_control_state_health
AFTER UPDATE OF is_enabled, maintenance_mode
ON public.technical_modules
FOR EACH ROW
WHEN (
  OLD.is_enabled IS DISTINCT FROM NEW.is_enabled
  OR OLD.maintenance_mode IS DISTINCT FROM NEW.maintenance_mode
)
EXECUTE FUNCTION public.sync_technical_module_control_state_health();

CREATE OR REPLACE FUNCTION public.refresh_health_after_dependency_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_module_key text;
BEGIN
  v_module_key := coalesce(NEW.module_key, OLD.module_key);

  IF v_module_key IS NOT NULL THEN
    PERFORM public.refresh_technical_module_health_state_internal(
      v_module_key,
      'dependency_registry_changed',
      NULL,
      now(),
      true
    );
  END IF;

  RETURN coalesce(NEW, OLD);
END;
$$;

CREATE TRIGGER technical_module_dependencies_refresh_health
AFTER INSERT OR UPDATE OR DELETE
ON public.technical_module_dependencies
FOR EACH ROW EXECUTE FUNCTION public.refresh_health_after_dependency_change();

CREATE OR REPLACE FUNCTION public.get_technical_module_health(
  p_module_key text
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
    p_module_key,
    public.technical_module_reported_health(p_module_key),
    public.technical_module_effective_health(p_module_key),
    public.technical_module_last_health_at(p_module_key),
    state.last_evaluated_at,
    CASE
      WHEN NOT module.is_enabled THEN 'Module is disabled.'
      WHEN module.maintenance_mode THEN 'Module is in maintenance mode.'
      WHEN public.technical_module_effective_health(p_module_key)
           IS DISTINCT FROM public.technical_module_reported_health(p_module_key)
        THEN 'Dependency state is affecting effective module health.'
      WHEN public.technical_module_reported_health(p_module_key) = 'healthy'
        THEN 'Registered health reporters are healthy.'
      WHEN public.technical_module_reported_health(p_module_key) = 'degraded'
        THEN 'One or more registered health reporters are degraded.'
      WHEN public.technical_module_reported_health(p_module_key) = 'down'
        THEN 'One or more registered health reporters are down.'
      ELSE 'Health has not been fully established.'
    END
  FROM public.technical_modules module
  LEFT JOIN public.technical_module_health_state state
    ON state.module_key = module.module_key
  WHERE module.module_key = p_module_key;
END;
$$;

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
      p_module_key, 'module.diagnostics', auth.uid()
    ) AS can_run
  FROM public.technical_module_health_probes probe
  LEFT JOIN public.technical_module_health_reports report
    ON report.module_key = probe.module_key
   AND report.probe_key = probe.probe_key
  WHERE probe.module_key = p_module_key
  ORDER BY probe.is_required DESC, probe.probe_key;
END;
$$;

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
    p_module_key, 'module.diagnostics', auth.uid()
  ) THEN
    RAISE EXCEPTION 'Technical module diagnostics permission required';
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
    dependency.description,
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

CREATE OR REPLACE FUNCTION public.list_technical_module_health_history(
  p_module_key text,
  p_limit integer DEFAULT 50
)
RETURNS TABLE (
  id bigint,
  previous_reported_status text,
  reported_status text,
  previous_effective_status text,
  effective_status text,
  transition_reason text,
  source_probe_key text,
  summary text,
  observed_at timestamptz,
  recorded_at timestamptz
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
    history.id,
    history.previous_reported_status,
    history.reported_status,
    history.previous_effective_status,
    history.effective_status,
    history.transition_reason,
    history.source_probe_key,
    history.summary,
    history.observed_at,
    history.recorded_at
  FROM public.technical_module_health_history history
  WHERE history.module_key = p_module_key
  ORDER BY history.recorded_at DESC, history.id DESC
  LIMIT greatest(1, least(coalesce(p_limit, 50), 200));
END;
$$;

CREATE OR REPLACE FUNCTION public.get_technical_module_state_impact(
  p_module_key text
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_result jsonb;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF NOT public.has_technical_permission(
    p_module_key, 'module.view', auth.uid()
  ) THEN
    RAISE EXCEPTION 'Technical module view permission required';
  END IF;

  WITH RECURSIVE impacted AS (
    SELECT
      dependency.module_key AS impacted_module_key,
      1 AS depth,
      dependency.failure_effect AS path_effect,
      ARRAY[p_module_key, dependency.module_key]::text[] AS path
    FROM public.technical_module_dependencies dependency
    WHERE dependency.depends_on_module_key = p_module_key

    UNION ALL

    SELECT
      dependency.module_key,
      impacted.depth + 1,
      CASE
        WHEN impacted.path_effect = 'degraded'
          OR dependency.failure_effect = 'degraded'
          THEN 'degraded'
        ELSE 'down'
      END,
      impacted.path || dependency.module_key
    FROM impacted
    JOIN public.technical_module_dependencies dependency
      ON dependency.depends_on_module_key = impacted.impacted_module_key
    WHERE NOT dependency.module_key = ANY(impacted.path)
  ),
  dedup AS (
    SELECT DISTINCT ON (impacted_module_key)
      impacted_module_key,
      depth,
      path_effect,
      path
    FROM impacted
    ORDER BY impacted_module_key, depth
  ),
  visibility AS (
    SELECT
      dedup.*,
      module.name,
      (
        public.is_technical_platform_admin(auth.uid())
        OR public.has_technical_permission(
          dedup.impacted_module_key,
          'module.view',
          auth.uid()
        )
      ) AS can_see
    FROM dedup
    JOIN public.technical_modules module
      ON module.module_key = dedup.impacted_module_key
  )
  SELECT jsonb_build_object(
    'module_key', p_module_key,
    'impacted_count', (SELECT count(*) FROM visibility),
    'visible_impacted',
      coalesce(
        (
          SELECT jsonb_agg(
            jsonb_build_object(
              'module_key', visibility.impacted_module_key,
              'name', visibility.name,
              'depth', visibility.depth,
              'failure_effect', visibility.path_effect,
              'path', to_jsonb(visibility.path)
            )
            ORDER BY visibility.depth, visibility.name
          )
          FROM visibility
          WHERE visibility.can_see
        ),
        '[]'::jsonb
      ),
    'hidden_impacted_count',
      (SELECT count(*) FROM visibility WHERE NOT visibility.can_see)
  )
  INTO v_result;

  RETURN v_result;
END;
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
    public.technical_module_effective_health(module.module_key),
    public.technical_module_last_health_at(module.module_key),
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

ALTER TABLE public.technical_module_dependencies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.technical_module_health_probes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.technical_module_health_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.technical_module_health_state ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.technical_module_health_history ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.technical_module_dependencies FROM anon, authenticated;
REVOKE ALL ON TABLE public.technical_module_health_probes FROM anon, authenticated;
REVOKE ALL ON TABLE public.technical_module_health_reports FROM anon, authenticated;
REVOKE ALL ON TABLE public.technical_module_health_state FROM anon, authenticated;
REVOKE ALL ON TABLE public.technical_module_health_history FROM anon, authenticated;

REVOKE ALL ON FUNCTION public.prevent_technical_module_dependency_cycle() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.technical_health_rank(text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.technical_health_from_rank(integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.technical_module_reported_health(text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.technical_module_last_health_at(text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.technical_module_effective_health(text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.refresh_technical_module_health_state_internal(
  text, text, text, timestamptz, boolean
) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.record_technical_module_health_report_internal(
  text, text, text, text, jsonb, timestamptz, uuid
) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.sync_technical_module_control_state_health() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.refresh_health_after_dependency_change() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_technical_module_health(text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.list_technical_module_health_probes(text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.run_technical_module_health_probe(text, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.list_technical_module_dependencies(text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.list_technical_module_health_history(text, integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_technical_module_state_impact(text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.list_my_technical_modules() FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.get_technical_module_health(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.list_technical_module_health_probes(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.run_technical_module_health_probe(text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.list_technical_module_dependencies(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.list_technical_module_health_history(text, integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_technical_module_state_impact(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.list_my_technical_modules() TO authenticated;

GRANT EXECUTE ON FUNCTION public.record_technical_module_health_report_internal(
  text, text, text, text, jsonb, timestamptz, uuid
) TO service_role;

COMMENT ON TABLE public.technical_module_dependencies IS
  'Explicit acyclic technical-module dependency graph managed through migrations.';
COMMENT ON TABLE public.technical_module_health_probes IS
  'Registered health probe/reporter definitions; no arbitrary SQL is stored.';
COMMENT ON TABLE public.technical_module_health_reports IS
  'Current report per registered module health probe.';
COMMENT ON TABLE public.technical_module_health_history IS
  'Append-only reported/effective module health transition history.';
