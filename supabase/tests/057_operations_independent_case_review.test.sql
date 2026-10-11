BEGIN;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SELECT plan(19);

INSERT INTO auth.users(id,aud,role,email,created_at,updated_at)
SELECT ('e6700000-0000-4000-8000-'||lpad(n::text,12,'0'))::uuid,
 'authenticated','authenticated','e6h-'||n||'@wantok.local',
 now(),now() FROM generate_series(1,6) n;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub',
 'e6700000-0000-4000-8000-000000000001',true);
SELECT lives_ok($$SELECT public.submit_vendor_intake_case(
 'home-services','individual','Synthetic self-review vendor',
 'PG','Morobe','Lae','Parcel 11 Example Street',
 'e6h@example.test','+67570004444','national_id',
 '1234',NULL,NULL,'Synthetic licensed electrical trade services',
 '{"trade_speciality":"Electrical"}'::jsonb)$$,
 'Applicant creates metadata-only case for rollback-only test');
RESET ROLE;
SELECT set_config('test.e6h_case',(
 SELECT id::text FROM public.vendor_intake_cases
 WHERE applicant_id='e6700000-0000-4000-8000-000000000001'),true);
SELECT public.map_operations_service_category(
 (SELECT category_id FROM public.vendor_intake_cases
 WHERE id=current_setting('test.e6h_case')::uuid),
 'trades','e6700000-0000-4000-8000-000000000006',
 'Synthetic independent local service family classification');
SELECT public.register_operations_region('PG-MPL','Morobe',
 'e6700000-0000-4000-8000-000000000006',
 'Synthetic independent province certification in rollback');
SELECT public.register_operations_case_jurisdiction(
 current_setting('test.e6h_case')::uuid,'PG-MPL',
 'e6700000-0000-4000-8000-000000000006',
 'Synthetic legal source fixture only for isolated unit test');

INSERT INTO public.provider_profiles(
 provider_id,display_name,is_active,verification_status)
VALUES('e6700000-0000-4000-8000-000000000001',
 'Synthetic E6H applicant',true,'verified');
INSERT INTO public.vendor_activation_clearances(
 provider_id,identity_reviewer,approving_officer,clearance_type,
 evidence_case_id,expires_at)
VALUES('e6700000-0000-4000-8000-000000000001',
 'e6700000-0000-4000-8000-000000000003',
 'e6700000-0000-4000-8000-000000000004',
 'final_independent_review',current_setting('test.e6h_case')::uuid,
 now()+interval '30 days');

INSERT INTO public.operations_duty_grants(
 staff_user_id,duty,country_code,region_code,category_scope,assignment_reason)
SELECT staff,'case_reviewer','PG','PG-MPL','trades',
 'Synthetic assigned duty, never real workforce privilege'
FROM (VALUES
 ('e6700000-0000-4000-8000-000000000001'::uuid),
 ('e6700000-0000-4000-8000-000000000002'::uuid)) t(staff);
INSERT INTO public.operations_duty_grants(
 staff_user_id,duty,country_code,region_code,category_scope,assignment_reason)
SELECT staff,'safety_investigator','PG','PG-MPL','trades',
 'Synthetic investigative duty including prior reviewers and applicant'
FROM (VALUES
 ('e6700000-0000-4000-8000-000000000001'::uuid),
 ('e6700000-0000-4000-8000-000000000003'::uuid),
 ('e6700000-0000-4000-8000-000000000004'::uuid),
 ('e6700000-0000-4000-8000-000000000005'::uuid)) t(staff);

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub',
 'e6700000-0000-4000-8000-000000000001',true);
SELECT ok(public.has_operations_scope(
 'case_reviewer','PG','PG-MPL','trades'),
 'Applicant has synthetically granted general staff duty');
SELECT ok(NOT public.has_operations_case_scope(
 'case_reviewer',current_setting('test.e6h_case')::uuid),
 'Enterprise applicant is denied reviewer duty on own case');
SELECT ok(NOT public.has_operations_case_scope(
 'safety_investigator',current_setting('test.e6h_case')::uuid),
 'Enterprise applicant is denied safety duty on own case');
SELECT ok(NOT public.has_operations_clearance_scope(
 'safety_investigator','e6700000-0000-4000-8000-000000000001'),
 'Provider cannot inspect own clearance through investigator role');
SELECT throws_ok($$SELECT public.revoke_vendor_activation_clearance(
 'e6700000-0000-4000-8000-000000000001',
 'Own clearance cannot be revoked by applicant with staff role')$$,
 '42501','Scoped independent safety investigator required',
 'Self-applicant cannot execute investigator emergency action');
SELECT is((SELECT count(*)::integer
 FROM public.vendor_intake_cases
 WHERE id=current_setting('test.e6h_case')::uuid),1,
 'Applicant retains normal owner case read after reviewer denial');

SELECT set_config('request.jwt.claim.sub',
 'e6700000-0000-4000-8000-000000000002',true);
SELECT ok(public.has_operations_case_scope(
 'case_reviewer',current_setting('test.e6h_case')::uuid),
 'Unrelated independent reviewer retains original enterprise duty');

SELECT set_config('request.jwt.claim.sub',
 'e6700000-0000-4000-8000-000000000003',true);
SELECT ok(public.has_operations_case_scope(
 'safety_investigator',current_setting('test.e6h_case')::uuid),
 'Prior identity reviewer can be case-scoped for unrelated duties');
SELECT ok(NOT public.has_operations_clearance_scope(
 'safety_investigator','e6700000-0000-4000-8000-000000000001'),
 'Prior identity reviewer cannot inspect same clearance');
SELECT is((SELECT count(*)::integer FROM public.list_vendor_clearance_status()),
 0,'Prior identity reviewer cannot list affected clearance');
SELECT throws_ok($$SELECT public.admin_set_provider_service_status(
 NULL,'paused')$$,
 '42501','Scoped safety pause required',
 'Identity reviewer cannot use clearance to pause provider service');

SELECT set_config('request.jwt.claim.sub',
 'e6700000-0000-4000-8000-000000000004',true);
SELECT ok(NOT public.has_operations_clearance_scope(
 'safety_investigator','e6700000-0000-4000-8000-000000000001'),
 'Former approving officer cannot inspect own approved clearance');
SELECT is((SELECT count(*)::integer FROM public.list_vendor_clearance_status()),
 0,'Former approving officer sees no clearance listing');

SELECT set_config('request.jwt.claim.sub',
 'e6700000-0000-4000-8000-000000000005',true);
SELECT ok(public.has_operations_clearance_scope(
 'safety_investigator','e6700000-0000-4000-8000-000000000001'),
 'Unconflicted independent safety investigator retains clearance scope');
SELECT is((SELECT count(*)::integer FROM public.list_vendor_clearance_status()),
 1,'Unconflicted investigator still sees one verified clearance');

RESET ROLE;
SELECT ok(NOT has_function_privilege('anon',
 'public.has_operations_clearance_scope(text,uuid)','EXECUTE'),
 'Anonymous callers cannot execute clearance scope helper');
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub',
 'e6700000-0000-4000-8000-000000000002',true);
SELECT ok(NOT public.has_operations_clearance_scope(
 'case_reviewer','e6700000-0000-4000-8000-000000000001'),
 'Case-review duty alone never grants safety clearance access');
SELECT ok(NOT public.has_operations_case_scope(
 'final_approver',current_setting('test.e6h_case')::uuid),
 'Unsupported enterprise final approval duty stays closed');
SELECT * FROM finish();
ROLLBACK;
