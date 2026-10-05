begin;

create extension if not exists pgtap with schema extensions;
select plan(13);

insert into auth.users (
  id, aud, role, email, raw_user_meta_data, created_at, updated_at
) values
  ('40000000-0000-0000-0000-000000000004', 'authenticated', 'authenticated', 'reservation-customer@wantok.local', '{"full_name":"Reservation Customer"}'::jsonb, now(), now()),
  ('50000000-0000-0000-0000-000000000005', 'authenticated', 'authenticated', 'reservation-provider@wantok.local', '{"full_name":"Reservation Provider"}'::jsonb, now(), now());

select is(
  (select count(*)::integer from public.profiles where id in (
    '40000000-0000-0000-0000-000000000004'::uuid,
    '50000000-0000-0000-0000-000000000005'::uuid
  )),
  2,
  'auth trigger creates reservation test profiles'
);

update public.profiles
set is_provider = true
where id = '50000000-0000-0000-0000-000000000005'::uuid;

select ok(
  public.has_role('provider', '50000000-0000-0000-0000-000000000005'::uuid),
  'provider flag grants provider RBAC role'
);

insert into public.provider_profiles (
  provider_id, display_name, provider_type, verification_status, is_active
) values (
  '50000000-0000-0000-0000-000000000005',
  'Lae Hire Test',
  'business',
  'verified',
  true
);

insert into public.provider_services (
  id, provider_id, category_id, title, pricing_model, base_price, currency, status
)
select
  '51000000-0000-0000-0000-000000000005'::uuid,
  '50000000-0000-0000-0000-000000000005'::uuid,
  id,
  '4WD Daily Hire',
  'fixed',
  250,
  'PGK',
  'active'
from public.service_categories
where slug = 'vehicle-hire';

insert into public.provider_resources (
  id, provider_id, category_id, resource_type, name, capacity, address_text, status
)
select
  '52000000-0000-0000-0000-000000000005'::uuid,
  '50000000-0000-0000-0000-000000000005'::uuid,
  id,
  '4wd',
  'Toyota Hilux',
  5,
  'Lae, Morobe Province',
  'active'
from public.service_categories
where slug = 'vehicle-hire';

insert into public.provider_availability_rules (
  provider_id, category_id, resource_id, day_of_week,
  start_time, end_time, timezone, effective_from, effective_to
)
select
  '50000000-0000-0000-0000-000000000005'::uuid,
  id,
  '52000000-0000-0000-0000-000000000005'::uuid,
  1,
  '08:00',
  '17:00',
  'Pacific/Port_Moresby',
  '2030-01-01',
  '2030-12-31'
from public.service_categories
where slug = 'vehicle-hire';

insert into public.provider_time_off (
  provider_id, resource_id, starts_at, ends_at, reason
) values (
  '50000000-0000-0000-0000-000000000005'::uuid,
  '52000000-0000-0000-0000-000000000005'::uuid,
  '2030-01-07 14:00:00+10',
  '2030-01-07 15:00:00+10',
  'Maintenance'
);

select ok(
  public.is_resource_available(
    '52000000-0000-0000-0000-000000000005'::uuid,
    '2030-01-07 09:00:00+10',
    '2030-01-07 12:00:00+10',
    null
  ),
  'resource is available inside configured Monday schedule'
);

select ok(
  not public.is_resource_available(
    '52000000-0000-0000-0000-000000000005'::uuid,
    '2030-01-07 18:00:00+10',
    '2030-01-07 19:00:00+10',
    null
  ),
  'resource is unavailable outside configured schedule'
);

select ok(
  not public.is_resource_available(
    '52000000-0000-0000-0000-000000000005'::uuid,
    '2030-01-07 14:15:00+10',
    '2030-01-07 14:45:00+10',
    null
  ),
  'resource time-off blocks reservation availability'
);

set local role authenticated;
select set_config('request.jwt.claim.sub', '40000000-0000-0000-0000-000000000004', true);

select lives_ok(
  $$select public.create_resource_reservation(
    '51000000-0000-0000-0000-000000000005'::uuid,
    '52000000-0000-0000-0000-000000000005'::uuid,
    '2030-01-07 09:00:00+10',
    '2030-01-07 12:00:00+10',
    1,
    null,
    'Airport pickup vehicle hire test'
  )$$,
  'customer can create resource reservation through secured RPC'
);

select set_config(
  'wantok.reservation_booking_id',
  (
    select id::text
    from public.service_bookings
    where customer_id = '40000000-0000-0000-0000-000000000004'::uuid
      and resource_id = '52000000-0000-0000-0000-000000000005'::uuid
    order by created_at desc
    limit 1
  ),
  true
);

select is(
  (select status from public.service_bookings where id = current_setting('wantok.reservation_booking_id')::uuid),
  'requested',
  'new resource reservation starts requested'
);

select is(
  (select provider_id from public.service_bookings where id = current_setting('wantok.reservation_booking_id')::uuid),
  '50000000-0000-0000-0000-000000000005'::uuid,
  'reservation is assigned to selected provider'
);

select is(
  (select requested_amount from public.service_bookings where id = current_setting('wantok.reservation_booking_id')::uuid),
  250::numeric,
  'fixed service starting amount is copied to reservation'
);

select set_config('request.jwt.claim.sub', '50000000-0000-0000-0000-000000000005', true);

select lives_ok(
  $$select public.provider_respond_service_booking(
    current_setting('wantok.reservation_booking_id')::uuid,
    true
  )$$,
  'provider can confirm an available resource reservation'
);

select is(
  (select status from public.service_bookings where id = current_setting('wantok.reservation_booking_id')::uuid),
  'confirmed',
  'provider confirmation moves reservation to confirmed'
);

select set_config('request.jwt.claim.sub', '40000000-0000-0000-0000-000000000004', true);

select ok(
  not public.is_resource_available(
    '52000000-0000-0000-0000-000000000005'::uuid,
    '2030-01-07 10:00:00+10',
    '2030-01-07 11:00:00+10',
    null
  ),
  'confirmed booking blocks overlapping availability'
);

select throws_ok(
  $$select public.create_resource_reservation(
    '51000000-0000-0000-0000-000000000005'::uuid,
    '52000000-0000-0000-0000-000000000005'::uuid,
    '2030-01-07 10:00:00+10',
    '2030-01-07 11:00:00+10',
    1,
    null,
    null
  )$$,
  'P0001',
  'Resource is not available for the requested time',
  'overlapping confirmed reservation is rejected'
);

reset role;
select * from finish();
rollback;
