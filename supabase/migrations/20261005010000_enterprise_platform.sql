-- Wantok Service enterprise shared platform layer
-- RBAC, auditability, notifications/outbox and payment-intent boundaries.

CREATE TABLE public.app_roles (
  code text PRIMARY KEY CHECK (code ~ '^[a-z][a-z0-9_]*$'),
  name text NOT NULL,
  description text,
  is_system boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO public.app_roles (code, name, description) VALUES
  ('customer', 'Customer', 'Can discover and book Wantok services.'),
  ('provider', 'Provider', 'Verified service provider account.'),
  ('driver', 'Driver', 'Approved mobility driver.'),
  ('admin', 'Administrator', 'Full application administration.'),
  ('operations', 'Operations', 'Operational oversight and fulfilment support.'),
  ('support', 'Support', 'Customer/provider support and case handling.'),
  ('finance', 'Finance', 'Payment, settlement and finance operations.'),
  ('moderator', 'Moderator', 'Marketplace content and safety moderation.')
ON CONFLICT (code) DO NOTHING;

CREATE TABLE public.user_roles (
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role_code text NOT NULL REFERENCES public.app_roles(code) ON DELETE RESTRICT,
  granted_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  granted_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz,
  PRIMARY KEY (user_id, role_code),
  CHECK (expires_at IS NULL OR expires_at > granted_at)
);

CREATE INDEX user_roles_role_active_idx
  ON public.user_roles (role_code, user_id)
  WHERE expires_at IS NULL;

CREATE OR REPLACE FUNCTION public.has_role(
  p_role text,
  p_user_id uuid DEFAULT auth.uid()
)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.user_roles AS ur
    WHERE ur.user_id = p_user_id
      AND ur.role_code = p_role
      AND (ur.expires_at IS NULL OR ur.expires_at > now())
  );
$$;

REVOKE ALL ON FUNCTION public.has_role(text, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.has_role(text, uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.is_admin(p_user_id uuid DEFAULT auth.uid())
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT
    public.has_role('admin', p_user_id)
    OR EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = p_user_id AND is_admin = true
    );
$$;

REVOKE ALL ON FUNCTION public.is_admin(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_admin(uuid) TO authenticated;

CREATE TABLE public.audit_events (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  occurred_at timestamptz NOT NULL DEFAULT now(),
  actor_user_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  action text NOT NULL,
  entity_type text NOT NULL,
  entity_id uuid,
  request_id text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb
);

CREATE INDEX audit_events_entity_idx
  ON public.audit_events (entity_type, entity_id, occurred_at DESC);
CREATE INDEX audit_events_actor_idx
  ON public.audit_events (actor_user_id, occurred_at DESC);
CREATE INDEX audit_events_occurred_idx
  ON public.audit_events (occurred_at DESC);

CREATE OR REPLACE FUNCTION public.write_audit_event(
  p_action text,
  p_entity_type text,
  p_entity_id uuid DEFAULT NULL,
  p_metadata jsonb DEFAULT '{}'::jsonb,
  p_actor_user_id uuid DEFAULT auth.uid()
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  INSERT INTO public.audit_events (
    actor_user_id, action, entity_type, entity_id, metadata
  ) VALUES (
    p_actor_user_id, p_action, p_entity_type, p_entity_id,
    COALESCE(p_metadata, '{}'::jsonb)
  );
END;
$$;

REVOKE ALL ON FUNCTION public.write_audit_event(text, text, uuid, jsonb, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.write_audit_event(text, text, uuid, jsonb, uuid) TO service_role;

CREATE OR REPLACE FUNCTION public.audit_status_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_old_status text := to_jsonb(OLD) ->> 'status';
  v_new_status text := to_jsonb(NEW) ->> 'status';
BEGIN
  IF v_old_status IS DISTINCT FROM v_new_status THEN
    PERFORM public.write_audit_event(
      'status_changed',
      TG_ARGV[0],
      NEW.id,
      jsonb_build_object('from', v_old_status, 'to', v_new_status),
      auth.uid()
    );
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER provider_applications_audit_status
AFTER UPDATE OF status ON public.provider_applications
FOR EACH ROW EXECUTE FUNCTION public.audit_status_change('provider_application');

CREATE TRIGGER provider_services_audit_status
AFTER UPDATE OF status ON public.provider_services
FOR EACH ROW EXECUTE FUNCTION public.audit_status_change('provider_service');

CREATE TRIGGER provider_resources_audit_status
AFTER UPDATE OF status ON public.provider_resources
FOR EACH ROW EXECUTE FUNCTION public.audit_status_change('provider_resource');

CREATE TRIGGER service_bookings_audit_status
AFTER UPDATE OF status ON public.service_bookings
FOR EACH ROW EXECUTE FUNCTION public.audit_status_change('service_booking');

CREATE TRIGGER rides_audit_status
AFTER UPDATE OF status ON public.rides
FOR EACH ROW EXECUTE FUNCTION public.audit_status_change('ride');

CREATE TABLE public.notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  recipient_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  notification_type text NOT NULL,
  title text NOT NULL,
  body text NOT NULL,
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  read_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX notifications_recipient_unread_idx
  ON public.notifications (recipient_id, created_at DESC)
  WHERE read_at IS NULL;

CREATE TABLE public.notification_outbox (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  recipient_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  channel text NOT NULL CHECK (channel IN ('push', 'email', 'sms', 'in_app')),
  template_key text NOT NULL,
  payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'processing', 'sent', 'failed', 'cancelled')),
  idempotency_key text UNIQUE,
  attempts integer NOT NULL DEFAULT 0 CHECK (attempts >= 0),
  available_at timestamptz NOT NULL DEFAULT now(),
  processed_at timestamptz,
  last_error text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX notification_outbox_pending_idx
  ON public.notification_outbox (available_at, created_at)
  WHERE status = 'pending';

CREATE TRIGGER notification_outbox_set_updated_at
BEFORE UPDATE ON public.notification_outbox
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE OR REPLACE FUNCTION public.enqueue_notification(
  p_recipient_id uuid,
  p_notification_type text,
  p_title text,
  p_body text,
  p_data jsonb DEFAULT '{}'::jsonb,
  p_channel text DEFAULT 'in_app',
  p_template_key text DEFAULT 'generic',
  p_idempotency_key text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_notification_id uuid;
BEGIN
  INSERT INTO public.notifications (
    recipient_id, notification_type, title, body, data
  ) VALUES (
    p_recipient_id, p_notification_type, p_title, p_body,
    COALESCE(p_data, '{}'::jsonb)
  )
  RETURNING id INTO v_notification_id;

  INSERT INTO public.notification_outbox (
    recipient_id, channel, template_key, payload, idempotency_key
  ) VALUES (
    p_recipient_id, p_channel, p_template_key,
    jsonb_build_object(
      'notification_id', v_notification_id,
      'title', p_title,
      'body', p_body,
      'data', COALESCE(p_data, '{}'::jsonb)
    ),
    p_idempotency_key
  )
  ON CONFLICT (idempotency_key) DO NOTHING;

  RETURN v_notification_id;
END;
$$;

REVOKE ALL ON FUNCTION public.enqueue_notification(uuid, text, text, text, jsonb, text, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.enqueue_notification(uuid, text, text, text, jsonb, text, text, text) TO service_role;

CREATE TABLE public.payment_intents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  provider_id uuid REFERENCES public.provider_profiles(provider_id) ON DELETE SET NULL,
  ride_id uuid REFERENCES public.rides(id) ON DELETE RESTRICT,
  booking_id uuid REFERENCES public.service_bookings(id) ON DELETE RESTRICT,
  amount numeric(14,2) NOT NULL CHECK (amount > 0),
  currency text NOT NULL DEFAULT 'PGK' CHECK (char_length(currency) = 3),
  payment_method text NOT NULL
    CHECK (payment_method IN ('cash', 'card', 'mobile_money', 'bank_transfer', 'wallet', 'other')),
  processor text,
  external_reference text,
  status text NOT NULL DEFAULT 'created'
    CHECK (status IN (
      'created', 'pending', 'authorized', 'captured',
      'failed', 'cancelled', 'partially_refunded', 'refunded'
    )),
  idempotency_key text NOT NULL UNIQUE,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  captured_at timestamptz,
  CHECK (num_nonnulls(ride_id, booking_id) = 1)
);

CREATE INDEX payment_intents_customer_created_idx
  ON public.payment_intents (customer_id, created_at DESC);
CREATE INDEX payment_intents_provider_created_idx
  ON public.payment_intents (provider_id, created_at DESC);
CREATE INDEX payment_intents_status_idx
  ON public.payment_intents (status, created_at);

CREATE TRIGGER payment_intents_set_updated_at
BEFORE UPDATE ON public.payment_intents
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER payment_intents_audit_status
AFTER UPDATE OF status ON public.payment_intents
FOR EACH ROW EXECUTE FUNCTION public.audit_status_change('payment_intent');

CREATE TABLE public.payment_events (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  payment_intent_id uuid NOT NULL REFERENCES public.payment_intents(id) ON DELETE CASCADE,
  event_type text NOT NULL,
  processor text,
  external_event_id text,
  status text,
  amount numeric(14,2),
  payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE NULLS NOT DISTINCT (processor, external_event_id)
);

CREATE INDEX payment_events_intent_idx
  ON public.payment_events (payment_intent_id, created_at);

CREATE TABLE public.provider_settlements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id uuid NOT NULL REFERENCES public.provider_profiles(provider_id) ON DELETE RESTRICT,
  period_start timestamptz NOT NULL,
  period_end timestamptz NOT NULL,
  gross_amount numeric(14,2) NOT NULL DEFAULT 0 CHECK (gross_amount >= 0),
  platform_fee numeric(14,2) NOT NULL DEFAULT 0 CHECK (platform_fee >= 0),
  adjustment_amount numeric(14,2) NOT NULL DEFAULT 0,
  net_amount numeric(14,2) GENERATED ALWAYS AS
    (gross_amount - platform_fee + adjustment_amount) STORED,
  currency text NOT NULL DEFAULT 'PGK' CHECK (char_length(currency) = 3),
  status text NOT NULL DEFAULT 'draft'
    CHECK (status IN ('draft', 'approved', 'processing', 'paid', 'failed', 'cancelled')),
  payout_reference text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  paid_at timestamptz,
  CHECK (period_end > period_start)
);

CREATE INDEX provider_settlements_provider_period_idx
  ON public.provider_settlements (provider_id, period_end DESC);

CREATE TRIGGER provider_settlements_set_updated_at
BEFORE UPDATE ON public.provider_settlements
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER provider_settlements_audit_status
AFTER UPDATE OF status ON public.provider_settlements
FOR EACH ROW EXECUTE FUNCTION public.audit_status_change('provider_settlement');

CREATE TABLE public.provider_settlement_items (
  settlement_id uuid NOT NULL REFERENCES public.provider_settlements(id) ON DELETE CASCADE,
  payment_intent_id uuid NOT NULL REFERENCES public.payment_intents(id) ON DELETE RESTRICT,
  gross_amount numeric(14,2) NOT NULL CHECK (gross_amount >= 0),
  platform_fee numeric(14,2) NOT NULL DEFAULT 0 CHECK (platform_fee >= 0),
  net_amount numeric(14,2) GENERATED ALWAYS AS
    (gross_amount - platform_fee) STORED,
  PRIMARY KEY (settlement_id, payment_intent_id)
);

CREATE TABLE public.user_devices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  platform text NOT NULL CHECK (platform IN ('android', 'ios', 'web')),
  push_token text NOT NULL UNIQUE,
  device_name text,
  app_version text,
  last_seen_at timestamptz NOT NULL DEFAULT now(),
  revoked_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX user_devices_user_active_idx
  ON public.user_devices (user_id, last_seen_at DESC)
  WHERE revoked_at IS NULL;

CREATE TRIGGER user_devices_set_updated_at
BEFORE UPDATE ON public.user_devices
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

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
END;
$$;

CREATE TRIGGER profiles_sync_roles
AFTER INSERT OR UPDATE OF is_provider, is_driver, is_admin
ON public.profiles
FOR EACH ROW EXECUTE FUNCTION public.sync_profile_roles();

INSERT INTO public.user_roles (user_id, role_code)
SELECT id, 'customer' FROM public.profiles
ON CONFLICT (user_id, role_code) DO NOTHING;

INSERT INTO public.user_roles (user_id, role_code)
SELECT id, 'provider' FROM public.profiles WHERE is_provider = true
ON CONFLICT (user_id, role_code) DO NOTHING;

INSERT INTO public.user_roles (user_id, role_code)
SELECT id, 'driver' FROM public.profiles WHERE is_driver = true
ON CONFLICT (user_id, role_code) DO NOTHING;

INSERT INTO public.user_roles (user_id, role_code)
SELECT id, 'admin' FROM public.profiles WHERE is_admin = true
ON CONFLICT (user_id, role_code) DO NOTHING;

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
  IF auth.uid() IS NULL OR NOT public.is_admin(auth.uid()) THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.app_roles WHERE code = p_role_code) THEN
    RAISE EXCEPTION 'Unknown role';
  END IF;

  INSERT INTO public.user_roles (user_id, role_code, granted_by, expires_at)
  VALUES (p_user_id, p_role_code, auth.uid(), p_expires_at)
  ON CONFLICT (user_id, role_code) DO UPDATE
  SET granted_by = EXCLUDED.granted_by,
      granted_at = now(),
      expires_at = EXCLUDED.expires_at
  RETURNING * INTO v_role;

  PERFORM public.write_audit_event(
    'role_granted', 'user_role', p_user_id,
    jsonb_build_object('role', p_role_code, 'expires_at', p_expires_at), auth.uid()
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
  IF auth.uid() IS NULL OR NOT public.is_admin(auth.uid()) THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  IF p_role_code = 'customer' THEN
    RAISE EXCEPTION 'The customer base role cannot be revoked';
  END IF;

  DELETE FROM public.user_roles
  WHERE user_id = p_user_id AND role_code = p_role_code;
  v_deleted := FOUND;

  IF v_deleted THEN
    PERFORM public.write_audit_event(
      'role_revoked', 'user_role', p_user_id,
      jsonb_build_object('role', p_role_code), auth.uid()
    );
  END IF;

  RETURN v_deleted;
END;
$$;

REVOKE ALL ON FUNCTION public.grant_user_role(uuid, text, timestamptz) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.revoke_user_role(uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.grant_user_role(uuid, text, timestamptz) TO authenticated;
GRANT EXECUTE ON FUNCTION public.revoke_user_role(uuid, text) TO authenticated;

ALTER TABLE public.app_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_outbox ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_intents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provider_settlements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provider_settlement_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_devices ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.app_roles FROM anon, authenticated;
REVOKE ALL ON TABLE public.user_roles FROM anon, authenticated;
REVOKE ALL ON TABLE public.audit_events FROM anon, authenticated;
REVOKE ALL ON TABLE public.notifications FROM anon, authenticated;
REVOKE ALL ON TABLE public.notification_outbox FROM anon, authenticated;
REVOKE ALL ON TABLE public.payment_intents FROM anon, authenticated;
REVOKE ALL ON TABLE public.payment_events FROM anon, authenticated;
REVOKE ALL ON TABLE public.provider_settlements FROM anon, authenticated;
REVOKE ALL ON TABLE public.provider_settlement_items FROM anon, authenticated;
REVOKE ALL ON TABLE public.user_devices FROM anon, authenticated;

GRANT SELECT ON TABLE public.app_roles TO authenticated;
GRANT SELECT ON TABLE public.user_roles TO authenticated;
GRANT SELECT ON TABLE public.audit_events TO authenticated;
GRANT SELECT ON TABLE public.notifications TO authenticated;
GRANT UPDATE (read_at) ON TABLE public.notifications TO authenticated;
GRANT SELECT ON TABLE public.notification_outbox TO authenticated;
GRANT SELECT ON TABLE public.payment_intents TO authenticated;
GRANT SELECT ON TABLE public.payment_events TO authenticated;
GRANT SELECT ON TABLE public.provider_settlements TO authenticated;
GRANT SELECT ON TABLE public.provider_settlement_items TO authenticated;
GRANT SELECT, INSERT ON TABLE public.user_devices TO authenticated;
GRANT UPDATE (platform, push_token, device_name, app_version, last_seen_at, revoked_at)
  ON TABLE public.user_devices TO authenticated;
GRANT DELETE ON TABLE public.user_devices TO authenticated;

CREATE POLICY app_roles_authenticated_read
ON public.app_roles
FOR SELECT TO authenticated
USING (true);

CREATE POLICY user_roles_read_own_or_admin
ON public.user_roles
FOR SELECT TO authenticated
USING (
  user_id = auth.uid()
  OR public.is_admin(auth.uid())
);

CREATE POLICY audit_events_privileged_read
ON public.audit_events
FOR SELECT TO authenticated
USING (
  public.is_admin(auth.uid())
  OR public.has_role('operations', auth.uid())
  OR public.has_role('support', auth.uid())
  OR public.has_role('finance', auth.uid())
);

CREATE POLICY notifications_read_own
ON public.notifications
FOR SELECT TO authenticated
USING (recipient_id = auth.uid());

CREATE POLICY notifications_mark_own_read
ON public.notifications
FOR UPDATE TO authenticated
USING (recipient_id = auth.uid())
WITH CHECK (recipient_id = auth.uid());

CREATE POLICY notification_outbox_privileged_read
ON public.notification_outbox
FOR SELECT TO authenticated
USING (
  public.is_admin(auth.uid())
  OR public.has_role('operations', auth.uid())
  OR public.has_role('support', auth.uid())
);

CREATE POLICY payment_intents_participant_read
ON public.payment_intents
FOR SELECT TO authenticated
USING (
  customer_id = auth.uid()
  OR provider_id = auth.uid()
  OR public.is_admin(auth.uid())
  OR public.has_role('finance', auth.uid())
  OR public.has_role('support', auth.uid())
);

CREATE POLICY payment_events_participant_read
ON public.payment_events
FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.payment_intents AS pi
    WHERE pi.id = payment_events.payment_intent_id
      AND (
        pi.customer_id = auth.uid()
        OR pi.provider_id = auth.uid()
        OR public.is_admin(auth.uid())
        OR public.has_role('finance', auth.uid())
        OR public.has_role('support', auth.uid())
      )
  )
);

CREATE POLICY provider_settlements_provider_or_finance_read
ON public.provider_settlements
FOR SELECT TO authenticated
USING (
  provider_id = auth.uid()
  OR public.is_admin(auth.uid())
  OR public.has_role('finance', auth.uid())
);

CREATE POLICY provider_settlement_items_provider_or_finance_read
ON public.provider_settlement_items
FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.provider_settlements AS ps
    WHERE ps.id = provider_settlement_items.settlement_id
      AND (
        ps.provider_id = auth.uid()
        OR public.is_admin(auth.uid())
        OR public.has_role('finance', auth.uid())
      )
  )
);

CREATE POLICY user_devices_read_own
ON public.user_devices
FOR SELECT TO authenticated
USING (user_id = auth.uid());

CREATE POLICY user_devices_insert_own
ON public.user_devices
FOR INSERT TO authenticated
WITH CHECK (user_id = auth.uid());

CREATE POLICY user_devices_update_own
ON public.user_devices
FOR UPDATE TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY user_devices_delete_own
ON public.user_devices
FOR DELETE TO authenticated
USING (user_id = auth.uid());
