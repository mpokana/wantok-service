begin;

create extension if not exists pgtap with schema extensions;
select plan(19);

insert into auth.users (
  id, aud, role, email, raw_user_meta_data, created_at, updated_at
) values
  ('f2600000-0000-0000-0000-000000000001', 'authenticated', 'authenticated',
   'cx1f-searcher@wantok.local', '{"full_name":"CX1F Searcher"}'::jsonb, now(), now()),
  ('f2600000-0000-0000-0000-000000000002', 'authenticated', 'authenticated',
   'cx1f-established@wantok.local', '{"full_name":"Established Provider"}'::jsonb, now(), now()),
  ('f2600000-0000-0000-0000-000000000003', 'authenticated', 'authenticated',
   'cx1f-new@wantok.local', '{"full_name":"New Provider"}'::jsonb, now(), now()),
  ('f2600000-0000-0000-0000-000000000004', 'authenticated', 'authenticated',
   'cx1f-pending@wantok.local', '{"full_name":"Pending Provider"}'::jsonb, now(), now()),
  ('f2600000-0000-0000-0000-000000000005', 'authenticated', 'authenticated',
   'cx1f-paused@wantok.local', '{"full_name":"Paused Provider"}'::jsonb, now(), now()),
  ('f2600000-0000-0000-0000-000000000006', 'authenticated', 'authenticated',
   'cx1f-driver@wantok.local', '{"full_name":"Driver Provider"}'::jsonb, now(), now());

update public.profiles
set is_provider = true
where id in (
  'f2600000-0000-0000-0000-000000000002'::uuid,
  'f2600000-0000-0000-0000-000000000003'::uuid,
  'f2600000-0000-0000-0000-000000000004'::uuid,
  'f2600000-0000-0000-0000-000000000005'::uuid,
  'f2600000-0000-0000-0000-000000000006'::uuid
);

insert into public.service_categories (
  id, slug, name, description, vertical, booking_mode, is_active, sort_order
) values
  (
    'f2600000-0000-0000-0000-000000000010',
    'cx1f-plumbing',
    'Plumbing',
    'Provider search plumbing test',
    'people',
    'quote',
    true,
    9910
  ),
  (
    'f2600000-0000-0000-0000-000000000011',
    'cx1f-driving',
    'Driving',
    'Provider search driving test',
    'mobility',
    'quote',
    true,
    9920
  );

insert into public.provider_profiles (
  provider_id, display_name, provider_type, bio,
  verification_status, is_active, rating_average, rating_count
) values
  (
    'f2600000-0000-0000-0000-000000000002',
    'Morobe Reliable Plumbing',
    'business',
    'Experienced plumbing team serving Lae.',
    'verified',
    true,
    4.90,
    100
  ),
  (
    'f2600000-0000-0000-0000-000000000003',
    'New Five Star Plumber',
    'individual',
    'New plumber in Lae.',
    'verified',
    true,
    5.00,
    1
  ),
  (
    'f2600000-0000-0000-0000-000000000004',
    'Pending Hidden Plumbing',
    'business',
    'Should not be client discoverable.',
    'pending',
    false,
    5.00,
    200
  ),
  (
    'f2600000-0000-0000-0000-000000000005',
    'Paused Hidden Plumbing',
    'individual',
    'Verified provider with no active service.',
    'verified',
    true,
    4.80,
    50
  ),
  (
    'f2600000-0000-0000-0000-000000000006',
    'Highlands Driver',
    'individual',
    'Driving services in Mount Hagen.',
    'verified',
    true,
    4.70,
    30
  );

insert into public.provider_services (
  id, provider_id, category_id, title, description,
  pricing_model, status, coverage_province, coverage_town
) values
  (
    'f2600000-0000-0000-0000-000000000020',
    'f2600000-0000-0000-0000-000000000002',
    'f2600000-0000-0000-0000-000000000010',
    'Emergency Pipe Repairs',
    'Residential and commercial plumbing.',
    'quote',
    'active',
    'Morobe',
    'Lae'
  ),
  (
    'f2600000-0000-0000-0000-000000000021',
    'f2600000-0000-0000-0000-000000000003',
    'f2600000-0000-0000-0000-000000000010',
    'Home Plumbing',
    'General home plumbing.',
    'quote',
    'active',
    'Morobe',
    'Lae'
  ),
  (
    'f2600000-0000-0000-0000-000000000022',
    'f2600000-0000-0000-0000-000000000004',
    'f2600000-0000-0000-0000-000000000010',
    'Pending Plumbing',
    'Not yet approved.',
    'quote',
    'active',
    'Morobe',
    'Lae'
  ),
  (
    'f2600000-0000-0000-0000-000000000023',
    'f2600000-0000-0000-0000-000000000005',
    'f2600000-0000-0000-0000-000000000010',
    'Paused Plumbing',
    'Provider service is paused.',
    'quote',
    'paused',
    'Morobe',
    'Lae'
  ),
  (
    'f2600000-0000-0000-0000-000000000024',
    'f2600000-0000-0000-0000-000000000006',
    'f2600000-0000-0000-0000-000000000011',
    'Project Driver',
    'Driver available around Mount Hagen.',
    'quote',
    'active',
    'Western Highlands',
    'Mount Hagen'
  );

select has_function(
  'public',
  'search_client_providers',
  array['text', 'uuid', 'text', 'text', 'integer'],
  'provider/service search RPC exists'
);

select has_function(
  'public',
  'list_top_client_providers',
  array['uuid', 'text', 'text', 'integer', 'integer'],
  'top-provider rotation RPC exists'
);

select is(
  has_function_privilege(
    'anon',
    'public.search_client_providers(text,uuid,text,text,integer)',
    'EXECUTE'
  ),
  false,
  'anonymous users cannot execute provider search'
);

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  'f2600000-0000-0000-0000-000000000001',
  true
);

select is(
  (
    select count(*)::integer
    from public.search_client_providers(null, null, null, null, 30)
    where provider_id::text like 'f2600000-%'
  ),
  3,
  'only active verified providers with active services are discoverable'
);

select is(
  (
    select count(*)::integer
    from public.search_client_providers('Morobe Reliable', null, null, null, 30)
  ),
  1,
  'provider name search works'
);

select is(
  (
    select count(*)::integer
    from public.search_client_providers('Emergency Pipe', null, null, null, 30)
  ),
  1,
  'service title search finds its provider'
);

select is(
  (
    select count(*)::integer
    from public.search_client_providers('Plumbing', null, null, null, 30)
    where provider_id::text like 'f2600000-%'
  ),
  2,
  'category-name search finds matching providers'
);

select is(
  (
    select count(*)::integer
    from public.search_client_providers(
      null,
      'f2600000-0000-0000-0000-000000000010'::uuid,
      null,
      null,
      30
    )
  ),
  2,
  'category filter restricts providers to approved active services'
);

select is(
  (
    select count(*)::integer
    from public.search_client_providers(null, null, 'Morobe', null, 30)
    where provider_id::text like 'f2600000-%'
  ),
  2,
  'province filter uses structured service coverage'
);

select is(
  (
    select count(*)::integer
    from public.search_client_providers(null, null, 'Morobe', 'Lae', 30)
    where provider_id::text like 'f2600000-%'
  ),
  2,
  'town filter uses structured service coverage'
);

select is(
  (
    select count(*)::integer
    from public.search_client_providers(null, null, 'Morobe', 'Madang', 30)
  ),
  0,
  'wrong town does not infer coverage from free text'
);

select is(
  (
    select provider_type
    from public.search_client_providers('Morobe Reliable', null, null, null, 30)
  ),
  'business',
  'provider type is returned'
);

select is(
  (
    select rating_count
    from public.search_client_providers('Morobe Reliable', null, null, null, 30)
  ),
  100,
  'review count is returned with search result'
);

select ok(
  (
    select organic_score
    from public.search_client_providers('Morobe Reliable', null, null, null, 30)
  )
  >
  (
    select organic_score
    from public.search_client_providers('New Five Star', null, null, null, 30)
  ),
  'confidence-aware organic score favours established 4.9/100 over 5.0/1'
);

select is(
  (
    select service_count
    from public.search_client_providers('Morobe Reliable', null, null, null, 30)
  ),
  1,
  'matching active service count is returned'
);

select ok(
  (
    select service_titles @> array['Emergency Pipe Repairs']::text[]
    from public.search_client_providers('Morobe Reliable', null, null, null, 30)
  ),
  'matching service titles are returned'
);

select ok(
  (
    select category_names @> array['Plumbing']::text[]
    from public.search_client_providers('Morobe Reliable', null, null, null, 30)
  ),
  'approved category names are returned'
);

select is(
  (
    select count(*)::integer
    from public.list_top_client_providers(null, null, null, 20, 2)
  ),
  2,
  'top-provider surface respects requested display limit'
);

select ok(
  not exists (
    select 1
    from public.list_top_client_providers(null, null, null, 20, 5)
    where provider_id in (
      'f2600000-0000-0000-0000-000000000004'::uuid,
      'f2600000-0000-0000-0000-000000000005'::uuid
    )
  ),
  'top-provider rotation cannot include pending or inactive-service providers'
);

select * from finish();
rollback;
