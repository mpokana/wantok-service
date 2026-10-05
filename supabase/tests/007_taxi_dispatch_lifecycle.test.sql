begin;

create extension if not exists pgtap with schema extensions;
select plan(24);

insert into auth.users (
  id, aud, role, email, raw_user_meta_data, created_at, updated_at
) values
  ('91000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', 'taxi-passenger@wantok.local', '{"full_name":"Taxi Passenger"}'::jsonb, now(), now()),
  ('92000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', 'taxi-driver-one@wantok.local', '{"full_name":"Driver One"}'::jsonb, now(), now()),
  ('93000000-0000-0000-0000-000000000003', 'authenticated', 'authenticated', 'taxi-driver-two@wantok.local', '{"full_name":"Driver Two"}'::jsonb, now(), now());

update public.profiles
set is_provider = true,
    is_driver = true,
    is_driver_approved = true
where id in (
  '92000000-0000-0000-0000-000000000002'::uuid,
  '93000000-0000-0000-0000-000000000003'::uuid
);

insert into public.driver_profiles (
  driver_id, vehicle_rego, vehicle_make, vehicle_model, vehicle_colour
) values
  ('92000000-0000-0000-0000-000000000002', 'TAX 001', 'Toyota', 'Prius', 'White'),
  ('93000000-0000-0000-0000-000000000003', 'TAX 002', 'Toyota', 'Corolla', 'Silver');

insert into public.driver_locations (
  driver_id, lat, lng, is_online
) values
  ('92000000-0000-0000-0000-000000000002', -6.7310, 147.0020, true),
  ('93000000-0000-0000-0000-000000000003', -6.7500, 147.0200, true);

select ok(
  public.has_role(
    'driver',
    '92000000-0000-0000-0000-000000000002'::uuid
  ),
  'driver one has authoritative driver role'
);

select ok(
  public.has_role(
    'driver',
    '93000000-0000-0000-0000-000000000003'::uuid
  ),
  'driver two has authoritative driver role'
);

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '91000000-0000-0000-0000-000000000001',
  true
);

select is(
  (select count(*)::integer from public.driver_locations),
  0,
  'passenger cannot browse online driver locations'
);

select ok(
  not has_function_privilege(
    'authenticated',
    'public.list_available_drivers()',
    'EXECUTE'
  ),
  'legacy driver discovery RPC is not executable by authenticated users'
);

select lives_ok(
  $$select public.request_taxi_ride(
    -6.7320, 147.0000,
    -6.7200, 147.0100,
    'Eriku, Lae',
    'Top Town, Lae'
  )$$,
  'passenger can request a taxi ride'
);

select set_config(
  'wantok.taxi_ride_id',
  (
    select id::text
    from public.rides
    where passenger_id = auth.uid()
    order by created_at desc
    limit 1
  ),
  true
);

select is(
  (
    select status
    from public.rides
    where id = current_setting('wantok.taxi_ride_id')::uuid
  ),
  'pending',
  'new taxi ride starts pending'
);

select is(
  (
    select driver_id
    from public.rides
    where id = current_setting('wantok.taxi_ride_id')::uuid
  ),
  null::uuid,
  'pending ride does not assign driver before acceptance'
);

select ok(
  public.refresh_taxi_dispatch(
    current_setting('wantok.taxi_ride_id')::uuid
  ),
  'pending ride has an active driver offer'
);

select is(
  (
    select pickup_label
    from public.rides
    where id = current_setting('wantok.taxi_ride_id')::uuid
  ),
  'Eriku, Lae',
  'pickup label is stored'
);

select ok(
  (
    select fare_estimate >= 8
    from public.rides
    where id = current_setting('wantok.taxi_ride_id')::uuid
  ),
  'fare estimate is calculated'
);

select set_config(
  'request.jwt.claim.sub',
  '92000000-0000-0000-0000-000000000002',
  true
);

select is(
  public.get_driver_pending_ride_offer() ->> 'pickup_label',
  'Eriku, Lae',
  'offered driver can retrieve dispatch details'
);

select lives_ok(
  $$select public.driver_respond_taxi_offer(
    current_setting('wantok.taxi_ride_id')::uuid,
    false
  )$$,
  'first driver can decline ride'
);

select is(
  (
    select status
    from public.ride_driver_offers
    where ride_id = current_setting('wantok.taxi_ride_id')::uuid
      and driver_id = '92000000-0000-0000-0000-000000000002'::uuid
  ),
  'declined',
  'declined offer is recorded'
);

select set_config(
  'request.jwt.claim.sub',
  '93000000-0000-0000-0000-000000000003',
  true
);

select is(
  public.get_driver_pending_ride_offer() ->> 'ride_id',
  current_setting('wantok.taxi_ride_id'),
  'decline redispatches to next eligible driver'
);

select lives_ok(
  $$select public.driver_respond_taxi_offer(
    current_setting('wantok.taxi_ride_id')::uuid,
    true
  )$$,
  'second driver can accept ride'
);

select is(
  (
    select status
    from public.rides
    where id = current_setting('wantok.taxi_ride_id')::uuid
  ),
  'accepted',
  'accepted driver moves ride to accepted'
);

select is(
  (
    select driver_id
    from public.rides
    where id = current_setting('wantok.taxi_ride_id')::uuid
  ),
  '93000000-0000-0000-0000-000000000003'::uuid,
  'accepted driver is assigned to ride'
);

select throws_ok(
  $$select public.driver_update_taxi_status(
    current_setting('wantok.taxi_ride_id')::uuid,
    'completed'
  )$$,
  'P0001',
  'Invalid ride status transition',
  'driver cannot skip ride states'
);

select lives_ok(
  $$select public.driver_update_taxi_status(
    current_setting('wantok.taxi_ride_id')::uuid,
    'arriving'
  )$$,
  'driver can mark arriving'
);

select lives_ok(
  $$select public.driver_update_taxi_status(
    current_setting('wantok.taxi_ride_id')::uuid,
    'arrived'
  )$$,
  'driver can mark arrived'
);

select lives_ok(
  $$select public.driver_update_taxi_status(
    current_setting('wantok.taxi_ride_id')::uuid,
    'in_progress'
  )$$,
  'driver can start trip'
);

select lives_ok(
  $$select public.driver_update_taxi_status(
    current_setting('wantok.taxi_ride_id')::uuid,
    'completed'
  )$$,
  'driver can complete trip'
);

select is(
  (
    select status
    from public.rides
    where id = current_setting('wantok.taxi_ride_id')::uuid
  ),
  'completed',
  'ride completes through valid lifecycle'
);

select ok(
  (
    select final_fare = fare_estimate
    from public.rides
    where id = current_setting('wantok.taxi_ride_id')::uuid
  ),
  'completion records final fare'
);

reset role;
select * from finish();
rollback;
