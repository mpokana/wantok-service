begin;

create extension if not exists pgtap with schema extensions;
select plan(13);

insert into auth.users (
  id, aud, role, email, raw_user_meta_data, created_at, updated_at
) values
  ('70000000-0000-0000-0000-000000000007', 'authenticated', 'authenticated', 'open-customer@wantok.local', '{"full_name":"Open Request Customer"}'::jsonb, now(), now()),
  ('80000000-0000-0000-0000-000000000008', 'authenticated', 'authenticated', 'delivery-provider@wantok.local', '{"full_name":"Delivery Provider"}'::jsonb, now(), now());

select is(
  public.provider_category_slug('errands'),
  'errands',
  'errands provider type maps to errands category'
);

update public.profiles
set is_provider = true
where id = '80000000-0000-0000-0000-000000000008'::uuid;

insert into public.provider_profiles (
  provider_id, display_name, provider_type, verification_status, is_active
) values (
  '80000000-0000-0000-0000-000000000008',
  'Delivery Provider',
  'individual',
  'verified',
  true
);

insert into public.provider_services (
  id, provider_id, category_id, title, pricing_model, status
)
select
  '81000000-0000-0000-0000-000000000008'::uuid,
  '80000000-0000-0000-0000-000000000008'::uuid,
  id,
  'Lae Delivery',
  'quote',
  'active'
from public.service_categories
where slug = 'delivery';

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '70000000-0000-0000-0000-000000000007',
  true
);

select throws_ok(
  $$select public.create_open_service_request(
    'delivery', null, null, 'Top Town', null,
    'Parcel', 20, 1, '{}'::jsonb
  )$$,
  'P0001',
  'Delivery requires pickup and destination addresses',
  'delivery request requires both route addresses'
);

select throws_ok(
  $$select public.create_open_service_request(
    'venue-booking', 'Lae', null, null, null,
    'Hall', null, 1, '{}'::jsonb
  )$$,
  'P0001',
  'This service does not use the open-request workflow',
  'reservation category cannot use open-request RPC'
);

select lives_ok(
  $$select public.create_open_service_request(
    'delivery',
    null,
    'Eriku, Lae',
    'Top Town, Lae',
    '2030-01-08 09:00:00+10',
    'Collect one sealed document envelope.',
    25,
    1,
    '{"item_type":"documents"}'::jsonb
  )$$,
  'customer can create delivery request through secured RPC'
);

select set_config(
  'wantok.open_booking_id',
  (
    select id::text
    from public.service_bookings
    where customer_id = auth.uid()
      and origin_address = 'Eriku, Lae'
    order by created_at desc
    limit 1
  ),
  true
);

select is(
  (select status
   from public.service_bookings
   where id = current_setting('wantok.open_booking_id')::uuid),
  'requested',
  'open request starts requested'
);

select is(
  (select provider_id
   from public.service_bookings
   where id = current_setting('wantok.open_booking_id')::uuid),
  null::uuid,
  'open request starts without assigned provider'
);

select is(
  (select destination_address
   from public.service_bookings
   where id = current_setting('wantok.open_booking_id')::uuid),
  'Top Town, Lae',
  'delivery destination is stored'
);

select is(
  (select metadata ->> 'booking_mode'
   from public.service_bookings
   where id = current_setting('wantok.open_booking_id')::uuid),
  'open_request',
  'open request metadata is server stamped'
);

select set_config(
  'request.jwt.claim.sub',
  '80000000-0000-0000-0000-000000000008',
  true
);

select is(
  (select count(*)::integer
   from public.service_bookings
   where id = current_setting('wantok.open_booking_id')::uuid),
  1,
  'approved matching provider can see open delivery request'
);

select lives_ok(
  $$select public.submit_service_quote(
    current_setting('wantok.open_booking_id')::uuid,
    22,
    'Can collect within 30 minutes.',
    null
  )$$,
  'approved delivery provider can quote open request'
);

select set_config(
  'request.jwt.claim.sub',
  '70000000-0000-0000-0000-000000000007',
  true
);

select lives_ok(
  $$select public.accept_service_quote((
    select id
    from public.service_quotes
    where booking_id = current_setting('wantok.open_booking_id')::uuid
      and provider_id = '80000000-0000-0000-0000-000000000008'::uuid
  ))$$,
  'customer can accept delivery provider quote'
);

select is(
  (select provider_id
   from public.service_bookings
   where id = current_setting('wantok.open_booking_id')::uuid),
  '80000000-0000-0000-0000-000000000008'::uuid,
  'accepted quote assigns delivery provider'
);

select is(
  (select status
   from public.service_bookings
   where id = current_setting('wantok.open_booking_id')::uuid),
  'confirmed',
  'accepted delivery quote confirms booking'
);

reset role;
select * from finish();
rollback;
