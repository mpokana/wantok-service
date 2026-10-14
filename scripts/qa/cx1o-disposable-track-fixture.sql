-- CX1O: synthetic, disconnected PostgreSQL fixture. NOT a migration.
-- The auth.uid stub reads a local test GUC, NOT a verified GoTrue JWT.
-- No user/customer data, domain service credentials or live schema copies.
\set ON_ERROR_STOP on
CREATE SCHEMA IF NOT EXISTS auth;
CREATE OR REPLACE FUNCTION auth.uid() RETURNS uuid
LANGUAGE sql STABLE AS $func$
  SELECT nullif(current_setting('request.jwt.claim.sub', true), '')::uuid
$func$;
CREATE TABLE public.service_bookings (
  id uuid PRIMARY KEY,
  customer_id uuid NOT NULL,
  provider_id uuid,
  category_id uuid NOT NULL,
  status text NOT NULL,
  scheduled_start timestamptz,
  created_at timestamptz NOT NULL,
  notes text,
  beneficiary_email text,
  service_address text
);
CREATE TABLE public.provider_eligibility (
  provider_id uuid NOT NULL,
  category_id uuid NOT NULL,
  status text NOT NULL
);
CREATE OR REPLACE FUNCTION public.is_admin(p_uid uuid)
RETURNS boolean LANGUAGE sql STABLE AS $func$
  SELECT p_uid = '44444444-4444-4444-8444-444444444444'::uuid
$func$;
ALTER TABLE public.service_bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provider_eligibility ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.service_bookings, public.provider_eligibility FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.service_bookings, public.provider_eligibility TO authenticated;
CREATE POLICY stage_booking_participants ON public.service_bookings FOR SELECT TO authenticated
USING (customer_id = auth.uid() OR provider_id = auth.uid() OR public.is_admin(auth.uid()));
CREATE POLICY stage_booking_qualified_provider ON public.service_bookings FOR SELECT TO authenticated
USING (provider_id IS NULL AND status IN ('requested','quoted') AND EXISTS (
  SELECT 1 FROM public.provider_eligibility pe
  WHERE pe.provider_id = auth.uid() AND pe.category_id = service_bookings.category_id
    AND pe.status = 'active'
));
CREATE POLICY stage_provider_eligibility ON public.provider_eligibility FOR SELECT TO authenticated USING (true);
INSERT INTO public.provider_eligibility VALUES
('55555555-5555-4555-8555-555555555555','77777777-7777-4777-8777-777777777777','active');
INSERT INTO public.service_bookings
  (id, customer_id, provider_id, category_id, status, scheduled_start, created_at, notes, beneficiary_email, service_address)
VALUES
('a0000000-0000-4000-8000-000000000001','11111111-1111-4111-8111-111111111111',NULL,'77777777-7777-4777-8777-777777777777','completed',NULL,'2026-10-14T07:00:00Z','PRIVATE_A','synthetic-a@example.invalid','PRIVATE_ADDRESS_A'),
('b0000000-0000-4000-8000-000000000002','22222222-2222-4222-8222-222222222222','33333333-3333-4333-8333-333333333333','77777777-7777-4777-8777-777777777777','confirmed',NULL,'2026-10-14T08:00:00Z','PRIVATE_B','synthetic-b@example.invalid','PRIVATE_ADDRESS_B'),
('c0000000-0000-4000-8000-000000000003','22222222-2222-4222-8222-222222222222',NULL,'77777777-7777-4777-8777-777777777777','requested',NULL,'2026-10-14T09:00:00Z','PRIVATE_UNASSIGNED','synthetic-u@example.invalid','PRIVATE_ADDRESS_U');
INSERT INTO public.service_bookings
  (id, customer_id, category_id, status, created_at, notes)
SELECT ('d0000000-0000-4000-8000-' || lpad(to_hex(g),12,'0'))::uuid,
  '11111111-1111-4111-8111-111111111111'::uuid,
  '77777777-7777-4777-8777-777777777777'::uuid,'completed',
  '2026-10-13T00:00:00Z'::timestamptz + (g||' seconds')::interval,'PRIVATE_GENERATED_A'
FROM generate_series(1,105) g;

-- Hypothetical minimal contract, not connected to the Flutter Client.
-- RLS invoker + server-provided actor identity + explicit b.customer_id predicate.
CREATE OR REPLACE FUNCTION public.list_my_track_bookings_candidate()
RETURNS TABLE (booking_id uuid, booking_status text, scheduled_start timestamptz, created_at timestamptz)
LANGUAGE sql STABLE SECURITY INVOKER SET search_path = pg_catalog, public, auth
AS $func$
 SELECT b.id, b.status, b.scheduled_start, b.created_at
 FROM public.service_bookings b
 WHERE auth.uid() IS NOT NULL AND b.customer_id = auth.uid()
 ORDER BY b.created_at DESC, b.id DESC
 LIMIT 100
$func$;
REVOKE ALL ON FUNCTION public.list_my_track_bookings_candidate() FROM PUBLIC, anon, service_role;
GRANT USAGE ON SCHEMA public, auth TO authenticated, anon;
GRANT EXECUTE ON FUNCTION auth.uid() TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.is_admin(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.list_my_track_bookings_candidate() TO authenticated;
