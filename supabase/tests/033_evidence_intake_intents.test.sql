begin;
create extension if not exists pgtap with schema extensions;
select plan(23);
select has_table('public','staged_evidence_intake_intents','Intake intent metadata table exists');
select ok((select relrowsecurity from pg_class where oid='public.staged_evidence_intake_intents'::regclass),'RLS enabled');
select ok(not has_table_privilege('authenticated','public.staged_evidence_intake_intents','INSERT'),'No direct applicant INSERT');
select ok(not has_table_privilege('authenticated','public.staged_evidence_intake_intents','UPDATE'),'No direct applicant UPDATE');
select ok(not has_table_privilege('authenticated','public.staged_evidence_intake_intents','DELETE'),'No direct applicant DELETE');
select ok(not has_table_privilege('anon','public.staged_evidence_intake_intents','SELECT'),'Anonymous cannot view intents');
select ok(has_function_privilege('authenticated','public.prepare_staged_evidence_intake(uuid,text)','EXECUTE'),'Authenticated can call guarded intent RPC');
select is((select count(*)::int from pg_policies where schemaname='storage'
 and tablename='objects' and (qual like '%staged-provider-evidence%' or with_check like '%staged-provider-evidence%')),0,'Evidence bucket remains closed');
insert into auth.users(id,aud,role,email,raw_user_meta_data,created_at,updated_at) values
 ('c3300000-0000-0000-0000-000000000001','authenticated','authenticated','intent-user1@wantok.local','{"full_name":"Intent Applicant"}'::jsonb,now(),now()),
 ('c3300000-0000-0000-0000-000000000002','authenticated','authenticated','intent-user2@wantok.local','{"full_name":"Other Applicant"}'::jsonb,now(),now()),
 ('c3300000-0000-0000-0000-000000000003','authenticated','authenticated','intent-admin@wantok.local','{"full_name":"Intake Admin"}'::jsonb,now(),now());
update public.profiles set is_admin=true where id='c3300000-0000-0000-0000-000000000003';

set local role authenticated;
select set_config('request.jwt.claim.sub','c3300000-0000-0000-0000-000000000001',true);
select lives_ok(
 $$select public.submit_staged_provider_application('home-services','Intent Test Applicant','individual','Morobe','Lae','Domestic electrical and repair services')$$,
 'Existing staged flow creates application');
select throws_ok(
 $$select public.prepare_staged_evidence_intake(
 (select id from public.staged_verification_checks limit 1),'WANTOK-EVIDENCE-INTAKE-DRAFT-2026-10')$$,
 '22023','Evidence intake is not eligible','No intent before admin planning');
select set_config('request.jwt.claim.sub','c3300000-0000-0000-0000-000000000003',true);
select lives_ok(
 $$select public.triage_staged_provider_application(
 (select id from public.staged_provider_applications where user_id='c3300000-0000-0000-0000-000000000001'),'in_review')$$,
 'Administrator triages staged application');
select lives_ok(
 $$select public.plan_staged_evidence_requirement(
 (select id from public.staged_verification_checks limit 1))$$,
 'Administrator plans evidence requirement');
select set_config('request.jwt.claim.sub','c3300000-0000-0000-0000-000000000001',true);
select throws_ok(
 $$select public.prepare_staged_evidence_intake(
 (select id from public.staged_verification_checks limit 1),'wrong-version')$$,
 '22023','Consent notice version mismatch','Rejects wrong notice version');
select lives_ok(
 $$select public.prepare_staged_evidence_intake(
 (select id from public.staged_verification_checks limit 1),'WANTOK-EVIDENCE-INTAKE-DRAFT-2026-10')$$,
 'Owner can prepare a non-uploading intent');
select lives_ok(
 $$select public.prepare_staged_evidence_intake(
 (select id from public.staged_verification_checks limit 1),'WANTOK-EVIDENCE-INTAKE-DRAFT-2026-10')$$,
 'Owner repeated prepare is idempotent');
select is((select count(*)::int from public.staged_evidence_intake_intents),1,
 'Only one intent exists');
select is((select count(*)::int from public.staged_evidence_intake_intents where state='awaiting_secure_gateway'),1,
 'Intent remains awaiting gateway; no upload active');
select set_config('request.jwt.claim.sub','c3300000-0000-0000-0000-000000000002',true);
select is((select count(*)::int from public.staged_evidence_intake_intents),0,
 'Other authenticated account sees no intent');
select throws_ok(
 $$select public.prepare_staged_evidence_intake(
 (select id from public.staged_verification_checks limit 1),'WANTOK-EVIDENCE-INTAKE-DRAFT-2026-10')$$,
 '22023','Evidence intake is not eligible','Unrelated account cannot prepare intent');
select set_config('request.jwt.claim.sub','c3300000-0000-0000-0000-000000000001',true);
select lives_ok(
 $$select public.withdraw_staged_evidence_intake(
 (select id from public.staged_evidence_intake_intents limit 1))$$,
 'Owner can withdraw intent');
select is((select state from public.staged_evidence_intake_intents limit 1),'withdrawn',
 'Withdrawal is recorded');
select throws_ok(
 $$select public.prepare_staged_evidence_intake(
 (select id from public.staged_verification_checks limit 1),'WANTOK-EVIDENCE-INTAKE-DRAFT-2026-10')$$,
 '22023','Evidence intent already withdrawn','Withdrawal cannot be bypassed by preparing again');
select is((select count(*)::int from storage.objects
 where bucket_id='staged-provider-evidence'),0,'No evidence objects were uploaded');
select * from finish();
rollback;
