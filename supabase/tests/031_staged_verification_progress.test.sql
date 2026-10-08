begin;
create extension if not exists pgtap with schema extensions;
select plan(24);

select has_table('public','staged_verification_checks','Separate per-application progress checks exist');
select has_table('public','staged_verification_audit','Separate immutable review audit exists');
select ok((select relrowsecurity from pg_class where oid='public.staged_verification_checks'::regclass),'Review checks are RLS protected');
select ok((select relrowsecurity from pg_class where oid='public.staged_verification_audit'::regclass),'Audit is RLS protected');
select ok(not has_table_privilege('authenticated','public.staged_verification_checks','INSERT'),'No direct user insert');
select ok(not has_table_privilege('authenticated','public.staged_verification_checks','UPDATE'),'No direct user update');
select ok(not has_table_privilege('authenticated','public.staged_verification_checks','DELETE'),'No direct user delete');
select ok(not has_table_privilege('authenticated','public.staged_verification_audit','INSERT'),'Audit append only through secure RPC');
select ok(has_function_privilege('authenticated','public.update_staged_verification_check(uuid,text)','EXECUTE'),'Secure RPC callable after server-side role checks');

insert into auth.users(id,aud,role,email,raw_user_meta_data,created_at,updated_at) values
 ('c3100000-0000-0000-0000-000000000001','authenticated','authenticated','reviewcheck-a@wantok.local','{"full_name":"Review Applicant A"}'::jsonb,now(),now()),
 ('c3100000-0000-0000-0000-000000000002','authenticated','authenticated','reviewcheck-b@wantok.local','{"full_name":"Review Applicant B"}'::jsonb,now(),now()),
 ('c3100000-0000-0000-0000-000000000003','authenticated','authenticated','reviewcheck-admin@wantok.local','{"full_name":"Review Administrator"}'::jsonb,now(),now());
update public.profiles set is_admin=true where id='c3100000-0000-0000-0000-000000000003';

set local role authenticated;
select set_config('request.jwt.claim.sub','c3100000-0000-0000-0000-000000000001',true);
select lives_ok(
 $$select public.submit_staged_provider_application('home-services','Reviewer Test Provider','business','Morobe','Lae','Home service and repairs in Morobe')$$,
 'Preliminary application creates checklist without document upload');
select is((select count(*)::int from public.staged_verification_checks),3,'Auto-populated three category-specific checks');
select is((select count(*)::int from public.staged_verification_checks where review_status='pending'),3,'All checks start pending');
select is((select count(*)::int from public.staged_verification_audit),0,'Applicant sees no admin audit');
select throws_ok(
 $$select public.update_staged_verification_check((select id from public.staged_verification_checks limit 1),'needs_followup')$$,
 '42501','Admin access required','Applicant cannot edit progress');

select set_config('request.jwt.claim.sub','c3100000-0000-0000-0000-000000000002',true);
select is((select count(*)::int from public.staged_verification_checks),0,'Another user cannot read checks');

select set_config('request.jwt.claim.sub','c3100000-0000-0000-0000-000000000003',true);
select is((select count(*)::int from public.staged_verification_checks),3,'Admin can read verification progress');
select throws_ok(
 $$select public.update_staged_verification_check((select id from public.staged_verification_checks limit 1),'needs_followup')$$,
 '22023','Application is not in preliminary review','Cannot review pending intake before triage');
select lives_ok(
 $$select public.triage_staged_provider_application(id,'in_review') from public.staged_provider_applications where status='submitted'$$,
 'Admin moves application into manual review');
select lives_ok(
 $$select public.update_staged_verification_check((select id from public.staged_verification_checks limit 1),'needs_followup')$$,
 'Admin can request follow-up without provider approval');
select is((select count(*)::int from public.staged_verification_audit),1,'Progress change writes one audit event');
select throws_ok(
 $$select public.update_staged_verification_check((select id from public.staged_verification_checks limit 1),'approved')$$,
 '22023','Only preliminary review progress is supported','There is no approval transition');
select lives_ok(
 $$select public.update_staged_verification_check((select id from public.staged_verification_checks where review_status='needs_followup' limit 1),'needs_followup')$$,
 'Idempotent repeated review update does not fail');
select is((select count(*)::int from public.staged_verification_audit),1,'Idempotent update writes no additional audit');
select is((select count(*)::int from public.provider_profiles where provider_id='c3100000-0000-0000-0000-000000000001'),0,'No provider verification or activation');

select * from finish();
rollback;
