begin;

create extension if not exists pgtap with schema extensions;
select plan(18);

insert into auth.users (
  id, aud, role, email, raw_user_meta_data, created_at, updated_at
) values
  ('c1000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated',
   'account-owner@wantok.local', '{"full_name":"Account Owner"}'::jsonb, now(), now()),
  ('c1000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated',
   'account-other@wantok.local', '{"full_name":"Account Other"}'::jsonb, now(), now());

update public.profiles
set is_provider = true
where id = 'c1000000-0000-0000-0000-000000000001'::uuid;

insert into public.provider_profiles (
  provider_id,
  display_name,
  provider_type,
  verification_status,
  is_active
) values (
  'c1000000-0000-0000-0000-000000000001',
  'Original Provider',
  'individual',
  'verified',
  true
);

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  'c1000000-0000-0000-0000-000000000001',
  true
);

select lives_ok(
  $$select * from public.get_my_account_profile()$$,
  'authenticated user can load own account profile'
);

select is(
  (select full_name from public.get_my_account_profile()),
  'Account Owner',
  'account profile returns current full name'
);

select lives_ok(
  $$select public.update_my_account_profile(
    'Mans Test',
    'Mans',
    '+675 7000 0000',
    'Lae, Morobe Province',
    true,
    false,
    true
  )$$,
  'owner can update personal profile and preferences'
);

select is(
  (select full_name from public.profiles where id = auth.uid()),
  'Mans Test',
  'full name is updated'
);

select is(
  (select preferred_name from public.profiles where id = auth.uid()),
  'Mans',
  'preferred name is updated'
);

select is(
  (select phone from public.profiles where id = auth.uid()),
  '+675 7000 0000',
  'phone is updated'
);

select is(
  (select address_text from public.profiles where id = auth.uid()),
  'Lae, Morobe Province',
  'address is updated'
);

select is(
  (select notify_messages from public.account_preferences where user_id = auth.uid()),
  false,
  'notification preferences are persisted'
);

select throws_ok(
  $$update public.profiles set is_admin = true where id = auth.uid()$$,
  '42501',
  null,
  'profile owner cannot grant self admin flag'
);

select throws_ok(
  $$update public.provider_profiles
    set verification_status = 'verified'
    where provider_id = auth.uid()$$,
  '42501',
  null,
  'provider cannot directly mutate verification authority'
);

select lives_ok(
  $$select public.update_my_provider_profile(
    'Updated Provider',
    'business',
    'Local services for testing.',
    'Lae',
    25
  )$$,
  'provider can update descriptive provider profile'
);

select is(
  (select display_name from public.get_my_provider_profile()),
  'Updated Provider',
  'provider display name is updated'
);

select is(
  (select provider_type from public.get_my_provider_profile()),
  'business',
  'provider type is updated'
);

select is(
  (select service_radius_km from public.get_my_provider_profile()),
  25::numeric,
  'provider service radius is updated'
);

select is(
  (select verification_status from public.get_my_provider_profile()),
  'verified',
  'provider update does not change verification status'
);

select set_config(
  'request.jwt.claim.sub',
  'c1000000-0000-0000-0000-000000000002',
  true
);

select is(
  (select count(*)::integer from public.account_preferences),
  0,
  'another user cannot read owner preferences through RLS'
);

select is(
  (select count(*)::integer from public.get_my_provider_profile()),
  0,
  'non-provider cannot read another providers private profile'
);

select throws_ok(
  $$select public.update_my_provider_profile(
    'Not Allowed',
    'individual',
    null,
    null,
    null
  )$$,
  'P0001',
  'Provider profile not found',
  'non-provider cannot update a provider profile'
);

reset role;
select * from finish();
rollback;
