begin;

create extension if not exists pgtap with schema extensions;
select plan(25);

select has_column('public', 'rides', 'trusted_person_id', 'rides include trusted-person source id');
select has_column('public', 'rides', 'beneficiary_name', 'rides include beneficiary name');
select has_column('public', 'rides', 'beneficiary_relationship', 'rides include beneficiary relationship');
select has_column('public', 'rides', 'beneficiary_phone', 'rides include beneficiary phone');
select has_column('public', 'rides', 'beneficiary_email', 'rides include beneficiary email');

insert into auth.users (
  id, aud, role, email, raw_user_meta_data, created_at, updated_at
) values
  (
    'd1900000-0000-0000-0000-000000000001',
    'authenticated',
    'authenticated',
    'taxi-delegated-owner@wantok.local',
    '{"full_name":"Taxi Booking Owner"}'::jsonb,
    now(),
    now()
  ),
  (
    'd1900000-0000-0000-0000-000000000002',
    'authenticated',
    'authenticated',
    'taxi-delegated-driver@wantok.local',
    '{"full_name":"Taxi Delegated Driver"}'::jsonb,
    now(),
    now()
  ),
  (
    'd1900000-0000-0000-0000-000000000003',
    'authenticated',
    'authenticated',
    'taxi-delegated-other@wantok.local',
    '{"full_name":"Other Taxi Account"}'::jsonb,
    now(),
    now()
  );

update public.profiles
set phone = case
  when id = 'd1900000-0000-0000-0000-000000000001'::uuid
    then '+67570001901'
  else phone
end
where id = 'd1900000-0000-0000-0000-000000000001'::uuid;

update public.profiles
set is_provider = true,
    is_driver = true,
    is_driver_approved = true
where id = 'd1900000-0000-0000-0000-000000000002'::uuid;

insert into public.driver_profiles (
  driver_id, vehicle_rego, vehicle_make, vehicle_model, vehicle_colour
) values (
  'd1900000-0000-0000-0000-000000000002',
  'DLG 019',
  'Toyota',
  'Corolla',
  'White'
);

insert into public.driver_locations (
  driver_id, lat, lng, is_online
) values (
  'd1900000-0000-0000-0000-000000000002',
  -6.7310,
  147.0020,
  true
);

insert into public.trusted_people (
  id, owner_id, display_name, relationship, phone, email, is_active
) values
  (
    'd1900000-0000-0000-0000-000000000021',
    'd1900000-0000-0000-0000-000000000001',
    'Aunty Taxi Rider',
    'Aunty',
    '+67570001921',
    'aunty.taxi@example.invalid',
    true
  ),
  (
    'd1900000-0000-0000-0000-000000000022',
    'd1900000-0000-0000-0000-000000000001',
    'Inactive Taxi Rider',
    'Relative',
    '+67570001922',
    null,
    false
  ),
  (
    'd1900000-0000-0000-0000-000000000023',
    'd1900000-0000-0000-0000-000000000003',
    'Other Account Rider',
    'Sibling',
    '+67570001923',
    null,
    true
  );

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  'd1900000-0000-0000-0000-000000000001',
  true
);

select lives_ok(
  $$select public.request_taxi_ride(
    -6.7320, 147.0000,
    -6.7200, 147.0100,
    'Eriku, Lae',
    'Top Town, Lae',
    'd1900000-0000-0000-0000-000000000021'::uuid
  )$$,
  'customer can request Taxi/Ride for own active trusted person'
);

select set_config(
  'wantok.delegated_taxi_ride_id',
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
    select passenger_id
    from public.rides
    where id = current_setting('wantok.delegated_taxi_ride_id')::uuid
  ),
  'd1900000-0000-0000-0000-000000000001'::uuid,
  'Taxi ride remains owned by signed-in booking account'
);

select is(
  (
    select trusted_person_id
    from public.rides
    where id = current_setting('wantok.delegated_taxi_ride_id')::uuid
  ),
  'd1900000-0000-0000-0000-000000000021'::uuid,
  'Taxi ride stores trusted-person source id'
);

select is(
  (
    select beneficiary_name
    from public.rides
    where id = current_setting('wantok.delegated_taxi_ride_id')::uuid
  ),
  'Aunty Taxi Rider',
  'Taxi ride snapshots actual rider name'
);

select is(
  (
    select beneficiary_phone
    from public.rides
    where id = current_setting('wantok.delegated_taxi_ride_id')::uuid
  ),
  '+67570001921',
  'Taxi ride snapshots actual rider phone'
);

select set_config(
  'request.jwt.claim.sub',
  'd1900000-0000-0000-0000-000000000002',
  true
);

select is(
  public.get_driver_pending_ride_offer() ->> 'passenger_name',
  'Aunty Taxi Rider',
  'offered driver sees actual delegated rider name'
);

select is(
  public.get_driver_pending_ride_offer() ->> 'booked_by_name',
  'Taxi Booking Owner',
  'offered driver can distinguish account holder who booked'
);

select is(
  public.get_driver_pending_ride_offer() ->> 'is_delegated',
  'true',
  'driver offer marks delegated ride'
);

select lives_ok(
  $$select public.driver_respond_taxi_offer(
    current_setting('wantok.delegated_taxi_ride_id')::uuid,
    true
  )$$,
  'driver can accept delegated ride'
);

select is(
  public.get_taxi_ride_details(
    current_setting('wantok.delegated_taxi_ride_id')::uuid
  ) ->> 'passenger_name',
  'Aunty Taxi Rider',
  'assigned driver ride details show actual rider'
);

select is(
  public.get_taxi_ride_details(
    current_setting('wantok.delegated_taxi_ride_id')::uuid
  ) ->> 'booked_by_name',
  'Taxi Booking Owner',
  'ride details preserve booking account name separately'
);

select set_config(
  'request.jwt.claim.sub',
  'd1900000-0000-0000-0000-000000000001',
  true
);

select throws_ok(
  $$select public.request_taxi_ride(
    -6.7320, 147.0000,
    -6.7100, 147.0150,
    'Eriku, Lae',
    'Lae Market',
    'd1900000-0000-0000-0000-000000000023'::uuid
  )$$,
  'P0001',
  'Trusted person is not available',
  'Taxi cannot use another account trusted person'
);

select throws_ok(
  $$select public.request_taxi_ride(
    -6.7320, 147.0000,
    -6.7100, 147.0150,
    'Eriku, Lae',
    'Lae Market',
    'd1900000-0000-0000-0000-000000000022'::uuid
  )$$,
  'P0001',
  'Trusted person is not available',
  'Taxi cannot use inactive trusted person'
);

update public.trusted_people
set display_name = 'Aunty Taxi Rider Updated',
    phone = '+67579991921'
where id = 'd1900000-0000-0000-0000-000000000021'::uuid;

select is(
  (
    select beneficiary_name
    from public.rides
    where id = current_setting('wantok.delegated_taxi_ride_id')::uuid
  ),
  'Aunty Taxi Rider',
  'Taxi beneficiary snapshot does not change after trusted-person edit'
);

delete from public.trusted_people
where id = 'd1900000-0000-0000-0000-000000000021'::uuid;

select is(
  (
    select trusted_person_id
    from public.rides
    where id = current_setting('wantok.delegated_taxi_ride_id')::uuid
  ),
  null::uuid,
  'deleting trusted person clears Taxi source foreign key'
);

select is(
  (
    select beneficiary_name
    from public.rides
    where id = current_setting('wantok.delegated_taxi_ride_id')::uuid
  ),
  'Aunty Taxi Rider',
  'historical Taxi beneficiary snapshot survives source deletion'
);

select lives_ok(
  $$select public.cancel_taxi_ride(
    current_setting('wantok.delegated_taxi_ride_id')::uuid,
    'Finish delegated-booking test'
  )$$,
  'booking account can cancel delegated ride before trip starts'
);

select lives_ok(
  $$select public.request_taxi_ride(
    -6.7320, 147.0000,
    -6.7150, 147.0180,
    'Eriku, Lae',
    'Lae Yacht Club',
    null
  )$$,
  'customer can still request Taxi/Ride for themselves'
);

select set_config(
  'wantok.self_taxi_ride_id',
  (
    select id::text
    from public.rides
    where passenger_id = auth.uid()
      and status = 'pending'
    order by created_at desc
    limit 1
  ),
  true
);

select is(
  public.get_taxi_ride_details(
    current_setting('wantok.self_taxi_ride_id')::uuid
  ) ->> 'passenger_name',
  'Taxi Booking Owner',
  'self Taxi ride uses account-holder rider name'
);

select is(
  public.get_taxi_ride_details(
    current_setting('wantok.self_taxi_ride_id')::uuid
  ) ->> 'is_delegated',
  'false',
  'self Taxi ride is not marked delegated'
);

reset role;
select * from finish();
rollback;
