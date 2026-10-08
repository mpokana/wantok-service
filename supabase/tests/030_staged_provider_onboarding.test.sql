begin;
create extension if not exists pgtap with schema extensions;
select plan(18);

select has_table('public','provider_onboarding_policies','Category policy table exists');
select has_table('public','staged_provider_applications','Separate staged intake table exists');
select ok((select relrowsecurity from pg_class where oid='public.staged_provider_applications'::regclass),'Staged intake enforces RLS');
select ok(not has_table_privilege('authenticated','public.staged_provider_applications','INSERT'),'Ordinary account cannot insert table rows');
select ok(not has_table_privilege('authenticated','public.staged_provider_applications','UPDATE'),'Ordinary account cannot update review');
select is((select count(*)::int from public.provider_onboarding_policies where intake_status='staged'),3,'Only three low-risk categories opened for preliminary intake');
select is((select count(*)::int from public.provider_onboarding_policies where intake_status='restricted'),4,'Medical, financial, education and travel remain restricted');
select ok(has_function_privilege('authenticated','public.submit_staged_provider_application(text,text,text,text,text,text)','EXECUTE'),'Authenticated users can submit via guarded RPC');

insert into auth.users(id,aud,role,email,raw_user_meta_data,created_at,updated_at) values
 ('c3000000-0000-0000-0000-000000000001','authenticated','authenticated','staged-a@wantok.local','{"full_name":"Staged Applicant A"}'::jsonb,now(),now()),
 ('c3000000-0000-0000-0000-000000000002','authenticated','authenticated','staged-b@wantok.local','{"full_name":"Staged Applicant B"}'::jsonb,now(),now()),
 ('c3000000-0000-0000-0000-000000000003','authenticated','authenticated','staged-admin@wantok.local','{"full_name":"Staged Admin"}'::jsonb,now(),now());
update public.profiles set is_admin=true where id='c3000000-0000-0000-0000-000000000003';

set local role authenticated;
select set_config('request.jwt.claim.sub','c3000000-0000-0000-0000-000000000001',true);
select lives_ok(
 $$select public.submit_staged_provider_application('home-services','Example Home Provider','individual','Morobe','Lae','Home repairs and routine maintenance')$$,
 'Nonregulated staged application is accepted');
select is((select count(*)::int from public.staged_provider_applications),1,'Applicant can view one staged record');
select throws_ok(
 $$select public.submit_staged_provider_application('home-services','Example Home Provider','individual','Morobe','Lae','Home repairs and routine maintenance')$$,
 '23505','A preliminary application already exists for this category','No duplicate applications');
select throws_ok(
 $$select public.submit_staged_provider_application('health-medical','Example Clinic','business','Morobe','Lae','Healthcare and treatment services')$$,
 '22023','Formal category intake not available','Medical formal intake remains blocked');
select throws_ok(
 $$select public.submit_staged_provider_application('travel-flights','Example Travel','business','Morobe','Lae','Travel and airline sales')$$,
 '22023','Formal category intake not available','Travel provider intake remains blocked');
select throws_ok(
 $$select public.triage_staged_provider_application('00000000-0000-0000-0000-000000000001','in_review')$$,
 '42501','Admin access required','Regular user cannot triage');
select set_config('request.jwt.claim.sub','c3000000-0000-0000-0000-000000000002',true);
select is((select count(*)::int from public.staged_provider_applications),0,'Another user cannot view the application');
select set_config('request.jwt.claim.sub','c3000000-0000-0000-0000-000000000003',true);
select lives_ok(
 $$select public.triage_staged_provider_application(id,'in_review') from public.staged_provider_applications where status='submitted'$$,
 'An authorised admin can mark an application for manual review');
select throws_ok(
 $$select public.triage_staged_provider_application(id,'approved') from public.staged_provider_applications limit 1$$,
 '22023','Only preliminary triage is permitted','Admin cannot approve by using staged review RPC');
reset role;
select is((select count(*)::int from public.provider_profiles where provider_id='c3000000-0000-0000-0000-000000000001'),0,'No provider account or privilege created');
select * from finish();
rollback;
