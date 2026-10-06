begin;

create extension if not exists pgtap with schema extensions;
select plan(30);

insert into auth.users (
  id, aud, role, email, raw_user_meta_data, created_at, updated_at
) values
  ('c1100000-0000-0000-0000-000000000001', 'authenticated', 'authenticated',
   'cx1-owner@wantok.local', '{"full_name":"CX1 Owner"}'::jsonb, now(), now()),
  ('c1100000-0000-0000-0000-000000000002', 'authenticated', 'authenticated',
   'cx1-provider@wantok.local', '{"full_name":"CX1 Provider"}'::jsonb, now(), now()),
  ('c1100000-0000-0000-0000-000000000003', 'authenticated', 'authenticated',
   'cx1-other@wantok.local', '{"full_name":"CX1 Other"}'::jsonb, now(), now());

update public.profiles
set is_provider = true
where id = 'c1100000-0000-0000-0000-000000000002'::uuid;

insert into public.provider_profiles (
  provider_id, display_name, provider_type, verification_status, is_active
) values (
  'c1100000-0000-0000-0000-000000000002',
  'CX1 Test Provider',
  'business',
  'verified',
  true
);

insert into public.service_categories (
  id, slug, name, description, vertical, booking_mode, is_active, sort_order
) values (
  'c1100000-0000-0000-0000-000000000010',
  'cx1-test-service',
  'CX1 Test Service',
  'CX1 test category',
  'other',
  'reservation',
  true,
  9990
);

insert into public.provider_services (
  id, provider_id, category_id, title, pricing_model, status
) values (
  'c1100000-0000-0000-0000-000000000011',
  'c1100000-0000-0000-0000-000000000002',
  'c1100000-0000-0000-0000-000000000010',
  'CX1 Provider Service',
  'fixed',
  'active'
);

insert into public.service_bookings (
  id,
  customer_id,
  category_id,
  provider_id,
  provider_service_id,
  status,
  final_amount,
  currency,
  completed_at
) values (
  'c1100000-0000-0000-0000-000000000012',
  'c1100000-0000-0000-0000-000000000001',
  'c1100000-0000-0000-0000-000000000010',
  'c1100000-0000-0000-0000-000000000002',
  'c1100000-0000-0000-0000-000000000011',
  'completed',
  25,
  'PGK',
  now()
);

select has_table(
  'public', 'client_saved_items',
  'CX1 saved-items table exists'
);

select has_table(
  'public', 'trusted_people',
  'CX1 trusted-people table exists'
);

select has_column(
  'public', 'profiles', 'avatar_url',
  'profiles include avatar URL'
);

select has_column(
  'public', 'profiles', 'bio',
  'profiles include biography'
);

select has_column(
  'public', 'account_preferences', 'profile_visibility',
  'account preferences include profile visibility'
);

select has_column(
  'public', 'service_reviews', 'title',
  'service reviews include a title'
);

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  'c1100000-0000-0000-0000-000000000001',
  true
);

select lives_ok(
  $$select * from public.get_my_account_profile_v2()$$,
  'owner can load richer account profile'
);

select lives_ok(
  $$select public.update_my_account_profile_v2(
    'CX1 Owner Updated',
    'Mans',
    '+675 7000 0001',
    'Lae, Morobe Province',
    'https://example.invalid/avatar.png',
    'Local Wantok user profile.',
    true,
    true,
    false,
    'private',
    'registered',
    true,
    false,
    true
  )$$,
  'owner can update richer profile and privacy preferences'
);

select is(
  (select preferred_name from public.profiles where id = auth.uid()),
  'Mans',
  'preferred name is stored'
);

select is(
  (select avatar_url from public.profiles where id = auth.uid()),
  'https://example.invalid/avatar.png',
  'avatar URL is stored'
);

select is(
  (
    select profile_visibility
    from public.account_preferences
    where user_id = auth.uid()
  ),
  'private',
  'profile visibility is stored'
);

select is(
  (
    select allow_recommendations
    from public.account_preferences
    where user_id = auth.uid()
  ),
  false,
  'recommendation preference is stored'
);

select lives_ok(
  $$select public.set_client_saved_item(
    'category',
    'c1100000-0000-0000-0000-000000000010'::uuid,
    true
  )$$,
  'owner can save a discoverable category'
);

select is(
  (select count(*)::integer from public.list_my_saved_items()),
  1,
  'saved-item list returns owner bookmark'
);

select lives_ok(
  $$select public.set_client_saved_item(
    'category',
    'c1100000-0000-0000-0000-000000000010'::uuid,
    false
  )$$,
  'owner can remove a saved category'
);

select is(
  (select count(*)::integer from public.list_my_saved_items()),
  0,
  'removed item no longer appears in saved list'
);

select throws_ok(
  $$select public.set_client_saved_item(
    'category',
    'c1100000-0000-0000-0000-000000009999'::uuid,
    true
  )$$,
  'P0001',
  'Saved item is not available',
  'unavailable entities cannot be bookmarked'
);

select lives_ok(
  $$insert into public.trusted_people (
    owner_id, display_name, relationship, phone
  ) values (
    auth.uid(), 'Aunty Test', 'Aunty', '+675 7000 0020'
  )$$,
  'owner can add a trusted person'
);

select is(
  (select count(*)::integer from public.trusted_people),
  1,
  'owner can read own trusted people'
);

select lives_ok(
  $$select public.submit_service_review(
    'c1100000-0000-0000-0000-000000000012'::uuid,
    5,
    'Excellent Wantok service.',
    'Very helpful',
    array['https://example.invalid/review.jpg'],
    null
  )$$,
  'customer can review a completed booking'
);

select is(
  (
    select rating
    from public.service_reviews
    where booking_id = 'c1100000-0000-0000-0000-000000000012'::uuid
  ),
  5,
  'review rating is stored'
);

select is(
  (
    select visibility
    from public.service_reviews
    where booking_id = 'c1100000-0000-0000-0000-000000000012'::uuid
  ),
  'registered',
  'review defaults to account review-visibility preference'
);

select is(
  (
    select rating_average
    from public.provider_profiles
    where provider_id = 'c1100000-0000-0000-0000-000000000002'::uuid
  ),
  5.00::numeric,
  'existing provider rating aggregate is refreshed'
);

select throws_ok(
  $$insert into public.service_reviews (
    booking_id, reviewer_id, provider_id, rating
  ) values (
    'c1100000-0000-0000-0000-000000000012',
    auth.uid(),
    'c1100000-0000-0000-0000-000000000002',
    4
  )$$,
  '42501',
  null,
  'direct review insertion is blocked in favour of secured RPC'
);

select set_config(
  'request.jwt.claim.sub',
  'c1100000-0000-0000-0000-000000000003',
  true
);

select is(
  (select count(*)::integer from public.trusted_people),
  0,
  'another account cannot read owner trusted people'
);

select is(
  (select count(*)::integer from public.list_my_saved_items()),
  0,
  'another account cannot read owner bookmarks through the secured API'
);

select is(
  (
    select count(*)::integer
    from public.get_client_profile(
      'c1100000-0000-0000-0000-000000000001'::uuid
    )
  ),
  0,
  'private client profile is hidden from another account'
);

select set_config(
  'request.jwt.claim.sub',
  'c1100000-0000-0000-0000-000000000001',
  true
);

select is(
  (
    select count(*)::integer
    from public.get_client_profile(auth.uid())
  ),
  1,
  'owner can always read own client profile'
);

select lives_ok(
  $$select public.update_my_account_profile_v2(
    'CX1 Owner Updated',
    'Mans',
    '+675 7000 0001',
    'Lae, Morobe Province',
    'https://example.invalid/avatar.png',
    'Local Wantok user profile.',
    true,
    true,
    false,
    'public',
    'registered',
    true,
    false,
    true
  )$$,
  'owner can make client profile public'
);

select set_config(
  'request.jwt.claim.sub',
  'c1100000-0000-0000-0000-000000000003',
  true
);

select is(
  (
    select count(*)::integer
    from public.get_client_profile(
      'c1100000-0000-0000-0000-000000000001'::uuid
    )
  ),
  1,
  'public client profile is visible to another account'
);

reset role;
select * from finish();
rollback;
