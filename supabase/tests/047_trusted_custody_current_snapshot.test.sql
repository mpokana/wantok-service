BEGIN;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SELECT plan(17);
SELECT has_function('public','read_staged_custody_reconciliation',ARRAY['uuid'],
 'Restricted, current-state custody read endpoint exists');
SELECT ok(NOT has_function_privilege('authenticated',
 'public.read_staged_custody_reconciliation(uuid)','EXECUTE'),
 'Applicant cannot call trusted custody reader');
SELECT ok(NOT has_function_privilege('anon',
 'public.read_staged_custody_reconciliation(uuid)','EXECUTE'),
 'Anonymous caller cannot read custody');
SELECT ok(has_function_privilege('service_role',
 'public.read_staged_custody_reconciliation(uuid)','EXECUTE'),
 'Server role is permitted to read current claim state');
SELECT is((SELECT count(*)::integer FROM pg_policies
 WHERE schemaname='storage' AND tablename='objects'
 AND (COALESCE(qual,'') LIKE '%staged-provider-evidence%'
 OR COALESCE(with_check,'') LIKE '%staged-provider-evidence%')),0,
 'Evidence Storage remains sealed');

INSERT INTO auth.users(id,aud,role,email,raw_user_meta_data,created_at,updated_at)
 VALUES
 ('c4700000-0000-4000-8000-000000000001',
  'authenticated','authenticated','current-custody-owner@wantok.local',
  '{"full_name":"Current Custody Test"}'::jsonb,now(),now()),
 ('c4700000-0000-4000-8000-000000000002',
  'authenticated','authenticated','current-custody-admin@wantok.local',
  '{"full_name":"Current Custody Admin"}'::jsonb,now(),now());
UPDATE public.profiles SET is_admin=true
 WHERE id='c4700000-0000-4000-8000-000000000002';
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.role','authenticated',true);
SELECT set_config('request.jwt.claim.sub',
 'c4700000-0000-4000-8000-000000000001',true);
SELECT lives_ok($$SELECT public.submit_staged_provider_application(
 'home-services','Current Custody Test Vendor','individual',
 'Morobe','Lae','Synthetic metadata-only reconciliation testing')$$,
 'Staged applicant created');
RESET ROLE;
SELECT public.map_operations_service_category(
 (SELECT category_id FROM public.staged_provider_applications LIMIT 1),
 'trades','c4700000-0000-4000-8000-000000000002'::uuid,
 'Synthetic service family mapping only for transaction rollback');
SELECT public.register_operations_region('PG-MPL','Morobe',
 'c4700000-0000-4000-8000-000000000002'::uuid,
 'Synthetic independently certified provincial location in test');
SELECT public.classify_operations_staged_application(
 (SELECT id FROM public.staged_provider_applications LIMIT 1),
 'PG-MPL','c4700000-0000-4000-8000-000000000002'::uuid,
 'Synthetic staged application jurisdiction certified in test');
INSERT INTO public.operations_duty_grants(
 staff_user_id,duty,country_code,region_code,category_scope,assignment_reason)
VALUES
 ('c4700000-0000-4000-8000-000000000002','case_reviewer','PG','PG-MPL','trades',
 'Synthetic staged reviewer assignment for rollback test only'),
 ('c4700000-0000-4000-8000-000000000002','evidence_officer','PG','PG-MPL','trades',
 'Synthetic staged evidence officer for rollback test only');
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub',
 'c4700000-0000-4000-8000-000000000002',true);
SELECT lives_ok($$SELECT public.triage_staged_provider_application(
 (SELECT id FROM public.staged_provider_applications
 WHERE user_id='c4700000-0000-4000-8000-000000000001'),'in_review')$$,
 'Staff starts review');
SELECT lives_ok($$SELECT public.plan_staged_evidence_requirement(
 (SELECT id FROM public.staged_verification_checks
 WHERE application_id=(SELECT id FROM public.staged_provider_applications
 WHERE user_id='c4700000-0000-4000-8000-000000000001') LIMIT 1))$$,
 'Evidence requirement planned');
SELECT set_config('request.jwt.claim.sub',
 'c4700000-0000-4000-8000-000000000001',true);
SELECT lives_ok($$SELECT public.prepare_staged_evidence_intake(
 (SELECT id FROM public.staged_verification_checks
 WHERE application_id=(SELECT id FROM public.staged_provider_applications
 WHERE user_id='c4700000-0000-4000-8000-000000000001') LIMIT 1),
 'WANTOK-EVIDENCE-INTAKE-DRAFT-2026-10')$$,
 'Draft intent prepared (still not consent)');

SET LOCAL ROLE service_role;
SELECT set_config('request.jwt.claim.role','service_role',true);
SELECT lives_ok($$SELECT public.claim_staged_evidence_intake(
 (SELECT id FROM public.staged_evidence_intake_intents
 WHERE applicant_id='c4700000-0000-4000-8000-000000000001'),
 'c4700000-0000-4000-8000-000000000001',
 (SELECT application_id FROM public.staged_evidence_intake_intents
 WHERE applicant_id='c4700000-0000-4000-8000-000000000001'),
 (SELECT check_id FROM public.staged_evidence_intake_intents
 WHERE applicant_id='c4700000-0000-4000-8000-000000000001'))$$,
 'Synthetic one-time claim created');
SELECT lives_ok($$SELECT public.record_staged_evidence_custody_manifest(
 (SELECT claim_id FROM public.staged_evidence_intake_intents),
 (SELECT id FROM public.staged_evidence_intake_intents),
 'c4700000-0000-4000-8000-000000000001',
 (SELECT application_id FROM public.staged_evidence_intake_intents),
 (SELECT check_id FROM public.staged_evidence_intake_intents),
 repeat('a',64),repeat('b',64),101,321,'application/pdf','synthetic-key-v1')$$,
 'Synthetic metadata manifest is recorded');
SELECT is((SELECT public.read_staged_custody_reconciliation(claim_id)
 ->>'claim_state' FROM public.staged_evidence_intake_intents),
 'claimed_for_quarantine','Current non-withdrawn claim state read');
SELECT is((SELECT public.read_staged_custody_reconciliation(claim_id)
 ->'snapshot'->>'sealed_sha256' FROM public.staged_evidence_intake_intents),
 repeat('b',64),'Current manifest digest read');
SELECT is((SELECT public.read_staged_custody_reconciliation(claim_id)
 ->'snapshot'->>'state' FROM public.staged_evidence_intake_intents),
 'pending_independent_reconciliation',
 'Matching metadata is still not approved');

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.role','authenticated',true);
SELECT set_config('request.jwt.claim.sub',
 'c4700000-0000-4000-8000-000000000001',true);
SELECT lives_ok($$SELECT public.withdraw_staged_evidence_intake(
 (SELECT id FROM public.staged_evidence_intake_intents))$$,
 'Applicant can withdraw a prior claim');
SET LOCAL ROLE service_role;
SELECT set_config('request.jwt.claim.role','service_role',true);
SELECT is((SELECT public.read_staged_custody_reconciliation(claim_id)
 ->>'claim_state' FROM public.staged_evidence_intake_intents),
 'withdrawn','Subsequent read reflects current withdrawal');
SELECT throws_ok($$SELECT public.read_staged_custody_reconciliation(
 'b4700000-0000-4000-8000-000000000099')$$,
 '42501','Custody reconciliation unavailable',
 'Unknown claim is blocked with generic error');
SELECT * FROM finish();
ROLLBACK;
