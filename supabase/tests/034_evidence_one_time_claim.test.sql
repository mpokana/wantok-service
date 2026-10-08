begin;
create extension if not exists pgtap with schema extensions;
select plan(25);
select has_column('public','staged_evidence_intake_intents','claim_id','Claim receipt ID exists');
select has_column('public','staged_evidence_intake_intents','claimed_at','Claim timestamp exists');
select has_table('public','staged_evidence_intent_claim_receipts','Server claim receipts exist');
select ok((select relrowsecurity from pg_class
 where oid='public.staged_evidence_intent_claim_receipts'::regclass),'Receipt RLS enabled');
select ok(not has_table_privilege('authenticated','public.staged_evidence_intent_claim_receipts','SELECT'),'Applicant cannot list claim receipts');
select ok(not has_table_privilege('authenticated','public.staged_evidence_intent_claim_receipts','INSERT'),'Applicant cannot forge claim receipts');
select ok(not has_function_privilege('authenticated','public.claim_staged_evidence_intake(uuid,uuid,uuid,uuid)','EXECUTE'),'Applicant cannot invoke claim RPC');
select ok(not has_function_privilege('anon','public.claim_staged_evidence_intake(uuid,uuid,uuid,uuid)','EXECUTE'),'Anonymous cannot claim');
select ok(has_function_privilege('service_role','public.claim_staged_evidence_intake(uuid,uuid,uuid,uuid)','EXECUTE'),'Only server service role can claim');
select is((select count(*)::int from pg_policies
 where schemaname='storage' and tablename='objects' and
 (qual like '%staged-provider-evidence%' or with_check like '%staged-provider-evidence%')),0,
 'Storage bucket remains sealed');

insert into auth.users(id,aud,role,email,raw_user_meta_data,created_at,updated_at) values
 ('c3400000-0000-0000-0000-000000000001','authenticated','authenticated','claim-owner@wantok.local','{"full_name":"Claim Owner"}'::jsonb,now(),now()),
 ('c3400000-0000-0000-0000-000000000002','authenticated','authenticated','claim-stranger@wantok.local','{"full_name":"Claim Stranger"}'::jsonb,now(),now()),
 ('c3400000-0000-0000-0000-000000000003','authenticated','authenticated','claim-admin@wantok.local','{"full_name":"Claim Admin"}'::jsonb,now(),now());
update public.profiles set is_admin=true where id='c3400000-0000-0000-0000-000000000003';

set local role authenticated;
select set_config('request.jwt.claim.sub','c3400000-0000-0000-0000-000000000001',true);
select lives_ok($$select public.submit_staged_provider_application(
 'home-services','Claim Applicant','individual','Morobe','Lae','Electrical repairs and trades')$$,
 'Applicant preliminary application exists');
select set_config('request.jwt.claim.sub','c3400000-0000-0000-0000-000000000003',true);
select lives_ok($$select public.triage_staged_provider_application(
 (select id from public.staged_provider_applications where user_id='c3400000-0000-0000-0000-000000000001'),'in_review')$$,
 'Admin triages application');
select lives_ok($$select public.plan_staged_evidence_requirement(
 (select id from public.staged_verification_checks where application_id=
  (select id from public.staged_provider_applications where user_id='c3400000-0000-0000-0000-000000000001') limit 1))$$,
 'Admin plans future evidence');
select set_config('request.jwt.claim.sub','c3400000-0000-0000-0000-000000000001',true);
select lives_ok($$select public.prepare_staged_evidence_intake(
 (select id from public.staged_verification_checks where application_id=
  (select id from public.staged_provider_applications where user_id='c3400000-0000-0000-0000-000000000001') limit 1),
 'WANTOK-EVIDENCE-INTAKE-DRAFT-2026-10')$$,'Owner prepares intent');

set local role service_role;
select throws_ok($$select public.claim_staged_evidence_intake(
 (select id from public.staged_evidence_intake_intents limit 1),
 'c3400000-0000-0000-0000-000000000002',
 (select application_id from public.staged_evidence_intake_intents limit 1),
 (select check_id from public.staged_evidence_intake_intents limit 1))$$,
 '22023','Evidence intent not eligible for one-time claim','Foreign account cannot claim');
select throws_ok($$select public.claim_staged_evidence_intake(
 (select id from public.staged_evidence_intake_intents limit 1),
 'c3400000-0000-0000-0000-000000000001',
 '00000000-0000-0000-0000-000000000000',
 (select check_id from public.staged_evidence_intake_intents limit 1))$$,
 '22023','Evidence intent not eligible for one-time claim','Application mismatch rejected');
select throws_ok($$select public.claim_staged_evidence_intake(
 (select id from public.staged_evidence_intake_intents limit 1),
 'c3400000-0000-0000-0000-000000000001',
 (select application_id from public.staged_evidence_intake_intents limit 1),
 '00000000-0000-0000-0000-000000000000')$$,
 '22023','Evidence intent not eligible for one-time claim','Check mismatch rejected');
select lives_ok($$select public.claim_staged_evidence_intake(
 (select id from public.staged_evidence_intake_intents limit 1),
 'c3400000-0000-0000-0000-000000000001',
 (select application_id from public.staged_evidence_intake_intents limit 1),
 (select check_id from public.staged_evidence_intake_intents limit 1))$$,
 'Exactly one valid server claim succeeds');
select is((select state from public.staged_evidence_intake_intents limit 1),'claimed_for_quarantine',
 'Claim changes state, NOT provider approval');
select is((select count(*)::int from public.staged_evidence_intent_claim_receipts),1,
 'Exactly one durable claim receipt');
select ok((select i.claim_id=r.claim_id and i.claimed_at=r.claimed_at
 from public.staged_evidence_intake_intents i
 join public.staged_evidence_intent_claim_receipts r on r.intent_id=i.id limit 1),
 'Receipt binds intent, UUID and claim timestamp');
select throws_ok($$select public.claim_staged_evidence_intake(
 (select id from public.staged_evidence_intake_intents limit 1),
 'c3400000-0000-0000-0000-000000000001',
 (select application_id from public.staged_evidence_intake_intents limit 1),
 (select check_id from public.staged_evidence_intake_intents limit 1))$$,
 '22023','Evidence intent not eligible for one-time claim','Duplicate claim irreversibly refused');

set local role authenticated;
select set_config('request.jwt.claim.sub','c3400000-0000-0000-0000-000000000001',true);
select lives_ok($$select public.withdraw_staged_evidence_intake(
 (select id from public.staged_evidence_intake_intents limit 1))$$,
 'Applicant can revoke already-claimed intent');
select is((select state from public.staged_evidence_intake_intents limit 1),'withdrawn',
 'Withdrawal revokes state');
select is((select count(*)::int from storage.objects where bucket_id='staged-provider-evidence'),0,
 'No uploaded evidence objects');
select * from finish();
rollback;
