begin;

create extension if not exists pgtap with schema extensions;
select plan(21);

insert into auth.users (
  id, aud, role, email, raw_user_meta_data, created_at, updated_at
) values
  ('b1000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', 'event-client@wantok.local', '{"full_name":"Event Client"}'::jsonb, now(), now()),
  ('b2000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', 'event-organiser@wantok.local', '{"full_name":"Event Organiser"}'::jsonb, now(), now()),
  ('b3000000-0000-0000-0000-000000000003', 'authenticated', 'authenticated', 'event-outsider@wantok.local', '{"full_name":"Event Outsider"}'::jsonb, now(), now());

update public.profiles
set is_provider = true
where id = 'b2000000-0000-0000-0000-000000000002'::uuid;

insert into public.provider_profiles (
  provider_id, provider_type, display_name, verification_status, is_active
) values (
  'b2000000-0000-0000-0000-000000000002',
  'organisation',
  'Wantok Events Test',
  'verified',
  true
);

insert into public.provider_services (
  id, provider_id, category_id, title, pricing_model, currency, status
)
select
  'b2100000-0000-0000-0000-000000000010'::uuid,
  'b2000000-0000-0000-0000-000000000002'::uuid,
  id,
  'Wantok Events Test',
  'fixed',
  'PGK',
  'active'
from public.service_categories
where slug = 'events';

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  'b2000000-0000-0000-0000-000000000002',
  true
);

insert into public.events (
  id, provider_id, provider_service_id, title, description,
  venue_name, venue_address, starts_at, ends_at, capacity, status
) values (
  'b2200000-0000-0000-0000-000000000020',
  'b2000000-0000-0000-0000-000000000002',
  'b2100000-0000-0000-0000-000000000010',
  'Wantok Community Day',
  'Test event',
  'Test Field',
  'Lae',
  now() + interval '5 days',
  now() + interval '5 days 3 hours',
  10,
  'published'
);

insert into public.event_ticket_types (
  id, event_id, name, price, currency, capacity, is_active
) values
  (
    'b2300000-0000-0000-0000-000000000030',
    'b2200000-0000-0000-0000-000000000020',
    'Free Entry',
    0,
    'PGK',
    5,
    true
  ),
  (
    'b2300000-0000-0000-0000-000000000031',
    'b2200000-0000-0000-0000-000000000020',
    'VIP',
    25,
    'PGK',
    3,
    true
  );

select is(
  (select count(*)::integer from public.events where status = 'published'),
  1,
  'organiser can create a published event'
);

select set_config(
  'request.jwt.claim.sub',
  'b1000000-0000-0000-0000-000000000001',
  true
);

select is(
  (select count(*)::integer from public.events where id = 'b2200000-0000-0000-0000-000000000020'),
  1,
  'customer can read published event'
);

select is(
  (select count(*)::integer from public.event_ticket_types where event_id = 'b2200000-0000-0000-0000-000000000020'),
  2,
  'customer can read active ticket types'
);

select lives_ok(
  $$select public.register_for_event(
    'b2200000-0000-0000-0000-000000000020',
    'b2300000-0000-0000-0000-000000000030',
    2,
    'Event Client',
    '70000000',
    null
  )$$,
  'customer can register for free event ticket'
);

select set_config(
  'wantok.free_registration_id',
  (
    select id::text from public.event_registrations
    where customer_id = auth.uid()
      and ticket_type_id = 'b2300000-0000-0000-0000-000000000030'
    order by created_at desc limit 1
  ),
  true
);

select is(
  (
    select payment_status from public.event_registrations
    where id = current_setting('wantok.free_registration_id')::uuid
  ),
  'not_required',
  'free registration requires no payment'
);

select is(
  (
    select total_amount from public.event_registrations
    where id = current_setting('wantok.free_registration_id')::uuid
  ),
  0.00::numeric,
  'free registration total is zero'
);

select lives_ok(
  $$select public.register_for_event(
    'b2200000-0000-0000-0000-000000000020',
    'b2300000-0000-0000-0000-000000000031',
    2,
    'Event Client',
    null,
    'VIP test'
  )$$,
  'customer can reserve paid ticket pending payment integration'
);

select set_config(
  'wantok.vip_registration_id',
  (
    select id::text from public.event_registrations
    where customer_id = auth.uid()
      and ticket_type_id = 'b2300000-0000-0000-0000-000000000031'
    order by created_at desc limit 1
  ),
  true
);

select is(
  (
    select total_amount from public.event_registrations
    where id = current_setting('wantok.vip_registration_id')::uuid
  ),
  50.00::numeric,
  'server calculates paid registration total'
);

select is(
  (
    select payment_status from public.event_registrations
    where id = current_setting('wantok.vip_registration_id')::uuid
  ),
  'unpaid',
  'paid ticket remains unpaid until payments layer is connected'
);

select throws_ok(
  $$select public.register_for_event(
    'b2200000-0000-0000-0000-000000000020',
    'b2300000-0000-0000-0000-000000000031',
    2,
    'Event Client',
    null,
    null
  )$$,
  'P0001',
  'Ticket type capacity exceeded',
  'ticket capacity is enforced'
);

select throws_ok(
  $$insert into public.event_registrations (
    event_id, ticket_type_id, customer_id, quantity,
    unit_price, total_amount, currency
  ) values (
    'b2200000-0000-0000-0000-000000000020',
    'b2300000-0000-0000-0000-000000000030',
    auth.uid(),
    1,
    0,
    0,
    'PGK'
  )$$,
  '42501',
  null,
  'customer cannot directly insert event registration'
);

select set_config(
  'request.jwt.claim.sub',
  'b3000000-0000-0000-0000-000000000003',
  true
);

select is(
  (
    select count(*)::integer from public.event_registrations
    where id = current_setting('wantok.free_registration_id')::uuid
  ),
  0,
  'outsider cannot read another customer registration'
);

select set_config(
  'request.jwt.claim.sub',
  'b2000000-0000-0000-0000-000000000002',
  true
);

select is(
  (
    select count(*)::integer from public.event_registrations
    where event_id = 'b2200000-0000-0000-0000-000000000020'
  ),
  2,
  'organiser can read registrations for own event'
);

select lives_ok(
  $$select public.vendor_set_event_registration_status(
    current_setting('wantok.free_registration_id')::uuid,
    'checked_in'
  )$$,
  'organiser can check in attendee'
);

select is(
  (
    select status from public.event_registrations
    where id = current_setting('wantok.free_registration_id')::uuid
  ),
  'checked_in',
  'checked-in status is stored'
);

select throws_ok(
  $$select public.vendor_set_event_registration_status(
    current_setting('wantok.free_registration_id')::uuid,
    'reserved'
  )$$,
  'P0001',
  'Invalid event registration status transition',
  'organiser cannot reverse checked-in registration'
);

select set_config(
  'request.jwt.claim.sub',
  'b1000000-0000-0000-0000-000000000001',
  true
);

select lives_ok(
  $$select public.cancel_event_registration(
    current_setting('wantok.vip_registration_id')::uuid
  )$$,
  'customer can cancel reserved registration before event'
);

select is(
  (
    select status from public.event_registrations
    where id = current_setting('wantok.vip_registration_id')::uuid
  ),
  'cancelled',
  'cancelled registration status is stored'
);

select set_config(
  'request.jwt.claim.sub',
  'b2000000-0000-0000-0000-000000000002',
  true
);

update public.events
set status = 'draft'
where id = 'b2200000-0000-0000-0000-000000000020';

select set_config(
  'request.jwt.claim.sub',
  'b1000000-0000-0000-0000-000000000001',
  true
);

select is(
  (
    select count(*)::integer from public.events
    where id = 'b2200000-0000-0000-0000-000000000020'
  ),
  0,
  'customer cannot read organiser draft event'
);

select set_config(
  'request.jwt.claim.sub',
  'b2000000-0000-0000-0000-000000000002',
  true
);

update public.events
set status = 'published'
where id = 'b2200000-0000-0000-0000-000000000020';

select is(
  (select status from public.events where id = 'b2200000-0000-0000-0000-000000000020'),
  'published',
  'organiser can republish own event'
);

select ok(
  public.has_role(
    'provider',
    'b2000000-0000-0000-0000-000000000002'::uuid
  ),
  'event organiser has provider role'
);

reset role;
select * from finish();
rollback;
