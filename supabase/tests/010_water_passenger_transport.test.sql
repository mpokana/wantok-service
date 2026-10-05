begin;

create extension if not exists pgtap with schema extensions;
select plan(29);

insert into auth.users (
  id, aud, role, email, raw_user_meta_data, created_at, updated_at
) values
  ('c1000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', 'water-client@wantok.local', '{"full_name":"Water Client"}'::jsonb, now(), now()),
  ('c2000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', 'water-operator@wantok.local', '{"full_name":"Water Operator"}'::jsonb, now(), now()),
  ('c3000000-0000-0000-0000-000000000003', 'authenticated', 'authenticated', 'water-outsider@wantok.local', '{"full_name":"Water Outsider"}'::jsonb, now(), now());

update public.profiles
set is_provider = true
where id = 'c2000000-0000-0000-0000-000000000002'::uuid;

insert into public.provider_profiles (
  provider_id, provider_type, display_name, verification_status, is_active
) values (
  'c2000000-0000-0000-0000-000000000002',
  'business',
  'Wantok Marine Test',
  'verified',
  true
);

insert into public.provider_services (
  id, provider_id, category_id, title, pricing_model, currency, status
)
select
  'c2100000-0000-0000-0000-000000000010'::uuid,
  'c2000000-0000-0000-0000-000000000002'::uuid,
  id,
  'Wantok Marine Test',
  'per_person',
  'PGK',
  'active'
from public.service_categories
where slug = 'boat-ship-rides';

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  'c2000000-0000-0000-0000-000000000002',
  true
);

insert into public.water_routes (
  id, provider_id, provider_service_id, name,
  origin_name, destination_name, estimated_minutes, status
) values (
  'c2200000-0000-0000-0000-000000000020',
  'c2000000-0000-0000-0000-000000000002',
  'c2100000-0000-0000-0000-000000000010',
  'Lae to Finschhafen',
  'Lae',
  'Finschhafen',
  240,
  'active'
);

insert into public.water_vessels (
  id, provider_id, provider_service_id, name,
  registration_number, vessel_type, total_capacity, status
) values (
  'c2300000-0000-0000-0000-000000000030',
  'c2000000-0000-0000-0000-000000000002',
  'c2100000-0000-0000-0000-000000000010',
  'MV Wantok',
  'TEST-001',
  'ferry',
  5,
  'active'
);

insert into public.water_departures (
  id, provider_id, provider_service_id, route_id, vessel_id,
  departs_at, arrives_at, status, booking_open, boarding_point
) values (
  'c2400000-0000-0000-0000-000000000040',
  'c2000000-0000-0000-0000-000000000002',
  'c2100000-0000-0000-0000-000000000010',
  'c2200000-0000-0000-0000-000000000020',
  'c2300000-0000-0000-0000-000000000030',
  now() + interval '3 days',
  now() + interval '3 days 4 hours',
  'scheduled',
  true,
  'Lae Main Wharf'
);

insert into public.water_fare_classes (
  id, departure_id, name, price, currency, capacity, is_active, sort_order
) values
  (
    'c2500000-0000-0000-0000-000000000050',
    'c2400000-0000-0000-0000-000000000040',
    'Standard',
    60,
    'PGK',
    3,
    true,
    10
  ),
  (
    'c2500000-0000-0000-0000-000000000051',
    'c2400000-0000-0000-0000-000000000040',
    'Child',
    30,
    'PGK',
    2,
    true,
    20
  );

select ok(
  public.has_role(
    'provider',
    'c2000000-0000-0000-0000-000000000002'::uuid
  ),
  'water operator has provider role'
);

select set_config(
  'request.jwt.claim.sub',
  'c1000000-0000-0000-0000-000000000001',
  true
);

select is(
  (
    select count(*)::integer
    from public.water_routes
    where id = 'c2200000-0000-0000-0000-000000000020'
  ),
  1,
  'customer can read active route'
);

select is(
  (
    select count(*)::integer
    from public.water_departures
    where id = 'c2400000-0000-0000-0000-000000000040'
  ),
  1,
  'customer can read scheduled departure'
);

select is(
  (
    select count(*)::integer
    from public.water_fare_classes
    where departure_id = 'c2400000-0000-0000-0000-000000000040'
  ),
  2,
  'customer can read active fare classes'
);

select lives_ok(
  $$select public.book_water_departure(
    'c2400000-0000-0000-0000-000000000040',
    'c2500000-0000-0000-0000-000000000050',
    '[
      {"full_name":"Alice Passenger","passenger_type":"adult"},
      {"full_name":"Bob Passenger","passenger_type":"adult"}
    ]'::jsonb,
    '70000000',
    'Two bags'
  )$$,
  'customer can book scheduled water departure'
);

select set_config(
  'wantok.water_booking_id',
  (
    select id::text
    from public.water_passenger_bookings
    where customer_id = auth.uid()
    order by created_at desc
    limit 1
  ),
  true
);

select is(
  (
    select passenger_count
    from public.water_passenger_bookings
    where id = current_setting('wantok.water_booking_id')::uuid
  ),
  2,
  'booking stores passenger count'
);

select is(
  (
    select total_amount
    from public.water_passenger_bookings
    where id = current_setting('wantok.water_booking_id')::uuid
  ),
  120.00::numeric,
  'server calculates passenger booking total'
);

select is(
  (
    select count(*)::integer
    from public.water_booking_passengers
    where booking_id = current_setting('wantok.water_booking_id')::uuid
  ),
  2,
  'manifest stores individual passenger names'
);

select is(
  (
    select payment_status
    from public.water_passenger_bookings
    where id = current_setting('wantok.water_booking_id')::uuid
  ),
  'unpaid',
  'paid fare remains unpaid until payments layer is connected'
);

select throws_ok(
  $$insert into public.water_passenger_bookings (
    departure_id, fare_class_id, customer_id, provider_id,
    passenger_count, unit_fare, total_amount, currency
  ) values (
    'c2400000-0000-0000-0000-000000000040',
    'c2500000-0000-0000-0000-000000000050',
    auth.uid(),
    'c2000000-0000-0000-0000-000000000002',
    1,
    1,
    1,
    'PGK'
  )$$,
  '42501',
  null,
  'customer cannot insert booking directly'
);

select throws_ok(
  $$select public.book_water_departure(
    'c2400000-0000-0000-0000-000000000040',
    'c2500000-0000-0000-0000-000000000050',
    '[{"full_name":"C One"},{"full_name":"D Two"}]'::jsonb,
    null,
    null
  )$$,
  'P0001',
  'Fare class capacity exceeded',
  'fare class capacity is enforced'
);

select lives_ok(
  $$select public.book_water_departure(
    'c2400000-0000-0000-0000-000000000040',
    'c2500000-0000-0000-0000-000000000051',
    '[{"full_name":"Child One","passenger_type":"child"}]'::jsonb,
    null,
    null
  )$$,
  'customer can book another fare class'
);

select set_config(
  'wantok.child_booking_id',
  (
    select id::text
    from public.water_passenger_bookings
    where customer_id = auth.uid()
      and fare_class_id = 'c2500000-0000-0000-0000-000000000051'
    order by created_at desc
    limit 1
  ),
  true
);

select set_config(
  'request.jwt.claim.sub',
  'c3000000-0000-0000-0000-000000000003',
  true
);

select is(
  (
    select count(*)::integer
    from public.water_passenger_bookings
    where id = current_setting('wantok.water_booking_id')::uuid
  ),
  0,
  'outsider cannot read customer booking'
);

select set_config(
  'request.jwt.claim.sub',
  'c2000000-0000-0000-0000-000000000002',
  true
);

select is(
  (
    select count(*)::integer
    from public.water_passenger_bookings
    where departure_id = 'c2400000-0000-0000-0000-000000000040'
  ),
  2,
  'operator sees departure bookings'
);

select is(
  (
    select count(*)::integer
    from public.water_booking_passengers
    where booking_id = current_setting('wantok.water_booking_id')::uuid
  ),
  2,
  'operator sees manifest passenger rows'
);

select lives_ok(
  $$select public.vendor_set_water_departure_status(
    'c2400000-0000-0000-0000-000000000040',
    'boarding'
  )$$,
  'operator opens boarding'
);

select is(
  (
    select booking_open
    from public.water_departures
    where id = 'c2400000-0000-0000-0000-000000000040'
  ),
  false,
  'boarding closes new bookings'
);

select lives_ok(
  $$select public.vendor_set_water_booking_status(
    current_setting('wantok.water_booking_id')::uuid,
    'boarded'
  )$$,
  'operator boards passenger booking'
);

select is(
  (
    select status
    from public.water_passenger_bookings
    where id = current_setting('wantok.water_booking_id')::uuid
  ),
  'boarded',
  'boarded status is stored'
);

select lives_ok(
  $$select public.vendor_set_water_booking_status(
    current_setting('wantok.child_booking_id')::uuid,
    'no_show'
  )$$,
  'operator can mark no-show'
);

select lives_ok(
  $$select public.vendor_set_water_departure_status(
    'c2400000-0000-0000-0000-000000000040',
    'departed'
  )$$,
  'operator marks departure departed'
);

select lives_ok(
  $$select public.vendor_set_water_departure_status(
    'c2400000-0000-0000-0000-000000000040',
    'arrived'
  )$$,
  'operator marks departure arrived'
);

select is(
  (
    select status
    from public.water_passenger_bookings
    where id = current_setting('wantok.water_booking_id')::uuid
  ),
  'completed',
  'boarded booking completes when vessel arrives'
);

select is(
  (
    select status
    from public.water_passenger_bookings
    where id = current_setting('wantok.child_booking_id')::uuid
  ),
  'no_show',
  'no-show booking remains no-show at arrival'
);

select throws_ok(
  $$select public.vendor_set_water_departure_status(
    'c2400000-0000-0000-0000-000000000040',
    'boarding'
  )$$,
  'P0001',
  'Invalid water departure status transition',
  'operator cannot reverse arrived departure'
);

select set_config(
  'request.jwt.claim.sub',
  'c1000000-0000-0000-0000-000000000001',
  true
);

select throws_ok(
  $$select public.cancel_water_booking(
    current_setting('wantok.water_booking_id')::uuid,
    'Too late'
  )$$,
  'P0001',
  'Booking can no longer be cancelled',
  'completed booking cannot be cancelled'
);

select set_config(
  'request.jwt.claim.sub',
  'c2000000-0000-0000-0000-000000000002',
  true
);

insert into public.water_departures (
  id, provider_id, provider_service_id, route_id, vessel_id,
  departs_at, status, booking_open
) values (
  'c2400000-0000-0000-0000-000000000041',
  'c2000000-0000-0000-0000-000000000002',
  'c2100000-0000-0000-0000-000000000010',
  'c2200000-0000-0000-0000-000000000020',
  'c2300000-0000-0000-0000-000000000030',
  now() + interval '4 days',
  'scheduled',
  true
);

insert into public.water_fare_classes (
  id, departure_id, name, price, capacity
) values (
  'c2500000-0000-0000-0000-000000000052',
  'c2400000-0000-0000-0000-000000000041',
  'Standard',
  50,
  5
);

select set_config(
  'request.jwt.claim.sub',
  'c1000000-0000-0000-0000-000000000001',
  true
);

select lives_ok(
  $$select public.book_water_departure(
    'c2400000-0000-0000-0000-000000000041',
    'c2500000-0000-0000-0000-000000000052',
    '[{"full_name":"Cancel Me"}]'::jsonb,
    null,
    null
  )$$,
  'customer can create cancellable future booking'
);

select set_config(
  'wantok.cancel_water_booking_id',
  (
    select id::text
    from public.water_passenger_bookings
    where departure_id = 'c2400000-0000-0000-0000-000000000041'
      and customer_id = auth.uid()
    order by created_at desc
    limit 1
  ),
  true
);

select lives_ok(
  $$select public.cancel_water_booking(
    current_setting('wantok.cancel_water_booking_id')::uuid,
    'Plans changed'
  )$$,
  'customer can cancel future booked passage'
);

select is(
  (
    select status
    from public.water_passenger_bookings
    where id = current_setting('wantok.cancel_water_booking_id')::uuid
  ),
  'cancelled',
  'future booking cancellation is stored'
);

reset role;
select * from finish();
rollback;
