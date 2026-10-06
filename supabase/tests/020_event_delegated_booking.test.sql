begin;

create extension if not exists pgtap with schema extensions;
select plan(24);

select has_column(
  'public', 'event_registrations', 'trusted_person_id',
  'event registrations include trusted-person source id'
);
select has_column(
  'public', 'event_registrations', 'attendee_relationship',
  'event registrations include attendee relationship snapshot'
);
select has_column(
  'public', 'event_registrations', 'attendee_phone',
  'event registrations include attendee phone snapshot'
);
select has_column(
  'public', 'event_registrations', 'attendee_email',
  'event registrations include attendee email snapshot'
);

insert into auth.users (
  id, aud, role, email, raw_user_meta_data, created_at, updated_at
) values
  (
    'e2000000-0000-0000-0000-000000000001',
    'authenticated',
    'authenticated',
    'event-delegated-owner@wantok.local',
    '{"full_name":"Event Booking Owner"}'::jsonb,
    now(),
    now()
  ),
  (
    'e2000000-0000-0000-0000-000000000002',
    'authenticated',
    'authenticated',
    'event-delegated-organiser@wantok.local',
    '{"full_name":"Event Delegated Organiser"}'::jsonb,
    now(),
    now()
  ),
  (
    'e2000000-0000-0000-0000-000000000003',
    'authenticated',
    'authenticated',
    'event-delegated-other@wantok.local',
    '{"full_name":"Other Event Account"}'::jsonb,
    now(),
    now()
  );

update public.profiles
set is_provider = true
where id = 'e2000000-0000-0000-0000-000000000002'::uuid;

insert into public.provider_profiles (
  provider_id, provider_type, display_name, verification_status, is_active
) values (
  'e2000000-0000-0000-0000-000000000002',
  'organisation',
  'Delegated Event Organiser',
  'verified',
  true
);

insert into public.provider_services (
  id, provider_id, category_id, title, pricing_model, currency, status
)
select
  'e2000000-0000-0000-0000-000000000010'::uuid,
  'e2000000-0000-0000-0000-000000000002'::uuid,
  id,
  'Delegated Event Service',
  'fixed',
  'PGK',
  'active'
from public.service_categories
where slug = 'events';

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  'e2000000-0000-0000-0000-000000000002',
  true
);

insert into public.events (
  id, provider_id, provider_service_id, title,
  venue_name, venue_address, starts_at, ends_at, capacity, status
) values (
  'e2000000-0000-0000-0000-000000000020',
  'e2000000-0000-0000-0000-000000000002',
  'e2000000-0000-0000-0000-000000000010',
  'Delegated Wantok Event',
  'Delegated Test Venue',
  'Lae, Morobe Province',
  now() + interval '7 days',
  now() + interval '7 days 3 hours',
  30,
  'published'
);

insert into public.event_ticket_types (
  id, event_id, name, price, currency, capacity, is_active
) values (
  'e2000000-0000-0000-0000-000000000030',
  'e2000000-0000-0000-0000-000000000020',
  'Community Entry',
  15,
  'PGK',
  20,
  true
);

reset role;

insert into public.trusted_people (
  id, owner_id, display_name, relationship, phone, email, is_active
) values
  (
    'e2000000-0000-0000-0000-000000000041',
    'e2000000-0000-0000-0000-000000000001',
    'Aunty Event Attendee',
    'Aunty',
    '+67570002041',
    'aunty.event@example.invalid',
    true
  ),
  (
    'e2000000-0000-0000-0000-000000000042',
    'e2000000-0000-0000-0000-000000000001',
    'Inactive Event Attendee',
    'Relative',
    '+67570002042',
    null,
    false
  ),
  (
    'e2000000-0000-0000-0000-000000000043',
    'e2000000-0000-0000-0000-000000000003',
    'Other Account Event Attendee',
    'Sibling',
    '+67570002043',
    null,
    true
  );

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  'e2000000-0000-0000-0000-000000000001',
  true
);

select lives_ok(
  $$select public.register_for_event(
    'e2000000-0000-0000-0000-000000000020'::uuid,
    'e2000000-0000-0000-0000-000000000030'::uuid,
    2,
    null,
    null,
    'Two tickets with a trusted primary attendee',
    'e2000000-0000-0000-0000-000000000041'::uuid
  )$$,
  'customer can register for event with own active trusted person'
);

select set_config(
  'wantok.delegated_event_registration_id',
  (
    select id::text
    from public.event_registrations
    where customer_id = auth.uid()
      and trusted_person_id = 'e2000000-0000-0000-0000-000000000041'::uuid
    order by created_at desc
    limit 1
  ),
  true
);

select is(
  (
    select customer_id
    from public.event_registrations
    where id = current_setting('wantok.delegated_event_registration_id')::uuid
  ),
  'e2000000-0000-0000-0000-000000000001'::uuid,
  'delegated event registration remains owned by booking account'
);

select is(
  (
    select trusted_person_id
    from public.event_registrations
    where id = current_setting('wantok.delegated_event_registration_id')::uuid
  ),
  'e2000000-0000-0000-0000-000000000041'::uuid,
  'event registration stores trusted-person source id'
);

select is(
  (
    select attendee_name
    from public.event_registrations
    where id = current_setting('wantok.delegated_event_registration_id')::uuid
  ),
  'Aunty Event Attendee',
  'event registration snapshots primary attendee name'
);

select is(
  (
    select attendee_relationship
    from public.event_registrations
    where id = current_setting('wantok.delegated_event_registration_id')::uuid
  ),
  'Aunty',
  'event registration snapshots attendee relationship'
);

select is(
  (
    select attendee_phone
    from public.event_registrations
    where id = current_setting('wantok.delegated_event_registration_id')::uuid
  ),
  '+67570002041',
  'event registration snapshots attendee phone'
);

select is(
  (
    select attendee_email
    from public.event_registrations
    where id = current_setting('wantok.delegated_event_registration_id')::uuid
  ),
  'aunty.event@example.invalid',
  'event registration snapshots attendee email'
);

select is(
  (
    select attendee_contact
    from public.event_registrations
    where id = current_setting('wantok.delegated_event_registration_id')::uuid
  ),
  '+67570002041',
  'legacy attendee contact uses trusted-person phone when available'
);

select is(
  (
    select metadata ->> 'booked_for'
    from public.event_registrations
    where id = current_setting('wantok.delegated_event_registration_id')::uuid
  ),
  'trusted_person',
  'delegated event metadata records trusted-person beneficiary'
);

select set_config(
  'request.jwt.claim.sub',
  'e2000000-0000-0000-0000-000000000002',
  true
);

select is(
  (
    select attendee_name
    from public.event_registrations
    where id = current_setting('wantok.delegated_event_registration_id')::uuid
  ),
  'Aunty Event Attendee',
  'event organiser can read delegated primary attendee'
);

select set_config(
  'request.jwt.claim.sub',
  'e2000000-0000-0000-0000-000000000001',
  true
);

select throws_ok(
  $$select public.register_for_event(
    'e2000000-0000-0000-0000-000000000020'::uuid,
    'e2000000-0000-0000-0000-000000000030'::uuid,
    1,
    null,
    null,
    null,
    'e2000000-0000-0000-0000-000000000043'::uuid
  )$$,
  'P0001',
  'Trusted person is not available',
  'event registration cannot use another account trusted person'
);

select throws_ok(
  $$select public.register_for_event(
    'e2000000-0000-0000-0000-000000000020'::uuid,
    'e2000000-0000-0000-0000-000000000030'::uuid,
    1,
    null,
    null,
    null,
    'e2000000-0000-0000-0000-000000000042'::uuid
  )$$,
  'P0001',
  'Trusted person is not available',
  'event registration cannot use inactive trusted person'
);

update public.trusted_people
set display_name = 'Aunty Event Attendee Updated',
    relationship = 'Relative',
    phone = '+67579992041'
where id = 'e2000000-0000-0000-0000-000000000041'::uuid;

select is(
  (
    select attendee_name
    from public.event_registrations
    where id = current_setting('wantok.delegated_event_registration_id')::uuid
  ),
  'Aunty Event Attendee',
  'event attendee snapshot is unchanged after trusted-person edit'
);

delete from public.trusted_people
where id = 'e2000000-0000-0000-0000-000000000041'::uuid;

select is(
  (
    select trusted_person_id
    from public.event_registrations
    where id = current_setting('wantok.delegated_event_registration_id')::uuid
  ),
  null::uuid,
  'deleting trusted person clears event source foreign key'
);

select is(
  (
    select attendee_name
    from public.event_registrations
    where id = current_setting('wantok.delegated_event_registration_id')::uuid
  ),
  'Aunty Event Attendee',
  'event attendee snapshot survives source deletion'
);

select lives_ok(
  $$select public.register_for_event(
    'e2000000-0000-0000-0000-000000000020'::uuid,
    'e2000000-0000-0000-0000-000000000030'::uuid,
    1,
    'Event Booking Owner',
    '+67570002001',
    'Self registration',
    null
  )$$,
  'customer can still register for themselves'
);

select set_config(
  'wantok.self_event_registration_id',
  (
    select id::text
    from public.event_registrations
    where customer_id = auth.uid()
      and trusted_person_id is null
      and note = 'Self registration'
    order by created_at desc
    limit 1
  ),
  true
);

select is(
  (
    select trusted_person_id
    from public.event_registrations
    where id = current_setting('wantok.self_event_registration_id')::uuid
  ),
  null::uuid,
  'self event registration has no trusted-person source'
);

select is(
  (
    select attendee_name
    from public.event_registrations
    where id = current_setting('wantok.self_event_registration_id')::uuid
  ),
  'Event Booking Owner',
  'self registration preserves manually supplied attendee name'
);

select is(
  (
    select metadata ->> 'booked_for'
    from public.event_registrations
    where id = current_setting('wantok.self_event_registration_id')::uuid
  ),
  'self',
  'self event metadata records self beneficiary'
);

select lives_ok(
  $$select public.cancel_event_registration(
    current_setting('wantok.delegated_event_registration_id')::uuid
  )$$,
  'booking account retains cancellation authority after trusted-person deletion'
);

reset role;
select * from finish();
rollback;
