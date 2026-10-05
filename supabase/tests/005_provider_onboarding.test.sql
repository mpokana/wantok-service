begin;

create extension if not exists pgtap with schema extensions;
select plan(7);

insert into auth.users (
  id, aud, role, email, raw_user_meta_data, created_at, updated_at
) values (
  '60000000-0000-0000-0000-000000000006',
  'authenticated',
  'authenticated',
  'onboarding-test@wantok.local',
  '{"full_name":"Onboarding Test"}'::jsonb,
  now(),
  now()
);

select is(
  (select count(*)::integer
   from public.profiles
   where id = '60000000-0000-0000-0000-000000000006'::uuid),
  1,
  'auth trigger creates onboarding profile'
);

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '60000000-0000-0000-0000-000000000006',
  true
);

select lives_ok(
  $$select public.submit_provider_application(
    'vehicle_hire',
    'Morobe Hire Test',
    null,
    null,
    null,
    null,
    'Vehicle hire onboarding test'
  )$$,
  'customer can submit supported provider application through RPC'
);

select is(
  (select count(*)::integer
   from public.provider_applications
   where user_id = auth.uid()
     and service_type = 'vehicle_hire'
     and status = 'pending'),
  1,
  'provider application is stored as pending'
);

select throws_ok(
  $$select public.submit_provider_application(
    'vehicle_hire',
    'Duplicate Test',
    null,
    null,
    null,
    null,
    null
  )$$,
  'P0001',
  'An application already exists for this service',
  'duplicate active application is rejected'
);

select throws_ok(
  $$select public.submit_provider_application(
    'unknown_service',
    null,
    null,
    null,
    null,
    null,
    null
  )$$,
  'P0001',
  'Unsupported provider service type',
  'unsupported provider service type is rejected'
);

select throws_ok(
  $$insert into public.provider_applications (
    user_id, service_type
  ) values (
    auth.uid(), 'boat_hire'
  )$$,
  '42501',
  null,
  'direct provider application insert is blocked'
);

select is(
  (select count(*)::integer
   from public.provider_applications
   where user_id = auth.uid()),
  1,
  'failed direct insert did not create another application'
);

reset role;
select * from finish();
rollback;
