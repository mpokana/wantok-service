begin;

create extension if not exists pgtap with schema extensions;
select plan(33);

select has_column('public','water_passenger_bookings','trusted_person_id','water bookings include trusted-person source id');
select has_column('public','water_passenger_bookings','beneficiary_name','water bookings include beneficiary name');
select has_column('public','water_passenger_bookings','beneficiary_relationship','water bookings include beneficiary relationship');
select has_column('public','water_passenger_bookings','beneficiary_phone','water bookings include beneficiary phone');
select has_column('public','water_passenger_bookings','beneficiary_email','water bookings include beneficiary email');

insert into auth.users (
  id,aud,role,email,raw_user_meta_data,created_at,updated_at
) values
  ('f2200000-0000-0000-0000-000000000001','authenticated','authenticated','water-delegated-owner@wantok.local','{"full_name":"Water Booking Owner"}',now(),now()),
  ('f2200000-0000-0000-0000-000000000002','authenticated','authenticated','water-delegated-operator@wantok.local','{"full_name":"Water Delegated Operator"}',now(),now()),
  ('f2200000-0000-0000-0000-000000000003','authenticated','authenticated','water-delegated-other@wantok.local','{"full_name":"Other Water Account"}',now(),now());

update public.profiles
set is_provider=true
where id='f2200000-0000-0000-0000-000000000002'::uuid;

insert into public.provider_profiles(
  provider_id,provider_type,display_name,verification_status,is_active
) values (
  'f2200000-0000-0000-0000-000000000002',
  'business',
  'Delegated Water Operator',
  'verified',
  true
);

insert into public.provider_services(
  id,provider_id,category_id,title,pricing_model,currency,status
)
select
  'f2200000-0000-0000-0000-000000000010'::uuid,
  'f2200000-0000-0000-0000-000000000002'::uuid,
  id,
  'Delegated Water Service',
  'per_person',
  'PGK',
  'active'
from public.service_categories
where slug='boat-ship-rides';

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  'f2200000-0000-0000-0000-000000000002',
  true
);

insert into public.water_routes(
  id,provider_id,provider_service_id,name,
  origin_name,destination_name,status
) values (
  'f2200000-0000-0000-0000-000000000020',
  'f2200000-0000-0000-0000-000000000002',
  'f2200000-0000-0000-0000-000000000010',
  'Delegated Lae Coastal Route',
  'Lae',
  'Finschhafen',
  'active'
);

insert into public.water_vessels(
  id,provider_id,provider_service_id,name,
  registration_number,vessel_type,total_capacity,status
) values (
  'f2200000-0000-0000-0000-000000000030',
  'f2200000-0000-0000-0000-000000000002',
  'f2200000-0000-0000-0000-000000000010',
  'MV Delegated Wantok',
  'DLG-WATER-22',
  'ferry',
  10,
  'active'
);

insert into public.water_departures(
  id,provider_id,provider_service_id,route_id,vessel_id,
  departs_at,arrives_at,status,booking_open,boarding_point
) values (
  'f2200000-0000-0000-0000-000000000040',
  'f2200000-0000-0000-0000-000000000002',
  'f2200000-0000-0000-0000-000000000010',
  'f2200000-0000-0000-0000-000000000020',
  'f2200000-0000-0000-0000-000000000030',
  now()+interval '4 days',
  now()+interval '4 days 4 hours',
  'scheduled',
  true,
  'Lae Main Wharf'
);

insert into public.water_fare_classes(
  id,departure_id,name,price,currency,capacity,is_active
) values (
  'f2200000-0000-0000-0000-000000000050',
  'f2200000-0000-0000-0000-000000000040',
  'Standard',
  70,
  'PGK',
  10,
  true
);

reset role;

select set_config(
  'request.jwt.claim.sub',
  'f2200000-0000-0000-0000-000000000001',
  true
);

insert into public.trusted_people(
  id,owner_id,display_name,relationship,phone,email,is_active
) values
  (
    'f2200000-0000-0000-0000-000000000061',
    'f2200000-0000-0000-0000-000000000001',
    'Aunty Water Traveller',
    'Aunty',
    '+67570002261',
    'aunty.water@example.invalid',
    true
  ),
  (
    'f2200000-0000-0000-0000-000000000062',
    'f2200000-0000-0000-0000-000000000001',
    'Inactive Water Traveller',
    'Relative',
    '+67570002262',
    null,
    false
  ),
  (
    'f2200000-0000-0000-0000-000000000063',
    'f2200000-0000-0000-0000-000000000003',
    'Other Water Traveller',
    'Sibling',
    '+67570002263',
    null,
    true
  );

set local role authenticated;

select lives_ok(
  $$select public.book_water_departure(
    'f2200000-0000-0000-0000-000000000040',
    'f2200000-0000-0000-0000-000000000050',
    '[
      {
        "full_name":"Spoofed Primary Name",
        "phone":"+67579990000",
        "passenger_type":"adult",
        "document_reference":"PRIMARY-ID-22"
      },
      {
        "full_name":"Second Water Passenger",
        "phone":"+67570002299",
        "passenger_type":"adult",
        "document_reference":"SECOND-ID-22"
      }
    ]'::jsonb,
    null,
    'Delegated water booking',
    'f2200000-0000-0000-0000-000000000061'::uuid
  )$$,
  'customer can book scheduled water trip for own active trusted person'
);

select set_config(
  'wantok.delegated_water_booking_id',
  (
    select id::text
    from public.water_passenger_bookings
    where customer_id=auth.uid()
    order by created_at desc
    limit 1
  ),
  true
);

select is(
  (
    select customer_id
    from public.water_passenger_bookings
    where id=current_setting('wantok.delegated_water_booking_id')::uuid
  ),
  'f2200000-0000-0000-0000-000000000001'::uuid,
  'delegated water booking remains owned by signed-in account'
);

select is(
  (
    select trusted_person_id
    from public.water_passenger_bookings
    where id=current_setting('wantok.delegated_water_booking_id')::uuid
  ),
  'f2200000-0000-0000-0000-000000000061'::uuid,
  'water booking stores trusted-person source id'
);

select is(
  (
    select beneficiary_name
    from public.water_passenger_bookings
    where id=current_setting('wantok.delegated_water_booking_id')::uuid
  ),
  'Aunty Water Traveller',
  'water booking snapshots primary traveller name'
);

select is(
  (
    select beneficiary_relationship
    from public.water_passenger_bookings
    where id=current_setting('wantok.delegated_water_booking_id')::uuid
  ),
  'Aunty',
  'water booking snapshots primary traveller relationship'
);

select is(
  (
    select beneficiary_phone
    from public.water_passenger_bookings
    where id=current_setting('wantok.delegated_water_booking_id')::uuid
  ),
  '+67570002261',
  'water booking snapshots primary traveller phone'
);

select is(
  (
    select metadata->>'booked_for'
    from public.water_passenger_bookings
    where id=current_setting('wantok.delegated_water_booking_id')::uuid
  ),
  'trusted_person',
  'water booking metadata records trusted-person beneficiary'
);

select is(
  (
    select contact_phone
    from public.water_passenger_bookings
    where id=current_setting('wantok.delegated_water_booking_id')::uuid
  ),
  '+67570002261',
  'trusted-person phone becomes booking contact when no contact was supplied'
);

select is(
  (
    select passenger_count
    from public.water_passenger_bookings
    where id=current_setting('wantok.delegated_water_booking_id')::uuid
  ),
  2,
  'delegated water booking keeps complete passenger count'
);

select is(
  (
    select full_name
    from public.water_booking_passengers
    where booking_id=current_setting('wantok.delegated_water_booking_id')::uuid
      and metadata->>'trusted_person_primary'='true'
  ),
  'Aunty Water Traveller',
  'server replaces first manifest name with authorised trusted-person snapshot'
);

select is(
  (
    select metadata->>'trusted_person_primary'
    from public.water_booking_passengers
    where booking_id=current_setting('wantok.delegated_water_booking_id')::uuid
      and full_name='Aunty Water Traveller'
  ),
  'true',
  'primary manifest passenger is explicitly marked as trusted-person primary'
);

select is(
  (
    select phone
    from public.water_booking_passengers
    where booking_id=current_setting('wantok.delegated_water_booking_id')::uuid
      and full_name='Aunty Water Traveller'
  ),
  '+67570002261',
  'server replaces primary manifest phone with trusted-person phone'
);

select is(
  (
    select document_reference
    from public.water_booking_passengers
    where booking_id=current_setting('wantok.delegated_water_booking_id')::uuid
      and full_name='Aunty Water Traveller'
  ),
  'PRIMARY-ID-22',
  'primary passenger document reference remains supplied manifest data'
);

select is(
  (
    select count(*)::integer
    from public.water_booking_passengers
    where booking_id=current_setting('wantok.delegated_water_booking_id')::uuid
      and full_name='Second Water Passenger'
  ),
  1,
  'additional manifest passengers remain unchanged'
);

select set_config(
  'request.jwt.claim.sub',
  'f2200000-0000-0000-0000-000000000002',
  true
);

select is(
  (
    select count(*)::integer
    from public.water_passenger_bookings
    where id=current_setting('wantok.delegated_water_booking_id')::uuid
  ),
  1,
  'water operator can read delegated booking'
);

select is(
  (
    select full_name
    from public.water_booking_passengers
    where booking_id=current_setting('wantok.delegated_water_booking_id')::uuid
      and metadata->>'trusted_person_primary'='true'
  ),
  'Aunty Water Traveller',
  'water operator manifest sees actual trusted primary passenger'
);

select set_config(
  'request.jwt.claim.sub',
  'f2200000-0000-0000-0000-000000000001',
  true
);

select throws_ok(
  $$select public.book_water_departure(
    'f2200000-0000-0000-0000-000000000040',
    'f2200000-0000-0000-0000-000000000050',
    '[{"full_name":"Attempted Other Traveller"}]'::jsonb,
    null,
    null,
    'f2200000-0000-0000-0000-000000000063'::uuid
  )$$,
  'P0001',
  'Trusted person is not available',
  'water booking rejects another account trusted person'
);

select throws_ok(
  $$select public.book_water_departure(
    'f2200000-0000-0000-0000-000000000040',
    'f2200000-0000-0000-0000-000000000050',
    '[{"full_name":"Attempted Inactive Traveller"}]'::jsonb,
    null,
    null,
    'f2200000-0000-0000-0000-000000000062'::uuid
  )$$,
  'P0001',
  'Trusted person is not available',
  'water booking rejects inactive trusted person'
);

update public.trusted_people
set display_name='Aunty Water Traveller Updated',
    phone='+67579992261'
where id='f2200000-0000-0000-0000-000000000061'::uuid;

select is(
  (
    select beneficiary_name
    from public.water_passenger_bookings
    where id=current_setting('wantok.delegated_water_booking_id')::uuid
  ),
  'Aunty Water Traveller',
  'water beneficiary snapshot is unchanged after trusted-person edit'
);

delete from public.trusted_people
where id='f2200000-0000-0000-0000-000000000061'::uuid;

select is(
  (
    select trusted_person_id
    from public.water_passenger_bookings
    where id=current_setting('wantok.delegated_water_booking_id')::uuid
  ),
  null::uuid,
  'deleting trusted person clears water source foreign key'
);

select is(
  (
    select beneficiary_name
    from public.water_passenger_bookings
    where id=current_setting('wantok.delegated_water_booking_id')::uuid
  ),
  'Aunty Water Traveller',
  'historical water beneficiary snapshot survives source deletion'
);

select is(
  (
    select full_name
    from public.water_booking_passengers
    where booking_id=current_setting('wantok.delegated_water_booking_id')::uuid
      and metadata->>'trusted_person_primary'='true'
  ),
  'Aunty Water Traveller',
  'historical primary manifest snapshot survives trusted-person deletion'
);

select lives_ok(
  $$select public.cancel_water_booking(
    current_setting('wantok.delegated_water_booking_id')::uuid,
    'Finish delegated water test'
  )$$,
  'booking account retains water cancellation authority'
);

select lives_ok(
  $$select public.book_water_departure(
    'f2200000-0000-0000-0000-000000000040',
    'f2200000-0000-0000-0000-000000000050',
    '[{
      "full_name":"Self Water Passenger",
      "phone":"+67570002201",
      "passenger_type":"adult"
    }]'::jsonb,
    '+67570002201',
    'Self water booking',
    null
  )$$,
  'customer can still book scheduled water transport without trusted person'
);

select set_config(
  'wantok.self_water_booking_id',
  (
    select id::text
    from public.water_passenger_bookings
    where customer_id=auth.uid()
      and status='booked'
    order by created_at desc
    limit 1
  ),
  true
);

select is(
  (
    select trusted_person_id
    from public.water_passenger_bookings
    where id=current_setting('wantok.self_water_booking_id')::uuid
  ),
  null::uuid,
  'self water booking has no trusted-person source'
);

select is(
  (
    select beneficiary_name
    from public.water_passenger_bookings
    where id=current_setting('wantok.self_water_booking_id')::uuid
  ),
  null::text,
  'self water booking has no beneficiary snapshot'
);

select is(
  (
    select metadata->>'booked_for'
    from public.water_passenger_bookings
    where id=current_setting('wantok.self_water_booking_id')::uuid
  ),
  'self',
  'self water booking metadata records self'
);

select is(
  (
    select full_name
    from public.water_booking_passengers
    where booking_id=current_setting('wantok.self_water_booking_id')::uuid
  ),
  'Self Water Passenger',
  'self water manifest keeps customer-supplied passenger name'
);

reset role;
select * from finish();
rollback;
