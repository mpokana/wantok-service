begin;
create extension if not exists pgtap with schema extensions;
select plan(29);

select has_table('public','staged_evidence_requirements','Admin-only evidence planning records exist');
select has_table('public','staged_evidence_requirement_audit','Planning event history exists');
select ok((select public=false from storage.buckets
  where id='staged-provider-evidence'),'New evidence bucket is non-public');
select is((select file_size_limit::bigint from storage.buckets
  where id='staged-provider-evidence'),5242880::bigint,
  'Quarantine bucket size ceiling is five MiB');
select ok((select allowed_mime_types =
  array['application/pdf','image/jpeg','image/png']::text[]
  from storage.buckets where id='staged-provider-evidence'),
  'Only a restricted MIME allowlist is declared');
select is((select count(*)::integer from pg_policies
  where schemaname='storage' and tablename='objects'
    and (coalesce(qual,'') like '%staged-provider-evidence%'
       or coalesce(with_check,'') like '%staged-provider-evidence%')),0,
  'No Storage object policies enable user access to evidence');
select ok((select relrowsecurity from pg_class where oid =
  'public.staged_evidence_requirements'::regclass),
  'Planning table enables RLS');
select ok((select relrowsecurity from pg_class where oid =
  'public.staged_evidence_requirement_audit'::regclass),
  'Planning audit enables RLS');
select ok(not has_table_privilege('authenticated',
  'public.staged_evidence_requirements','INSERT'),
  'Authenticated users cannot insert planning rows directly');
select ok(not has_table_privilege('authenticated',
  'public.staged_evidence_requirements','UPDATE'),
  'Authenticated users cannot mutate planning rows directly');
select ok(not has_table_privilege('authenticated',
  'public.staged_evidence_requirement_audit','INSERT'),
  'Authenticated users cannot forge the audit');
select ok(has_function_privilege('authenticated',
  'public.plan_staged_evidence_requirement(uuid)','EXECUTE'),
  'Only authenticated roles can call the guarded planner');

insert into auth.users(id,aud,role,email,raw_user_meta_data,created_at,updated_at) values
 ('c3200000-0000-0000-0000-000000000001','authenticated','authenticated',
  'evidence-applicant-one@wantok.local','{"full_name":"Test Applicant One"}'::jsonb,now(),now()),
 ('c3200000-0000-0000-0000-000000000002','authenticated','authenticated',
  'evidence-applicant-two@wantok.local','{"full_name":"Test Applicant Two"}'::jsonb,now(),now()),
 ('c3200000-0000-0000-0000-000000000003','authenticated','authenticated',
  'evidence-admin@wantok.local','{"full_name":"Test Reviewer"}'::jsonb,now(),now());
update public.profiles set is_admin=true
 where id='c3200000-0000-0000-0000-000000000003';

set local role authenticated;
select set_config('request.jwt.claim.sub',
 'c3200000-0000-0000-0000-000000000001',true);
select lives_ok(
 $$select public.submit_staged_provider_application(
   'home-services','Evidence Test Provider','individual','Morobe','Lae',
   'House repairs and maintenance services')$$,
 'Applicant can submit the existing staged application');
select is((select count(*)::integer from public.staged_verification_checks),3,
 'Staged application creates three review requirements');
select throws_ok(
 $$select public.plan_staged_evidence_requirement(
   (select id from public.staged_verification_checks limit 1))$$,
 '42501','Admin access required',
 'Applicant cannot plan collection of sensitive evidence');

select throws_ok(
 $$insert into storage.objects(bucket_id,name,owner_id)
   values('staged-provider-evidence','unauthorised.pdf', auth.uid()::text)$$,
 '42501','new row violates row-level security policy for table "objects"',
 'Applicant cannot upload directly to the closed evidence bucket');
select set_config('request.jwt.claim.sub',
 'c3200000-0000-0000-0000-000000000002',true);
select is((select count(*)::integer from public.staged_verification_checks),0,
 'Another applicant cannot see protected checklist');
select set_config('request.jwt.claim.sub',
 'c3200000-0000-0000-0000-000000000003',true);
select throws_ok(
 $$select public.plan_staged_evidence_requirement(
   (select id from public.staged_verification_checks limit 1))$$,
 '22023','Application is not in preliminary review',
 'Admin must triage staged application before planning');
select lives_ok(
 $$select public.triage_staged_provider_application(
   (select id from public.staged_provider_applications limit 1),
   'in_review')$$,
 'Admin moves preliminary application into manual review');
select lives_ok(
 $$select public.plan_staged_evidence_requirement(
   (select id from public.staged_verification_checks limit 1))$$,
 'Admin records a planned evidence requirement without file upload');
select lives_ok(
 $$select public.plan_staged_evidence_requirement(
   (select id from public.staged_verification_checks limit 1))$$,
 'Repeating a plan is idempotent');
select is((select count(*)::integer from public.staged_evidence_requirement_audit),
  1,'Idempotent planning creates exactly one audit event');
select set_config('request.jwt.claim.sub',
 'c3200000-0000-0000-0000-000000000001',true);
select is((select count(*)::integer from public.staged_evidence_requirements),1,
 'Owner sees their own planned requirement');
select is((select count(*)::integer from public.staged_evidence_requirement_audit),0,
 'Applicant cannot view admin-only planning audit');
select throws_ok(
 $$select public.cancel_staged_evidence_requirement(
   (select check_id from public.staged_evidence_requirements limit 1))$$,
 '42501','Admin access required',
 'Applicant cannot cancel administrator planning');
select set_config('request.jwt.claim.sub',
 'c3200000-0000-0000-0000-000000000002',true);
select is((select count(*)::integer from public.staged_evidence_requirements),0,
 'Another applicant cannot view the owner planning');
select set_config('request.jwt.claim.sub',
 'c3200000-0000-0000-0000-000000000003',true);
select lives_ok(
 $$select public.cancel_staged_evidence_requirement(
   (select check_id from public.staged_evidence_requirements limit 1))$$,
 'Admin cancels the planning signal');
select is((select count(*)::integer from public.staged_evidence_requirement_audit),
  2,'Cancellation appends an audit entry');
select is((select count(*)::integer from storage.objects
  where bucket_id='staged-provider-evidence'),0,
  'No file or real document was uploaded');

reset role;
select * from finish();
rollback;
