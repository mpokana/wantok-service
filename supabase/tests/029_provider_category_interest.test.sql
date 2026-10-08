begin;
create extension if not exists pgtap with schema extensions;
select plan(10);

select has_table('public','provider_category_interests',
 'Provider interest stores only user and controlled category');
select ok(
 (select relrowsecurity from pg_class
  where oid='public.provider_category_interests'::regclass),
 'Provider interest is protected by RLS');
select ok(not has_table_privilege('authenticated',
 'public.provider_category_interests','INSERT'),
 'Clients cannot insert interest directly');
select ok(has_function_privilege('authenticated',
 'public.register_provider_category_interest(text)','EXECUTE'),
 'Authenticated users can invoke reviewed registration RPC');

insert into auth.users(
 id, aud, role, email, raw_user_meta_data, created_at, updated_at)
values
 ('c2900000-0000-0000-0000-000000000001',
  'authenticated','authenticated','interest-1@wantok.local',
  '{"full_name":"Interest One"}'::jsonb,now(),now()),
 ('c2900000-0000-0000-0000-000000000002',
  'authenticated','authenticated','interest-2@wantok.local',
  '{"full_name":"Interest Two"}'::jsonb,now(),now());

set local role authenticated;
select set_config('request.jwt.claim.sub',
 'c2900000-0000-0000-0000-000000000001',true);

select lives_ok($$select public.register_provider_category_interest('health-medical')$$,
 'Authorised account records interest, not provider approval');
select is(
 (select count(*)::int from public.provider_category_interests),
 1, 'Self sees exactly one new interest');
select lives_ok($$select public.register_provider_category_interest('health-medical')$$,
 'Repeated registration is safely idempotent');
select is((select count(*)::int from public.provider_category_interests),
 1,'Repeated registration creates no duplicate');
select throws_ok(
 $$select public.register_provider_category_interest('food')$$,
 '22023','Category is not accepting provider interest',
 'Live transaction categories cannot use staged interest endpoint');

select set_config('request.jwt.claim.sub',
 'c2900000-0000-0000-0000-000000000002',true);
select is((select count(*)::int from public.provider_category_interests),
 0,'Another account cannot see the first user interest');

reset role;
select * from finish();
rollback;
