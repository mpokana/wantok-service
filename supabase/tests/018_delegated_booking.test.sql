begin;

create extension if not exists pgtap with schema extensions;
select plan(25);

select has_column(
  'public', 'service_bookings', 'trusted_person_id',
  'service bookings include trusted-person source id'
);
select has_column(
  'public', 'service_bookings', 'beneficiary_name',
  'service bookings include beneficiary name snapshot'
);
select has_column(
  'public', 'service_bookings', 'beneficiary_relationship',
  'service bookings include beneficiary relationship snapshot'
);
select has_column(
  'public', 'service_bookings', 'beneficiary_phone',
  'service bookings include beneficiary phone snapshot'
);
select has_column(
  'public', 'service_bookings', 'beneficiary_email',
  'service bookings include beneficiary email snapshot'
);

insert into auth.users (
  id, aud, role, email, raw_user_meta_data, created_at, updated_at
) values
  ('d1800000-0000-0000-0000-000000000001', 'authenticated', 'authenticated',
   'delegated-owner@wantok.local', '{"full_name":"Delegated Owner"}'::jsonb, now(), now()),
  ('d1800000-0000-0000-0000-000000000002', 'authenticated', 'authenticated',
   'delegated-provider@wantok.local', '{"full_name":"Delegated Provider"}'::jsonb, now(), now()),
  ('d1800000-0000-0000-0000-000000000003', 'authenticated', 'authenticated',
   'delegated-other@wantok.local', '{"full_name":"Delegated Other"}'::jsonb, now(), now());

update public.profiles
set is_provider = true
where id = 'd1800000-0000-0000-0000-000000000002'::uuid;

insert into public.provider_profiles (
  provider_id, display_name, provider_type, verification_status, is_active
) values (
  'd1800000-0000-0000-0000-000000000002',
  'Delegated Hire Test',
  'business',
  'verified',
  true
);

insert into public.provider_services (
  id, provider_id, category_id, title, pricing_model, base_price, currency, status
)
select
  'd1800000-0000-0000-0000-000000000011'::uuid,
  'd1800000-0000-0000-0000-000000000002'::uuid,
  id,
  'Delegated Vehicle Hire',
  'fixed',
  175,
  'PGK',
  'active'
from public.service_categories
where slug = 'vehicle-hire';

insert into public.provider_resources (
  id, provider_id, category_id, resource_type, name, capacity, address_text, status
)
select
  'd1800000-0000-0000-0000-000000000012'::uuid,
  'd1800000-0000-0000-0000-000000000002'::uuid,
  id,
  'vehicle',
  'Delegated Test Vehicle',
  5,
  'Lae, Morobe Province',
  'active'
from public.service_categories
where slug = 'vehicle-hire';

insert into public.trusted_people (
  id, owner_id, display_name, relationship, phone, email, is_active
) values
  (
    'd1800000-0000-0000-0000-000000000021',
    'd1800000-0000-0000-0000-000000000001',
    'Aunty Mary',
    'Aunty',
    '+67570000021',
    'aunty.mary@example.invalid',
    true
  ),
  (
    'd1800000-0000-0000-0000-000000000022',
    'd1800000-0000-0000-0000-000000000001',
    'Inactive Relative',
    'Relative',
    '+67570000022',
    null,
    false
  ),
  (
    'd1800000-0000-0000-0000-000000000023',
    'd1800000-0000-0000-0000-000000000003',
    'Other Account Person',
    'Sibling',
    '+67570000023',
    null,
    true
  ),
  (
    'd1800000-0000-0000-0000-000000000024',
    'd1800000-0000-0000-0000-000000000001',
    'Uncle Joe',
    'Uncle',
    '+67570000024',
    'uncle.joe@example.invalid',
    true
  );

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  'd1800000-0000-0000-0000-000000000001',
  true
);

select lives_ok(
  $$select public.create_resource_reservation(
    'd1800000-0000-0000-0000-000000000011'::uuid,
    'd1800000-0000-0000-0000-000000000012'::uuid,
    '2031-02-03 09:00:00+10',
    '2031-02-03 12:00:00+10',
    1,
    'Lae Airport',
    'Pickup for Aunty Mary',
    'd1800000-0000-0000-0000-000000000021'::uuid
  )$$,
  'customer can create reservation for their active trusted person'
);

select set_config(
  'wantok.delegated_reservation_id',
  (
    select id::text
    from public.service_bookings
    where customer_id = 'd1800000-0000-0000-0000-000000000001'::uuid
      and resource_id = 'd1800000-0000-0000-0000-000000000012'::uuid
      and trusted_person_id = 'd1800000-0000-0000-0000-000000000021'::uuid
    order by created_at desc
    limit 1
  ),
  true
);

select is(
  (
    select customer_id
    from public.service_bookings
    where id = current_setting('wantok.delegated_reservation_id')::uuid
  ),
  'd1800000-0000-0000-0000-000000000001'::uuid,
  'delegated reservation remains owned by signed-in customer'
);

select is(
  (
    select trusted_person_id
    from public.service_bookings
    where id = current_setting('wantok.delegated_reservation_id')::uuid
  ),
  'd1800000-0000-0000-0000-000000000021'::uuid,
  'delegated reservation stores trusted-person source id'
);

select is(
  (
    select beneficiary_name
    from public.service_bookings
    where id = current_setting('wantok.delegated_reservation_id')::uuid
  ),
  'Aunty Mary',
  'delegated reservation snapshots beneficiary name'
);

select is(
  (
    select beneficiary_relationship
    from public.service_bookings
    where id = current_setting('wantok.delegated_reservation_id')::uuid
  ),
  'Aunty',
  'delegated reservation snapshots beneficiary relationship'
);

select is(
  (
    select beneficiary_phone
    from public.service_bookings
    where id = current_setting('wantok.delegated_reservation_id')::uuid
  ),
  '+67570000021',
  'delegated reservation snapshots beneficiary phone'
);

select is(
  (
    select metadata ->> 'booked_for'
    from public.service_bookings
    where id = current_setting('wantok.delegated_reservation_id')::uuid
  ),
  'trusted_person',
  'delegated reservation metadata records trusted-person booking mode'
);

update public.trusted_people
set display_name = 'Aunty Mary Updated',
    phone = '+67579999999'
where id = 'd1800000-0000-0000-0000-000000000021'::uuid;

select is(
  (
    select beneficiary_name
    from public.service_bookings
    where id = current_setting('wantok.delegated_reservation_id')::uuid
  ),
  'Aunty Mary',
  'booking beneficiary snapshot does not change when trusted profile is edited'
);

select throws_ok(
  $$select public.create_resource_reservation(
    'd1800000-0000-0000-0000-000000000011'::uuid,
    'd1800000-0000-0000-0000-000000000012'::uuid,
    '2031-02-04 09:00:00+10',
    '2031-02-04 12:00:00+10',
    1,
    null,
    null,
    'd1800000-0000-0000-0000-000000000023'::uuid
  )$$,
  'P0001',
  'Trusted person is not available',
  'customer cannot book using another account trusted person'
);

select throws_ok(
  $$select public.create_open_service_request(
    'errands',
    'Top Town, Lae',
    null,
    null,
    null,
    'Collect medicine',
    25,
    1,
    '{}'::jsonb,
    'd1800000-0000-0000-0000-000000000022'::uuid
  )$$,
  'P0001',
  'Trusted person is not available',
  'inactive trusted person cannot be selected'
);

select lives_ok(
  $$select public.create_open_service_request(
    'errands',
    'Top Town, Lae',
    null,
    null,
    null,
    'Collect documents for Uncle Joe',
    20,
    1,
    '{"client_surface":"test"}'::jsonb,
    'd1800000-0000-0000-0000-000000000024'::uuid
  )$$,
  'customer can create open request for active trusted person'
);

select set_config(
  'wantok.delegated_request_id',
  (
    select id::text
    from public.service_bookings
    where customer_id = 'd1800000-0000-0000-0000-000000000001'::uuid
      and trusted_person_id = 'd1800000-0000-0000-0000-000000000024'::uuid
      and category_id = (
        select id from public.service_categories where slug = 'errands'
      )
    order by created_at desc
    limit 1
  ),
  true
);

select is(
  (
    select customer_id
    from public.service_bookings
    where id = current_setting('wantok.delegated_request_id')::uuid
  ),
  'd1800000-0000-0000-0000-000000000001'::uuid,
  'delegated open request remains owned by signed-in customer'
);

select is(
  (
    select beneficiary_name
    from public.service_bookings
    where id = current_setting('wantok.delegated_request_id')::uuid
  ),
  'Uncle Joe',
  'open request snapshots beneficiary name'
);

select is(
  (
    select beneficiary_email
    from public.service_bookings
    where id = current_setting('wantok.delegated_request_id')::uuid
  ),
  'uncle.joe@example.invalid',
  'open request snapshots beneficiary email'
);

select is(
  (
    select metadata ->> 'booked_for'
    from public.service_bookings
    where id = current_setting('wantok.delegated_request_id')::uuid
  ),
  'trusted_person',
  'open request metadata records delegated booking'
);

select lives_ok(
  $$select public.create_open_service_request(
    'general-labour',
    'Eriku, Lae',
    null,
    null,
    null,
    'Need one helper',
    null,
    1,
    '{}'::jsonb,
    null
  )$$,
  'customer can still create a booking for themselves'
);

select is(
  (
    select count(*)::integer
    from public.service_bookings
    where customer_id = 'd1800000-0000-0000-0000-000000000001'::uuid
      and category_id = (
        select id from public.service_categories where slug = 'general-labour'
      )
      and trusted_person_id is null
      and beneficiary_name is null
      and metadata ->> 'booked_for' = 'self'
  ),
  1,
  'self booking contains no beneficiary snapshot'
);

delete from public.trusted_people
where id = 'd1800000-0000-0000-0000-000000000021'::uuid;

select is(
  (
    select trusted_person_id
    from public.service_bookings
    where id = current_setting('wantok.delegated_reservation_id')::uuid
  ),
  null::uuid,
  'deleting trusted person clears only source foreign key'
);

select is(
  (
    select beneficiary_name
    from public.service_bookings
    where id = current_setting('wantok.delegated_reservation_id')::uuid
  ),
  'Aunty Mary',
  'historical beneficiary name survives trusted-person deletion'
);

select throws_ok(
  $$insert into public.service_bookings (
    customer_id,
    category_id,
    service_address,
    trusted_person_id,
    beneficiary_name
  )
  select
    auth.uid(),
    id,
    'Lae',
    'd1800000-0000-0000-0000-000000000024'::uuid,
    'Injected Beneficiary'
  from public.service_categories
  where slug = 'errands'$$,
  '42501',
  null,
  'ordinary direct insert cannot write protected beneficiary columns'
);

reset role;
select * from finish();
rollback;
