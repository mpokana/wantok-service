begin;

create extension if not exists pgtap with schema extensions;
select plan(13);

insert into auth.users (
  id, aud, role, email, raw_user_meta_data, created_at, updated_at
) values
  (
    'c2500000-0000-0000-0000-000000000001',
    'authenticated',
    'authenticated',
    'place-client@wantok.local',
    '{"full_name":"Place Client"}'::jsonb,
    now(),
    now()
  ),
  (
    'c2500000-0000-0000-0000-000000000002',
    'authenticated',
    'authenticated',
    'place-provider@wantok.local',
    '{"full_name":"Place Provider"}'::jsonb,
    now(),
    now()
  ),
  (
    'c2500000-0000-0000-0000-000000000003',
    'authenticated',
    'authenticated',
    'hidden-provider@wantok.local',
    '{"full_name":"Hidden Provider"}'::jsonb,
    now(),
    now()
  );

update public.profiles
set is_provider = true
where id in (
  'c2500000-0000-0000-0000-000000000002'::uuid,
  'c2500000-0000-0000-0000-000000000003'::uuid
);

insert into public.provider_profiles (
  provider_id,
  display_name,
  provider_type,
  verification_status,
  is_active
) values
  (
    'c2500000-0000-0000-0000-000000000002',
    'Place Test Provider',
    'business',
    'verified',
    true
  ),
  (
    'c2500000-0000-0000-0000-000000000003',
    'Hidden Place Provider',
    'business',
    'pending',
    false
  );

insert into public.service_categories (
  id, slug, name, description, vertical, booking_mode, is_active, sort_order
) values
  (
    'c2500000-0000-0000-0000-000000000010',
    'place-hire-test',
    'Place Hire Test',
    'Place coverage listing category',
    'hire',
    'reservation',
    true,
    9960
  ),
  (
    'c2500000-0000-0000-0000-000000000020',
    'place-event-test',
    'Place Event Test',
    'Place coverage event category',
    'events',
    'ticketing',
    true,
    9961
  ),
  (
    'c2500000-0000-0000-0000-000000000030',
    'place-water-test',
    'Place Water Test',
    'Place coverage water category',
    'travel',
    'scheduled',
    true,
    9962
  );

insert into public.provider_services (
  id,
  provider_id,
  category_id,
  title,
  pricing_model,
  status,
  service_address,
  coverage_province,
  coverage_town
) values
  (
    'c2500000-0000-0000-0000-000000000011',
    'c2500000-0000-0000-0000-000000000002',
    'c2500000-0000-0000-0000-000000000010',
    'Lae Hire Coverage',
    'fixed',
    'active',
    'Section 1, Lae',
    'Morobe Province',
    'Lae'
  ),
  (
    'c2500000-0000-0000-0000-000000000012',
    'c2500000-0000-0000-0000-000000000002',
    'c2500000-0000-0000-0000-000000000010',
    'Address Only Service',
    'fixed',
    'active',
    'Madang, Madang Province',
    null,
    null
  ),
  (
    'c2500000-0000-0000-0000-000000000013',
    'c2500000-0000-0000-0000-000000000003',
    'c2500000-0000-0000-0000-000000000010',
    'Hidden Service',
    'fixed',
    'active',
    'Goroka, Eastern Highlands',
    'Eastern Highlands Province',
    'Goroka'
  ),
  (
    'c2500000-0000-0000-0000-000000000021',
    'c2500000-0000-0000-0000-000000000002',
    'c2500000-0000-0000-0000-000000000020',
    'Event Organiser Listing',
    'fixed',
    'active',
    'Lae',
    null,
    null
  ),
  (
    'c2500000-0000-0000-0000-000000000031',
    'c2500000-0000-0000-0000-000000000002',
    'c2500000-0000-0000-0000-000000000030',
    'Water Passenger Listing',
    'fixed',
    'active',
    'Lae',
    null,
    null
  );

insert into public.provider_resources (
  id,
  provider_id,
  category_id,
  resource_type,
  name,
  address_text,
  coverage_province,
  coverage_town,
  status
) values (
  'c2500000-0000-0000-0000-000000000014',
  'c2500000-0000-0000-0000-000000000002',
  'c2500000-0000-0000-0000-000000000010',
  'vehicle',
  'Lae Resource',
  'Lae',
  'Morobe Province',
  'Lae',
  'active'
);

insert into public.events (
  id,
  provider_id,
  provider_service_id,
  title,
  venue_name,
  venue_address,
  venue_province,
  venue_town,
  starts_at,
  ends_at,
  status
) values (
  'c2500000-0000-0000-0000-000000000022',
  'c2500000-0000-0000-0000-000000000002',
  'c2500000-0000-0000-0000-000000000021',
  'Lae Place Event',
  'Test Venue',
  'Lae',
  'Morobe Province',
  'Lae',
  now() + interval '3 days',
  now() + interval '3 days 2 hours',
  'published'
);

insert into public.water_routes (
  id,
  provider_id,
  provider_service_id,
  name,
  origin_name,
  origin_address,
  origin_province,
  origin_town,
  destination_name,
  destination_address,
  destination_province,
  destination_town,
  estimated_minutes,
  status
) values (
  'c2500000-0000-0000-0000-000000000032',
  'c2500000-0000-0000-0000-000000000002',
  'c2500000-0000-0000-0000-000000000031',
  'Lae to Finschhafen',
  'Lae',
  'Lae waterfront',
  'Morobe Province',
  'Lae',
  'Finschhafen',
  'Finschhafen waterfront',
  'Morobe Province',
  'Finschhafen',
  180,
  'active'
);

select has_function(
  'public',
  'list_client_service_places',
  array['integer'],
  'PNG service-place discovery RPC exists'
);

select ok(
  not has_function_privilege(
    'anon',
    'public.list_client_service_places(integer)',
    'EXECUTE'
  ),
  'anonymous users cannot execute client place discovery'
);

select ok(
  has_function_privilege(
    'authenticated',
    'public.list_client_service_places(integer)',
    'EXECUTE'
  ),
  'authenticated users can execute client place discovery'
);

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  'c2500000-0000-0000-0000-000000000001',
  true
);
select is(
  (
    select count(*)::integer
    from public.list_client_service_places(30)
  ),
  2,
  'only places with active verified structured coverage are returned'
);

select is(
  (
    select listing_count
    from public.list_client_service_places(30)
    where lower(province) = 'morobe province'
      and lower(town) = 'lae'
  ),
  2,
  'Lae aggregates active service and resource coverage'
);

select is(
  (
    select event_count
    from public.list_client_service_places(30)
    where lower(province) = 'morobe province'
      and lower(town) = 'lae'
  ),
  1,
  'future published event contributes to Lae coverage'
);

select is(
  (
    select route_count
    from public.list_client_service_places(30)
    where lower(province) = 'morobe province'
      and lower(town) = 'lae'
  ),
  1,
  'water route origin contributes to Lae coverage'
);

select is(
  (
    select cardinality(category_ids)
    from public.list_client_service_places(30)
    where lower(province) = 'morobe province'
      and lower(town) = 'lae'
  ),
  3,
  'Lae exposes each covered active service category once'
);

select is(
  (
    select route_count
    from public.list_client_service_places(30)
    where lower(province) = 'morobe province'
      and lower(town) = 'finschhafen'
  ),
  1,
  'water route destination becomes a discoverable place'
);

select is(
  (
    select count(*)::integer
    from public.list_client_service_places(30)
    where lower(province) like '%madang%'
       or lower(coalesce(town, '')) = 'madang'
  ),
  0,
  'free-text address alone does not create a destination'
);

select is(
  (
    select count(*)::integer
    from public.list_client_service_places(30)
    where lower(coalesce(town, '')) = 'goroka'
  ),
  0,
  'inactive unverified provider coverage is excluded'
);

reset role;

select throws_ok(
  $$insert into public.provider_services (
    provider_id,
    category_id,
    title,
    pricing_model,
    status,
    coverage_province,
    coverage_town
  ) values (
    'c2500000-0000-0000-0000-000000000002',
    'c2500000-0000-0000-0000-000000000010',
    'Invalid Town Only Service',
    'fixed',
    'draft',
    null,
    'Lae'
  )$$,
  '23514',
  null,
  'service town cannot be stored without a province'
);

select throws_ok(
  $$insert into public.events (
    provider_id,
    provider_service_id,
    title,
    venue_province,
    venue_town,
    starts_at,
    status
  ) values (
    'c2500000-0000-0000-0000-000000000002',
    'c2500000-0000-0000-0000-000000000021',
    'Invalid Town Only Event',
    null,
    'Lae',
    now() + interval '2 days',
    'draft'
  )$$,
  '23514',
  null,
  'event town cannot be stored without a province'
);

select * from finish();
rollback;
