BEGIN;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SELECT plan(35);
SELECT has_table('public','operations_case_jurisdictions','Case jurisdictions registered independently');
SELECT has_table('public','operations_service_category_scopes','Service category mapping is controlled');
SELECT has_table('public','operations_approved_regions','Only independently checked subdivisions can be assigned');
SELECT has_table('public','operations_case_jurisdiction_events','Case classification changes have an audit');
SELECT has_function('public','has_operations_case_scope',ARRAY['text','uuid'],
 'Case access resolves the current JWT against verified scopes');
SELECT ok(NOT has_table_privilege('authenticated','public.operations_case_jurisdictions','SELECT'),
 'Direct classification list hidden from every browser');
SELECT ok(NOT has_table_privilege('authenticated','public.operations_case_jurisdictions','INSERT'),
 'Cannot self-classify a case');
SELECT ok(NOT has_function_privilege('authenticated',
 'public.register_operations_case_jurisdiction(uuid,text,uuid,text)','EXECUTE'),
 'Untrusted user cannot certify case jurisdiction');
SELECT ok(NOT has_function_privilege('authenticated',
 'public.map_operations_service_category(uuid,text,uuid,text)','EXECUTE'),
 'Untrusted user cannot change category scope');
SELECT ok(NOT has_function_privilege('authenticated',
 'public.register_operations_region(text,text,uuid,text)','EXECUTE'),
 'Untrusted user cannot certify a made-up province');

INSERT INTO auth.users(id,aud,role,email,created_at,updated_at) VALUES
 ('b5100000-0000-4000-8000-000000000001','authenticated','authenticated',
 'e6b-pg-applicant@wantok.local',now(),now()),
 ('b5100000-0000-4000-8000-000000000002','authenticated','authenticated',
 'e6b-case-reviewer@wantok.local',now(),now()),
 ('b5100000-0000-4000-8000-000000000003','authenticated','authenticated',
 'e6b-province-reviewer@wantok.local',now(),now()),
 ('b5100000-0000-4000-8000-000000000004','authenticated','authenticated',
 'e6b-wrong-category@wantok.local',now(),now()),
 ('b5100000-0000-4000-8000-000000000005','authenticated','authenticated',
 'e6b-evidence-officer@wantok.local',now(),now()),
 ('b5100000-0000-4000-8000-000000000006','authenticated','authenticated',
 'e6b-global-admin@wantok.local',now(),now()),
 ('b5100000-0000-4000-8000-000000000007','authenticated','authenticated',
 'e6b-au-applicant@wantok.local',now(),now());
UPDATE public.profiles SET is_admin=true
 WHERE id='b5100000-0000-4000-8000-000000000006';
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','b5100000-0000-4000-8000-000000000001',true);
SELECT lives_ok($$SELECT public.submit_vendor_intake_case(
 'home-services','individual','Synthetic Morobe Trades','PG','Morobe','Lae',
 'Lot 40 Main Street','e6bpg@example.test','+67570001111',
 'national_id','1212',NULL,NULL,'Plumbing and electrical repair work',
 '{"trade_speciality":"Plumbing"}'::jsonb)$$,
 'Applicants can continue metadata-only submissions');
SELECT set_config('request.jwt.claim.sub','b5100000-0000-4000-8000-000000000007',true);
SELECT lives_ok($$SELECT public.submit_vendor_intake_case(
 'home-services','individual','Synthetic Australia Trades','AU','New South Wales','Sydney',
 '42 Example Avenue','e6bau@example.test','+61700011111',
 'passport','3434',NULL,NULL,'Building maintenance and home repair work',
 '{"trade_speciality":"Plumbing"}'::jsonb)$$,
 'A different country still accepts staged metadata only');
RESET ROLE;
SELECT set_config('test.e6b_pg_case',(
 SELECT id::text FROM public.vendor_intake_cases
 WHERE applicant_id='b5100000-0000-4000-8000-000000000001'),true);
SELECT set_config('test.e6b_au_case',(
 SELECT id::text FROM public.vendor_intake_cases
 WHERE applicant_id='b5100000-0000-4000-8000-000000000007'),true);
SELECT public.map_operations_service_category(
 (SELECT category_id FROM public.vendor_intake_cases
 WHERE id=current_setting('test.e6b_pg_case')::uuid),'trades',
 'b5100000-0000-4000-8000-000000000002'::uuid,
 'Synthetic standalone test category mapping, not live governance');
SELECT public.register_operations_region('PG-MPL','Morobe',
 'b5100000-0000-4000-8000-000000000002'::uuid,
 'Synthetic independently checked province in test transaction');
SELECT public.register_operations_region('PG-NCD','National Capital District',
 'b5100000-0000-4000-8000-000000000002'::uuid,
 'Synthetic independently checked province in test transaction');
INSERT INTO public.operations_duty_grants(
 staff_user_id,duty,country_code,region_code,category_scope,assignment_reason)
VALUES
 ('b5100000-0000-4000-8000-000000000002','case_reviewer','PG','PG-MPL','trades',
 'Assigned to Morobe trades review in synthetic test'),
 ('b5100000-0000-4000-8000-000000000003','case_reviewer','PG','PG-NCD','trades',
 'Assigned to NCD trades review in synthetic test'),
 ('b5100000-0000-4000-8000-000000000004','case_reviewer','PG','PG-MPL','food',
 'Assigned only to food category in synthetic test'),
 ('b5100000-0000-4000-8000-000000000005','evidence_officer','PG','PG-MPL','trades',
 'Assigned only to Morobe evidence metadata testing');
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','b5100000-0000-4000-8000-000000000002',true);
SELECT is((SELECT count(*)::integer FROM public.vendor_intake_cases),0,
 'No access even with correct duty while the case is unclassified');
SELECT throws_ok($$SELECT public.triage_vendor_intake_case(
 current_setting('test.e6b_pg_case')::uuid,'start_review',NULL)$$,
 '42501','Scoped case reviewer required',
 'Unclassified intake remains closed to staff mutation');
SELECT set_config('request.jwt.claim.sub','b5100000-0000-4000-8000-000000000006',true);
SELECT is((SELECT count(*)::integer FROM public.vendor_intake_cases),0,
 'Global admin flag alone cannot see vendor case data');
SELECT throws_ok($$SELECT public.triage_vendor_intake_case(
 current_setting('test.e6b_pg_case')::uuid,'start_review',NULL)$$,
 '42501','Scoped case reviewer required',
 'Global admin alone cannot mutate pending case');
RESET ROLE;
SELECT throws_ok($$SELECT public.register_operations_case_jurisdiction(
 current_setting('test.e6b_pg_case')::uuid,'PG-FAKE',
 'b5100000-0000-4000-8000-000000000002'::uuid,
 'A synthetic region that has not been approved anywhere')$$,
 '22023','Verified case jurisdiction and category mapping required',
 'Unregistered subdivision cannot be certified');
SELECT public.register_operations_case_jurisdiction(
 current_setting('test.e6b_pg_case')::uuid,'PG-MPL',
 'b5100000-0000-4000-8000-000000000002'::uuid,
 'Synthetic classification from verified registry for tests');
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','b5100000-0000-4000-8000-000000000002',true);
SELECT is((SELECT count(*)::integer FROM public.vendor_intake_cases),1,
 'Correctly scoped reviewer sees one local case, not foreign AU case');
SELECT ok((SELECT count(*) >= 4 FROM public.vendor_verification_checks),
 'Scoped reviewer can inspect metadata-only checklist');
SELECT lives_ok($$SELECT public.triage_vendor_intake_case(
 current_setting('test.e6b_pg_case')::uuid,'start_review',NULL)$$,
 'Correctly assigned reviewer can start an in-scope case');
SELECT set_config('request.jwt.claim.sub','b5100000-0000-4000-8000-000000000003',true);
SELECT is((SELECT count(*)::integer FROM public.vendor_intake_cases),0,
 'Wrong-province reviewer cannot enumerate case');
SELECT throws_ok($$SELECT public.triage_vendor_intake_case(
 current_setting('test.e6b_pg_case')::uuid,'decline','Wrong province attempt')$$,
 '42501','Scoped case reviewer required','Wrong province cannot reject a case');
SELECT set_config('request.jwt.claim.sub','b5100000-0000-4000-8000-000000000004',true);
SELECT is((SELECT count(*)::integer FROM public.vendor_intake_cases),0,
 'Wrong-category reviewer cannot inspect a case');
SELECT set_config('request.jwt.claim.sub','b5100000-0000-4000-8000-000000000005',true);
SELECT is((SELECT count(*)::integer FROM public.vendor_intake_cases),1,
 'Evidence officer sees only in-scope intake');
SELECT throws_ok($$SELECT public.triage_vendor_intake_case(
 current_setting('test.e6b_pg_case')::uuid,'decline','Evidence officer cannot decline case')$$,
 '42501','Scoped case reviewer required',
 'Evidence officer does not inherit case reviewer authority');
SELECT lives_ok($$SELECT public.request_vendor_evidence(
 (SELECT id FROM public.vendor_verification_checks
 WHERE case_id=current_setting('test.e6b_pg_case')::uuid
 AND requirement_key='identity_check'),
 'Document request metadata only; uploads remain disallowed')$$,
 'Authorised evidence officer may request metadata only');
SELECT is((SELECT count(*)::integer FROM public.vendor_evidence_requests),1,
 'Evidence officer may read in-scope request');
SELECT set_config('request.jwt.claim.sub','b5100000-0000-4000-8000-000000000001',true);
SELECT is((SELECT count(*)::integer FROM public.vendor_evidence_requests),1,
 'Applicant continues to see their own request');
SELECT is((SELECT count(*)::integer FROM public.vendor_verification_checks),0,
 'Applicant cannot read internal review/check results');
RESET ROLE;
SELECT public.register_operations_case_jurisdiction(
 current_setting('test.e6b_pg_case')::uuid,'PG-NCD',
 'b5100000-0000-4000-8000-000000000002'::uuid,
 'Synthetic province correction for immediate privilege reevaluation');
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','b5100000-0000-4000-8000-000000000002',true);
SELECT is((SELECT count(*)::integer FROM public.vendor_intake_cases),0,
 'Old province reviewer immediately loses case read after correction');
SELECT set_config('request.jwt.claim.sub','b5100000-0000-4000-8000-000000000003',true);
SELECT is((SELECT count(*)::integer FROM public.vendor_intake_cases),1,
 'New province reviewer gains scope only after explicit case correction');
RESET ROLE;
SELECT public.map_operations_service_category(
 (SELECT category_id FROM public.vendor_intake_cases
 WHERE id=current_setting('test.e6b_pg_case')::uuid),'food',
 'b5100000-0000-4000-8000-000000000002'::uuid,
 'Synthetic taxonomy correction invalidates prior case mapping');
SET LOCAL ROLE authenticated;
SELECT is((SELECT count(*)::integer FROM public.vendor_intake_cases),0,
 'Category reclassification invalidates an unrecertified case');
RESET ROLE;
SELECT public.register_operations_case_jurisdiction(
 current_setting('test.e6b_pg_case')::uuid,'PG-MPL',
 'b5100000-0000-4000-8000-000000000002'::uuid,
 'New category approved after explicit case reclassification');
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','b5100000-0000-4000-8000-000000000004',true);
SELECT is((SELECT count(*)::integer FROM public.vendor_intake_cases),1,
 'Food reviewer gains access only after independent remapping');
RESET ROLE;
UPDATE public.operations_approved_regions SET is_enabled=false
 WHERE region_code='PG-MPL';
SET LOCAL ROLE authenticated;
SELECT is((SELECT count(*)::integer FROM public.vendor_intake_cases),0,
 'Disabling an approved subdivision immediately blocks reads');
RESET ROLE;
UPDATE public.operations_approved_regions SET is_enabled=true
 WHERE region_code='PG-MPL';
UPDATE public.operations_duty_grants SET revoked_at=clock_timestamp(),
 revoke_reason='Revoked synthetic reviewer grant for offline negative test'
 WHERE staff_user_id='b5100000-0000-4000-8000-000000000004';
SET LOCAL ROLE authenticated;
SELECT is((SELECT count(*)::integer FROM public.vendor_intake_cases),0,
 'Revoking a scoped duty immediately blocks the former reviewer');
SELECT * FROM finish();
ROLLBACK;
