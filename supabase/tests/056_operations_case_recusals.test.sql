BEGIN;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SELECT plan(18);
SELECT has_table('public','operations_case_recusals',
 'Explicit case-related conflict register exists');
SELECT ok(NOT has_table_privilege('authenticated',
 'public.operations_case_recusals','INSERT'),
 'Officer cannot directly forge a conflict record');
SELECT ok(NOT has_table_privilege('authenticated',
 'public.operations_case_recusals','DELETE'),
 'Officer cannot delete a conflict after recusing');
SELECT ok(has_function_privilege('authenticated',
 'public.declare_operations_case_recusal(text,uuid,text)','EXECUTE'),
 'Authenticated scoped officer can declare conflict');
SELECT ok(NOT has_function_privilege('authenticated',
 'public.record_operations_case_conflict_trusted(text,uuid,uuid,uuid,text)','EXECUTE'),
 'Browser cannot recuse another employee using service-only control');

INSERT INTO auth.users(id,aud,role,email,created_at,updated_at)
SELECT ('b6600000-0000-4000-8000-'||lpad(n::text,12,'0'))::uuid,
 'authenticated','authenticated','e6f-staff-'||n||'@wantok.local',
 now(),now() FROM generate_series(1,4) n;
UPDATE public.profiles SET is_admin=true
 WHERE id='b6600000-0000-4000-8000-000000000004';
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub',
 'b6600000-0000-4000-8000-000000000001',true);
SELECT lives_ok($$SELECT public.submit_vendor_intake_case(
 'home-services','individual','Synthetic conflict vendor','PG','Morobe','Lae',
 'Lot 40 Sample Road','coi@example.test','+67570005555',
 'national_id','1234',NULL,NULL,'Licensed electrical repair work',
 '{"trade_speciality":"Electrical"}'::jsonb)$$,
 'Applicant submits normal metadata-only enterprise case');
SELECT lives_ok($$SELECT public.submit_staged_provider_application(
 'home-services','Synthetic staged conflict vendor','individual',
 'Morobe','Lae','Repair and maintenance metadata only')$$,
 'Applicant submits independent staged review case');
RESET ROLE;
SELECT set_config('test.e6f_enterprise',(
 SELECT id::text FROM public.vendor_intake_cases
 WHERE applicant_id='b6600000-0000-4000-8000-000000000001'),true);
SELECT set_config('test.e6f_staged',(
 SELECT id::text FROM public.staged_provider_applications
 WHERE user_id='b6600000-0000-4000-8000-000000000001'),true);
SELECT public.map_operations_service_category(
 (SELECT category_id FROM public.vendor_intake_cases
 WHERE id=current_setting('test.e6f_enterprise')::uuid),
 'trades','b6600000-0000-4000-8000-000000000004',
 'Independent synthetic category proof in rollback-only test');
SELECT public.register_operations_region('PG-MPL','Morobe',
 'b6600000-0000-4000-8000-000000000004',
 'Independently checked synthetic location for recusal test');
SELECT public.register_operations_case_jurisdiction(
 current_setting('test.e6f_enterprise')::uuid,'PG-MPL',
 'b6600000-0000-4000-8000-000000000004',
 'Synthetic enterprise case certified from fixture source');
SELECT public.classify_operations_staged_application(
 current_setting('test.e6f_staged')::uuid,'PG-MPL',
 'b6600000-0000-4000-8000-000000000004',
 'Synthetic staged case certified from fixture source');
INSERT INTO public.operations_duty_grants(
 staff_user_id,duty,country_code,region_code,category_scope,assignment_reason)
VALUES
 ('b6600000-0000-4000-8000-000000000002',
 'case_reviewer','PG','PG-MPL','trades',
 'Synthetic assigned first reviewer with declared relation risk'),
 ('b6600000-0000-4000-8000-000000000002',
 'safety_investigator','PG','PG-MPL','trades',
 'Synthetic conflict scenario for safety investigation grant'),
 ('b6600000-0000-4000-8000-000000000003',
 'case_reviewer','PG','PG-MPL','trades',
 'Independent second reviewer for synthetic jurisdiction');
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub',
 'b6600000-0000-4000-8000-000000000002',true);
SELECT ok(public.has_operations_case_scope('case_reviewer',
 current_setting('test.e6f_enterprise')::uuid),
 'Reviewer initially sees assigned enterprise case');
SELECT ok(public.has_operations_staged_scope('case_reviewer',
 current_setting('test.e6f_staged')::uuid),
 'Reviewer initially sees staged case');
SELECT lives_ok($$SELECT public.declare_operations_case_recusal(
 'enterprise',current_setting('test.e6f_enterprise')::uuid,
 'Previously undisclosed commercial relationship with applicant business')$$,
 'Reviewer may permanently declare an enterprise business conflict');
SELECT ok(NOT public.has_operations_case_scope('case_reviewer',
 current_setting('test.e6f_enterprise')::uuid),
 'Enterprise access is immediately denied after self-recusal');
SELECT ok(NOT public.has_operations_case_scope('safety_investigator',
 current_setting('test.e6f_enterprise')::uuid),
 'Conflicted reviewer cannot switch to safety duty to bypass recusal');
SELECT ok(public.has_operations_staged_scope('case_reviewer',
 current_setting('test.e6f_staged')::uuid),
 'Unrelated staged case scope remains valid until separately recused');
SELECT lives_ok($$SELECT public.declare_operations_case_recusal(
 'staged',current_setting('test.e6f_staged')::uuid,
 'A second potential financial interest was found in the staged case')$$,
 'Reviewer may separately disclose staged case conflict');
SELECT ok(NOT public.has_operations_staged_scope('case_reviewer',
 current_setting('test.e6f_staged')::uuid),
 'Staged reviewer loses assigned authority after recusal');

SELECT set_config('request.jwt.claim.sub',
 'b6600000-0000-4000-8000-000000000003',true);
SELECT ok(public.has_operations_case_scope('case_reviewer',
 current_setting('test.e6f_enterprise')::uuid),
 'Unconflicted independent reviewer remains eligible');
RESET ROLE;
SELECT public.record_operations_case_conflict_trusted(
 'staged',current_setting('test.e6f_staged')::uuid,
 'b6600000-0000-4000-8000-000000000003',
 'b6600000-0000-4000-8000-000000000004',
 'Trusted compliance investigation independently confirms a conflict');
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub',
 'b6600000-0000-4000-8000-000000000003',true);
SELECT ok(NOT public.has_operations_staged_scope('case_reviewer',
 current_setting('test.e6f_staged')::uuid),
 'Independently recorded staff conflict revokes staged access at once');
SELECT set_config('request.jwt.claim.sub',
 'b6600000-0000-4000-8000-000000000001',true);
SELECT ok(
 (SELECT count(*) FROM public.vendor_intake_cases
 WHERE id=current_setting('test.e6f_enterprise')::uuid)=1
 AND (SELECT count(*) FROM public.staged_provider_applications
 WHERE id=current_setting('test.e6f_staged')::uuid)=1,
 'Applicant retains own application reads despite staff recusals');
SELECT * FROM finish();
ROLLBACK;
