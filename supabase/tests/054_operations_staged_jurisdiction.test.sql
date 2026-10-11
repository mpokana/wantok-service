BEGIN;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SELECT plan(29);
SELECT has_table('public','operations_staged_jurisdictions',
 'Staged workflow has its own verified case jurisdiction');
SELECT has_table('public','operations_staged_jurisdiction_events',
 'Jurisdiction corrections are independently audited');
SELECT ok(NOT has_table_privilege('authenticated',
 'public.operations_staged_jurisdictions','SELECT'),
 'Browser cannot enumerate classified cases directly');
SELECT ok(NOT has_function_privilege('authenticated',
 'public.classify_operations_staged_application(uuid,text,uuid,text)','EXECUTE'),
 'Browser cannot classify its own staged application');
SELECT ok(has_function_privilege('service_role',
 'public.classify_operations_staged_application(uuid,text,uuid,text)','EXECUTE'),
 'Trusted service can certify staged region');
SELECT ok(NOT has_table_privilege('authenticated',
 'public.staged_verification_audit','INSERT'),
 'Browser cannot fabricate review audit history');

INSERT INTO auth.users(id,aud,role,email,created_at,updated_at)
SELECT ('b6400000-0000-4000-8000-'||lpad(n::text,12,'0'))::uuid,
 'authenticated','authenticated','e6e-staged-'||n||'@wantok.local',
 now(),now() FROM generate_series(1,7) n;
UPDATE public.profiles SET is_admin=true
 WHERE id='b6400000-0000-4000-8000-000000000002';
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub',
 'b6400000-0000-4000-8000-000000000001',true);
SELECT lives_ok($$SELECT public.submit_staged_provider_application(
 'home-services','Synthetic e6e applicant','individual','Morobe','Lae',
 'Electrical maintenance and home repair')$$,
 'Staged applicant can still submit metadata without official review');
SELECT is((SELECT count(*)::integer FROM public.staged_provider_applications),1,
 'Applicant sees their own unclassified case');
SELECT set_config('request.jwt.claim.sub',
 'b6400000-0000-4000-8000-000000000002',true);
SELECT is((SELECT count(*)::integer FROM public.staged_provider_applications),0,
 'Unassigned old global admin cannot enumerate unclassified case');
SELECT throws_ok($$SELECT public.triage_staged_provider_application(
 (SELECT id FROM public.staged_provider_applications LIMIT 1),'in_review')$$,
 '42501','Scoped staged case reviewer required',
 'Unassigned old admin cannot triage staged provider');
RESET ROLE;
SELECT set_config('test.e6e_case',(
 SELECT id::text FROM public.staged_provider_applications
 WHERE user_id='b6400000-0000-4000-8000-000000000001'),true);
SELECT public.map_operations_service_category(
 (SELECT category_id FROM public.staged_provider_applications
 WHERE id=current_setting('test.e6e_case')::uuid),'trades',
 'b6400000-0000-4000-8000-000000000003',
 'Transaction-scoped evidence for mock service family');
SELECT public.register_operations_region('PG-MPL','Morobe',
 'b6400000-0000-4000-8000-000000000003',
 'Synthetic PNG province certified for jurisdiction isolation');
SELECT public.register_operations_region('PG-NCD','National Capital District',
 'b6400000-0000-4000-8000-000000000003',
 'Synthetic PNG city subdivision for jurisdiction change');
INSERT INTO public.operations_duty_grants(
 staff_user_id,duty,country_code,region_code,category_scope,assignment_reason)
VALUES
 ('b6400000-0000-4000-8000-000000000003','case_reviewer','PG','PG-MPL','trades',
 'Synthetic exact-scope case-review permission for regression'),
 ('b6400000-0000-4000-8000-000000000004','evidence_officer','PG','PG-MPL','trades',
 'Synthetic exact-scope evidence officer for regression'),
 ('b6400000-0000-4000-8000-000000000005','case_reviewer','PG','PG-NCD','trades',
 'Different PNG province case reviewer for negative test'),
 ('b6400000-0000-4000-8000-000000000006','case_reviewer','AU',NULL,'trades',
 'Different country case reviewer for negative test'),
 ('b6400000-0000-4000-8000-000000000007','case_reviewer','PG','PG-MPL','food',
 'Wrong category case reviewer for negative test');
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub',
 'b6400000-0000-4000-8000-000000000003',true);
SELECT is((SELECT count(*)::integer FROM public.staged_provider_applications),0,
 'Valid staff grant cannot view unclassified staged case');
SELECT throws_ok($$SELECT public.triage_staged_provider_application(
 current_setting('test.e6e_case')::uuid,'in_review')$$,
 '42501','Scoped staged case reviewer required',
 'No reviewer can triage without independent mapping');
RESET ROLE;
SELECT throws_ok($$SELECT public.classify_operations_staged_application(
 current_setting('test.e6e_case')::uuid,'PG-FAKE',
 'b6400000-0000-4000-8000-000000000003',
 'Unrecognised plausible province must not classify the applicant')$$,
 '22023','Independently verified staged jurisdiction required',
 'Uncertified province code is not a valid authority');
SELECT public.classify_operations_staged_application(
 current_setting('test.e6e_case')::uuid,'PG-MPL',
 'b6400000-0000-4000-8000-000000000003',
 'Synthetic certified Morobe staged applicant for testing only');

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub',
 'b6400000-0000-4000-8000-000000000003',true);
SELECT is((SELECT count(*)::integer FROM public.staged_provider_applications),1,
 'Classified Morobe reviewer may inspect their case');
SELECT set_config('request.jwt.claim.sub',
 'b6400000-0000-4000-8000-000000000004',true);
SELECT is((SELECT count(*)::integer FROM public.staged_provider_applications),1,
 'Evidence officer may inspect only verified service-region case');
SELECT throws_ok($$SELECT public.triage_staged_provider_application(
 current_setting('test.e6e_case')::uuid,'in_review')$$,
 '42501','Scoped staged case reviewer required',
 'Evidence officer cannot inherit case reviewer duty');
SELECT set_config('request.jwt.claim.sub',
 'b6400000-0000-4000-8000-000000000005',true);
SELECT is((SELECT count(*)::integer FROM public.staged_provider_applications),0,
 'Wrong province reviewer has no staged case visibility');
SELECT set_config('request.jwt.claim.sub',
 'b6400000-0000-4000-8000-000000000006',true);
SELECT is((SELECT count(*)::integer FROM public.staged_provider_applications),0,
 'Wrong country reviewer has no staged case visibility');
SELECT set_config('request.jwt.claim.sub',
 'b6400000-0000-4000-8000-000000000007',true);
SELECT is((SELECT count(*)::integer FROM public.staged_provider_applications),0,
 'Wrong service family has no staged case visibility');
SELECT set_config('request.jwt.claim.sub',
 'b6400000-0000-4000-8000-000000000003',true);
SELECT lives_ok($$SELECT public.triage_staged_provider_application(
 current_setting('test.e6e_case')::uuid,'in_review')$$,
 'Mapped reviewer performs only preliminary triage');
SELECT lives_ok($$SELECT public.update_staged_verification_check(
 (SELECT id FROM public.staged_verification_checks
 WHERE application_id=current_setting('test.e6e_case')::uuid LIMIT 1),
 'needs_followup')$$,
 'Mapped reviewer records a preliminary follow-up check');
SELECT throws_ok($$SELECT public.plan_staged_evidence_requirement(
 (SELECT id FROM public.staged_verification_checks
 WHERE application_id=current_setting('test.e6e_case')::uuid LIMIT 1))$$,
 '42501','Scoped staged evidence officer required',
 'Review duty cannot be reused for evidence planning');
SELECT set_config('request.jwt.claim.sub',
 'b6400000-0000-4000-8000-000000000004',true);
SELECT lives_ok($$SELECT public.plan_staged_evidence_requirement(
 (SELECT id FROM public.staged_verification_checks
 WHERE application_id=current_setting('test.e6e_case')::uuid LIMIT 1))$$,
 'Independent evidence officer can plan metadata only');
SELECT set_config('request.jwt.claim.sub',
 'b6400000-0000-4000-8000-000000000002',true);
SELECT is((SELECT count(*)::integer FROM public.staged_verification_audit),0,
 'Global admin cannot inspect other reviewer audit');
RESET ROLE;
INSERT INTO public.operations_duty_grants(
 staff_user_id,duty,country_code,region_code,category_scope,assignment_reason)
 VALUES('b6400000-0000-4000-8000-000000000001',
 'case_reviewer','PG','PG-MPL','trades',
 'Synthetic applicant COI assignment must not permit self review');
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub',
 'b6400000-0000-4000-8000-000000000001',true);
SELECT ok(NOT public.has_operations_staged_scope(
 'case_reviewer',current_setting('test.e6e_case')::uuid),
 'Applicant cannot review own application despite explicit test grant');
RESET ROLE;
UPDATE public.operations_approved_regions SET is_enabled=false
 WHERE region_code='PG-MPL';
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub',
 'b6400000-0000-4000-8000-000000000003',true);
SELECT is((SELECT count(*)::integer FROM public.staged_provider_applications),0,
 'Disabling approved region immediately revokes view access');
RESET ROLE;
UPDATE public.operations_approved_regions SET is_enabled=true
 WHERE region_code='PG-MPL';
SELECT public.map_operations_service_category(
 (SELECT category_id FROM public.staged_provider_applications
 WHERE id=current_setting('test.e6e_case')::uuid),'food',
 'b6400000-0000-4000-8000-000000000003',
 'Independent category remap invalidates previous staged classification');
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub',
 'b6400000-0000-4000-8000-000000000003',true);
SELECT is((SELECT count(*)::integer FROM public.staged_provider_applications),0,
 'Taxonomy changes invalidate stale case classification');
RESET ROLE;
SELECT public.classify_operations_staged_application(
 current_setting('test.e6e_case')::uuid,'PG-MPL',
 'b6400000-0000-4000-8000-000000000003',
 'Independent reclassification after trusted category correction');
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub',
 'b6400000-0000-4000-8000-000000000007',true);
SELECT is((SELECT count(*)::integer FROM public.staged_provider_applications),1,
 'New category reviewer obtains access only after re-certification');
RESET ROLE;
UPDATE public.operations_duty_grants SET
 revoked_at=clock_timestamp(),revoke_reason=
 'Synthetic duty revoked immediately for test negative case'
 WHERE staff_user_id='b6400000-0000-4000-8000-000000000007';
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub',
 'b6400000-0000-4000-8000-000000000007',true);
SELECT is((SELECT count(*)::integer FROM public.staged_provider_applications),0,
 'Staff revocation immediately denies staged access');
SELECT * FROM finish();
ROLLBACK;
