begin;

create extension if not exists pgtap with schema extensions;
select plan(12);

insert into auth.users (
  id, aud, role, email, raw_user_meta_data, created_at, updated_at
) values
  ('c2400000-0000-0000-0000-000000000001', 'authenticated', 'authenticated',
   'recommend-owner@wantok.local', '{"full_name":"Recommendation Owner"}'::jsonb, now(), now()),
  ('c2400000-0000-0000-0000-000000000002', 'authenticated', 'authenticated',
   'recommend-other@wantok.local', '{"full_name":"Recommendation Other"}'::jsonb, now(), now()),
  ('c2400000-0000-0000-0000-000000000003', 'authenticated', 'authenticated',
   'recommend-near-provider@wantok.local', '{"full_name":"Near Provider"}'::jsonb, now(), now()),
  ('c2400000-0000-0000-0000-000000000004', 'authenticated', 'authenticated',
   'recommend-far-provider@wantok.local', '{"full_name":"Far Provider"}'::jsonb, now(), now());

update public.profiles
set is_provider = true
where id in (
  'c2400000-0000-0000-0000-000000000003'::uuid,
  'c2400000-0000-0000-0000-000000000004'::uuid
);

insert into public.provider_profiles (
  provider_id, display_name, provider_type, verification_status, is_active,
  base_address, base_lat, base_lng, service_radius_km
) values
  (
    'c2400000-0000-0000-0000-000000000003',
    'Recommendation Near Provider',
    'business',
    'verified',
    true,
    'Lae, Morobe Province',
    -6.7300,
    147.0000,
    30
  ),
  (
    'c2400000-0000-0000-0000-000000000004',
    'Recommendation Far Provider',
    'business',
    'verified',
    true,
    'Port Moresby, NCD',
    -9.4700,
    147.1600,
    30
  );

insert into public.service_categories (
  id, slug, name, description, vertical, booking_mode, is_active, sort_order
) values
  (
    'c2400000-0000-0000-0000-000000000010',
    'recommend-near-service',
    'Recommendation Near Service',
    'Nearby recommendation test category',
    'other',
    'reservation',
    true,
    9980
  ),
  (
    'c2400000-0000-0000-0000-000000000020',
    'recommend-history-service',
    'Recommendation History Service',
    'History recommendation test category',
    'other',
    'reservation',
    true,
    9981
  );

insert into public.provider_services (
  id, provider_id, category_id, title, pricing_model, status,
  service_address, lat, lng, service_radius_km
) values
  (
    'c2400000-0000-0000-0000-000000000011',
    'c2400000-0000-0000-0000-000000000003',
    'c2400000-0000-0000-0000-000000000010',
    'Near Recommendation Service',
    'fixed',
    'active',
    'Lae, Morobe Province',
    -6.7300,
    147.0000,
    30
  ),
  (
    'c2400000-0000-0000-0000-000000000021',
    'c2400000-0000-0000-0000-000000000004',
    'c2400000-0000-0000-0000-000000000020',
    'Far Recommendation Service',
    'fixed',
    'active',
    'Port Moresby, NCD',
    -9.4700,
    147.1600,
    30
  );

insert into public.client_saved_items (user_id, item_type, entity_id)
values (
  'c2400000-0000-0000-0000-000000000001',
  'category',
  'c2400000-0000-0000-0000-000000000010'
);

insert into public.service_bookings (
  id, customer_id, category_id, provider_id, provider_service_id,
  status, currency, completed_at
) values (
  'c2400000-0000-0000-0000-000000000030',
  'c2400000-0000-0000-0000-000000000001',
  'c2400000-0000-0000-0000-000000000020',
  'c2400000-0000-0000-0000-000000000004',
  'c2400000-0000-0000-0000-000000000021',
  'completed',
  'PGK',
  now()
);

select has_function(
  'public',
  'list_client_service_recommendations',
  array['double precision', 'double precision', 'integer'],
  'client recommendation RPC exists'
);

select ok(
  not has_function_privilege(
    'anon',
    'public.list_client_service_recommendations(double precision,double precision,integer)',
    'EXECUTE'
  ),
  'anonymous users cannot execute personalised recommendations'
);

select ok(
  has_function_privilege(
    'authenticated',
    'public.list_client_service_recommendations(double precision,double precision,integer)',
    'EXECUTE'
  ),
  'authenticated users can execute personalised recommendations'
);

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  'c2400000-0000-0000-0000-000000000001',
  true
);
select is(
  (
    select count(*)::integer
    from public.list_client_service_recommendations(null, null, 8)
  ),
  2,
  'saved and recent-history categories are recommended without location'
);

select is(
  (
    select reason
    from public.list_client_service_recommendations(null, null, 8)
    where category_id = 'c2400000-0000-0000-0000-000000000010'::uuid
  ),
  'Saved by you',
  'saved category receives the saved reason'
);

select is(
  (
    select reason
    from public.list_client_service_recommendations(null, null, 8)
    where category_id = 'c2400000-0000-0000-0000-000000000020'::uuid
  ),
  'Based on your recent activity',
  'recent completed booking contributes a history recommendation'
);

select ok(
  (
    select score
    from public.list_client_service_recommendations(null, null, 8)
    where category_id = 'c2400000-0000-0000-0000-000000000010'::uuid
  ) >
  (
    select score
    from public.list_client_service_recommendations(null, null, 8)
    where category_id = 'c2400000-0000-0000-0000-000000000020'::uuid
  ),
  'directly saved category outranks one recent-history signal'
);

select set_config(
  'request.jwt.claim.sub',
  'c2400000-0000-0000-0000-000000000002',
  true
);

select is(
  (
    select count(*)::integer
    from public.list_client_service_recommendations(null, null, 8)
  ),
  0,
  'another account does not inherit saved or history signals'
);

select is(
  (
    select count(*)::integer
    from public.list_client_service_recommendations(-6.7300, 147.0000, 8)
  ),
  1,
  'location-only recommendations include nearby real coverage but omit distant coverage'
);

select is(
  (
    select reason
    from public.list_client_service_recommendations(-6.7300, 147.0000, 8)
    limit 1
  ),
  'Available near you',
  'nearby coverage receives a location reason'
);

reset role;

insert into public.account_preferences (
  user_id, allow_recommendations
) values (
  'c2400000-0000-0000-0000-000000000002',
  false
)
on conflict (user_id) do update
set allow_recommendations = excluded.allow_recommendations;

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  'c2400000-0000-0000-0000-000000000002',
  true
);

select is(
  (
    select count(*)::integer
    from public.list_client_service_recommendations(-6.7300, 147.0000, 8)
  ),
  0,
  'recommendation opt-out suppresses all personalised recommendations'
);

select throws_ok(
  $$select * from public.list_client_service_recommendations(100, 147, 8)$$,
  'P0001',
  'Invalid recommendation coordinates',
  'invalid recommendation coordinates are rejected'
);

reset role;
select * from finish();
rollback;
