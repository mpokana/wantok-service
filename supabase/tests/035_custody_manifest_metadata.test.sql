begin;
create extension if not exists pgtap with schema extensions;
select plan(31);

select has_table('public','staged_evidence_custody_manifests','Metadata-only manifest exists');
select ok((select relrowsecurity from pg_class
 where oid='public.staged_evidence_custody_manifests'::regclass),'Manifest RLS enabled');
select ok(not has_table_privilege('authenticated',
 'public.staged_evidence_custody_manifests','SELECT'),'Applicants cannot read ciphertext metadata');
select ok(not has_table_privilege('authenticated',
 'public.staged_evidence_custody_manifests','INSERT'),'Applicants cannot forge custody metadata');
select ok(not has_table_privilege('authenticated',
 'public.staged_evidence_custody_manifests','UPDATE'),'Applicants cannot change digests');
select ok(not has_table_privilege('anon',
 'public.staged_evidence_custody_manifests','SELECT'),'Anonymous users cannot read custody');
select ok(not has_function_privilege('authenticated',
 'public.record_staged_evidence_custody_manifest(uuid,uuid,uuid,uuid,uuid,text,text,bigint,bigint,text,text)','EXECUTE'),
 'Applicant cannot call privileged custody RPC');
select ok(not has_function_privilege('anon',
 'public.record_staged_evidence_custody_manifest(uuid,uuid,uuid,uuid,uuid,text,text,bigint,bigint,text,text)','EXECUTE'),
 'Anonymous cannot call privileged custody RPC');
select ok(has_function_privilege('service_role',
 'public.record_staged_evidence_custody_manifest(uuid,uuid,uuid,uuid,uuid,text,text,bigint,bigint,text,text)','EXECUTE'),
 'Service-role-only RPC exists');
select is((select count(*)::int from pg_policies
 where schemaname='storage' and tablename='objects'
 and (coalesce(qual,'') like '%staged-provider-evidence%'
   or coalesce(with_check,'') like '%staged-provider-evidence%')),0,
 'Sealed Storage access policies remain absent');

insert into auth.users(id,aud,role,email,raw_user_meta_data,created_at,updated_at)
 values
 ('c3500000-0000-0000-0000-000000000001','authenticated','authenticated',
  'custody-owner@wantok.local','{"full_name":"Custody Owner"}'::jsonb,now(),now()),
 ('c3500000-0000-0000-0000-000000000002','authenticated','authenticated',
  'custody-admin@wantok.local','{"full_name":"Custody Admin"}'::jsonb,now(),now());
update public.profiles set is_admin=true
 where id='c3500000-0000-0000-0000-000000000002';
set local role authenticated;
select set_config('request.jwt.claim.sub','c3500000-0000-0000-0000-000000000001',true);
select lives_ok($$select public.submit_staged_provider_application(
 'home-services','Custody Test Provider','individual','Morobe','Lae',
 'Synthetic metadata-only custody testing')$$,'Staged application prepared');
select set_config('request.jwt.claim.sub','c3500000-0000-0000-0000-000000000002',true);
select lives_ok($$select public.triage_staged_provider_application(
 (select id from public.staged_provider_applications
  where user_id='c3500000-0000-0000-0000-000000000001'),'in_review')$$,
 'Admin triaged applicant');
select lives_ok($$select public.plan_staged_evidence_requirement(
 (select id from public.staged_verification_checks where application_id=
  (select id from public.staged_provider_applications
   where user_id='c3500000-0000-0000-0000-000000000001') limit 1))$$,
 'Admin planned requirement');
select set_config('request.jwt.claim.sub','c3500000-0000-0000-0000-000000000001',true);
select lives_ok($$select public.prepare_staged_evidence_intake(
 (select id from public.staged_verification_checks where application_id=
  (select id from public.staged_provider_applications
   where user_id='c3500000-0000-0000-0000-000000000001') limit 1),
 'WANTOK-EVIDENCE-INTAKE-DRAFT-2026-10')$$,'Owner prepared intent');
set local role service_role;
select lives_ok($$select public.claim_staged_evidence_intake(
 (select id from public.staged_evidence_intake_intents
  where applicant_id='c3500000-0000-0000-0000-000000000001'),
 'c3500000-0000-0000-0000-000000000001',
 (select application_id from public.staged_evidence_intake_intents
  where applicant_id='c3500000-0000-0000-0000-000000000001'),
 (select check_id from public.staged_evidence_intake_intents
  where applicant_id='c3500000-0000-0000-0000-000000000001'))$$,
 'One-time claim receipt exists before manifest recording');

-- Fixed synthetic hashes: no filesystem bytes, path, filename, KMS material.
create temporary view custody_input as
select i.id as intent_id,i.claim_id,i.applicant_id,i.application_id,i.check_id
from public.staged_evidence_intake_intents i
where i.applicant_id='c3500000-0000-0000-0000-000000000001';
select throws_ok($$select public.record_staged_evidence_custody_manifest(
 (select claim_id from custody_input), (select intent_id from custody_input),
 'c3500000-0000-0000-0000-000000000002',
 (select application_id from custody_input), (select check_id from custody_input),
 repeat('a',64),repeat('b',64),101,320,'application/pdf','key-v1')$$,
 '22023','Custody claim unavailable or already recorded',
 'Foreign applicant cannot attach metadata');
select throws_ok($$select public.record_staged_evidence_custody_manifest(
 (select claim_id from custody_input), (select intent_id from custody_input),
 (select applicant_id from custody_input),
 (select application_id from custody_input), (select check_id from custody_input),
 'bad-hash',repeat('b',64),101,320,'application/pdf','key-v1')$$,
 '22023','Custody metadata is invalid','Malformed digest rejected');
select throws_ok($$select public.record_staged_evidence_custody_manifest(
 (select claim_id from custody_input), (select intent_id from custody_input),
 (select applicant_id from custody_input),
 (select application_id from custody_input), (select check_id from custody_input),
 repeat('a',64),repeat('b',64),101,320,'text/html','key-v1')$$,
 '22023','Custody metadata is invalid','Unexpected MIME rejected');
select throws_ok($$select public.record_staged_evidence_custody_manifest(
 (select claim_id from custody_input), (select intent_id from custody_input),
 (select applicant_id from custody_input),
 (select application_id from custody_input), (select check_id from custody_input),
 repeat('a',64),repeat('b',64),101,9500,'application/pdf','key-v1')$$,
 '22023','Custody metadata is invalid','Impossible envelope overhead refused');
select throws_ok($$select public.record_staged_evidence_custody_manifest(
 (select claim_id from custody_input), (select intent_id from custody_input),
 (select applicant_id from custody_input),
 (select application_id from custody_input), (select check_id from custody_input),
 repeat('a',64),repeat('b',64),101,320,'application/pdf','../secret')$$,
 '22023','Custody metadata is invalid','Invalid key identifier rejected');
select throws_ok($$select public.record_staged_evidence_custody_manifest(
 'b3500000-0000-0000-0000-000000000099', (select intent_id from custody_input),
 (select applicant_id from custody_input),
 (select application_id from custody_input), (select check_id from custody_input),
 repeat('a',64),repeat('b',64),101,320,'application/pdf','key-v1')$$,
 '22023','Custody claim unavailable or already recorded','Unknown claim rejected');
select throws_ok($$select public.record_staged_evidence_custody_manifest(
 (select claim_id from custody_input), (select intent_id from custody_input),
 (select applicant_id from custody_input),
 (select application_id from custody_input),
 'b3500000-0000-0000-0000-000000000099',
 repeat('a',64),repeat('b',64),101,320,'application/pdf','key-v1')$$,
 '22023','Custody claim unavailable or already recorded','Foreign check binding rejected');
select lives_ok($$select public.record_staged_evidence_custody_manifest(
 (select claim_id from custody_input), (select intent_id from custody_input),
 (select applicant_id from custody_input),
 (select application_id from custody_input), (select check_id from custody_input),
 repeat('a',64),repeat('b',64),101,320,'application/pdf','key-v1')$$,
 'Claim-bound metadata recorded for independent reconciliation');
select is((select count(*)::int from public.staged_evidence_custody_manifests),1,
 'Exactly one manifest stored');
select is((select state from public.staged_evidence_custody_manifests),
 'pending_independent_reconciliation','No manifest is marked reviewed or approved');
select ok((select m.claim_id=i.claim_id and m.intent_id=i.id
  and m.applicant_id=i.applicant_id and m.check_id=i.check_id
  from public.staged_evidence_custody_manifests m
  join public.staged_evidence_intake_intents i on i.id=m.intent_id limit 1),
 'Manifest binds original claim, intent and applicant/check');
select throws_ok($$select public.record_staged_evidence_custody_manifest(
 (select claim_id from custody_input), (select intent_id from custody_input),
 (select applicant_id from custody_input),
 (select application_id from custody_input), (select check_id from custody_input),
 repeat('c',64),repeat('d',64),101,320,'application/pdf','key-v2')$$,
 '22023','Custody claim unavailable or already recorded','Duplicate cannot replace stored digests');
select is((select plain_sha256 from public.staged_evidence_custody_manifests),
 repeat('a',64),'Original digest survives duplicate attempt');

set local role authenticated;
select set_config('request.jwt.claim.sub','c3500000-0000-0000-0000-000000000001',true);
select lives_ok($$select public.withdraw_staged_evidence_intake(
 (select id from public.staged_evidence_intake_intents
  where applicant_id='c3500000-0000-0000-0000-000000000001'))$$,
 'Owner can still withdraw claimed intent');
select throws_ok($$select count(*) from public.staged_evidence_custody_manifests$$,
 '42501','permission denied for table staged_evidence_custody_manifests',
 'Applicant has no direct manifest SELECT');
select is((select count(*)::int from storage.objects where bucket_id='staged-provider-evidence'),0,
 'No evidence object upload activated');

reset role;
select * from finish();
rollback;
