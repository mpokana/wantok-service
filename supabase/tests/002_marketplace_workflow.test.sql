begin;

create extension if not exists pgtap with schema extensions;
select plan(13);

insert into auth.users (
  id, aud, role, email, raw_user_meta_data, created_at, updated_at
) values
  ('10000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', 'customer-test@wantok.local', '{"full_name":"Customer Test"}'::jsonb, now(), now()),
  ('20000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', 'provider-test@wantok.local', '{"full_name":"Provider Test"}'::jsonb, now(), now()),
  ('30000000-0000-0000-0000-000000000003', 'authenticated', 'authenticated', 'outsider-test@wantok.local', '{"full_name":"Outsider Test"}'::jsonb, now(), now());

select is(
  (select count(*)::integer from public.profiles where id in (
    '10000000-0000-0000-0000-000000000001'::uuid,
    '20000000-0000-0000-0000-000000000002'::uuid,
    '30000000-0000-0000-0000-000000000003'::uuid
  )),
  3,
  'auth user trigger creates three profiles'
);

select is(
  (select count(*)::integer from public.user_roles where role_code = 'customer' and user_id in (
    '10000000-0000-0000-0000-000000000001'::uuid,
    '20000000-0000-0000-0000-000000000002'::uuid,
    '30000000-0000-0000-0000-000000000003'::uuid
  )),
  3,
  'new profiles receive customer RBAC role'
);

update public.profiles
set is_provider = true
where id = '20000000-0000-0000-0000-000000000002'::uuid;

insert into public.provider_profiles (
  provider_id, display_name, provider_type, verification_status, is_active
) values (
  '20000000-0000-0000-0000-000000000002',
  'Provider Test',
  'individual',
  'verified',
  true
);

insert into public.provider_services (
  id, provider_id, category_id, title, pricing_model, status
)
select
  '21000000-0000-0000-0000-000000000002'::uuid,
  '20000000-0000-0000-0000-000000000002'::uuid,
  id,
  'General Labour Provider',
  'quote',
  'active'
from public.service_categories
where slug = 'general-labour';

select ok(
  public.has_role('provider', '20000000-0000-0000-0000-000000000002'::uuid),
  'provider profile flag synchronises provider RBAC role'
);

set local role authenticated;
select set_config('request.jwt.claim.sub', '10000000-0000-0000-0000-000000000001', true);

with inserted_booking as (
  insert into public.service_bookings (
    customer_id, category_id, service_address, notes, requested_amount, currency
  )
  select
    auth.uid(),
    id,
    'Lae Test Area',
    'Need two verified workers for a one-day loading job.',
    200,
    'PGK'
  from public.service_categories
  where slug = 'general-labour'
  returning id
)
select set_config('wantok.test_booking_id', id::text, true)
from inserted_booking;

select is(
  (select count(*)::integer from public.service_bookings where id = current_setting('wantok.test_booking_id')::uuid),
  1,
  'customer can create and read own open service request'
);

select set_config('request.jwt.claim.sub', '30000000-0000-0000-0000-000000000003', true);
select is(
  (select count(*)::integer from public.service_bookings where id = current_setting('wantok.test_booking_id')::uuid),
  0,
  'unqualified authenticated user cannot see open marketplace request'
);

select set_config('request.jwt.claim.sub', '20000000-0000-0000-0000-000000000002', true);
select is(
  (select count(*)::integer from public.service_bookings where id = current_setting('wantok.test_booking_id')::uuid),
  1,
  'approved provider with active matching service can see open request'
);

select lives_ok(
  $$select public.submit_service_quote(
    current_setting('wantok.test_booking_id')::uuid,
    180,
    'Available tomorrow morning.',
    null
  )$$,
  'approved provider can submit quote through secured RPC'
);

select is(
  (select status from public.service_bookings where id = current_setting('wantok.test_booking_id')::uuid),
  'quoted',
  'first provider quote moves request to quoted status'
);

select set_config('request.jwt.claim.sub', '10000000-0000-0000-0000-000000000001', true);
select is(
  (select count(*)::integer from public.service_quotes where booking_id = current_setting('wantok.test_booking_id')::uuid and status = 'pending'),
  1,
  'customer can read pending quote on own request'
);

select lives_ok(
  $$select public.accept_service_quote((
    select id from public.service_quotes
    where booking_id = current_setting('wantok.test_booking_id')::uuid
      and provider_id = '20000000-0000-0000-0000-000000000002'::uuid
  ))$$,
  'customer can accept provider quote through secured RPC'
);

select is(
  (select status from public.service_bookings where id = current_setting('wantok.test_booking_id')::uuid),
  'confirmed',
  'accepted quote confirms booking'
);

select is(
  (select provider_id from public.service_bookings where id = current_setting('wantok.test_booking_id')::uuid),
  '20000000-0000-0000-0000-000000000002'::uuid,
  'accepted quote assigns provider to booking'
);

select is(
  (select quoted_amount from public.service_bookings where id = current_setting('wantok.test_booking_id')::uuid),
  180::numeric,
  'accepted quote amount is stored on booking'
);

reset role;
select * from finish();
rollback;
