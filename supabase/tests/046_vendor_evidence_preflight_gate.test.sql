BEGIN;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SELECT plan(11);
SELECT has_function('public','vendor_evidence_preflight',
 ARRAY['uuid'],'Applicant-scoped preflight exists');
INSERT INTO auth.users(id,aud,role,email,created_at,updated_at) VALUES
('ee000000-0000-4000-8000-000000000001','authenticated','authenticated',
 'preflight-applicant@wantok.local',now(),now()),
('ee000000-0000-4000-8000-000000000002','authenticated','authenticated',
 'preflight-staff@wantok.local',now(),now()),
('ee000000-0000-4000-8000-000000000003','authenticated','authenticated',
 'preflight-stranger@wantok.local',now(),now());
UPDATE public.profiles SET is_admin=true
 WHERE id='ee000000-0000-4000-8000-000000000002';
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','ee000000-0000-4000-8000-000000000001',true);
SELECT lives_ok($$SELECT public.submit_vendor_intake_case(
 'home-services','individual','Preflight Plumbing','PG','Morobe','Lae',
 'Second Street Building 10','preflight@example.test','+67570000111',
 'national_id','1234',NULL,NULL,'Residential building plumbing service',
 '{"trade_speciality":"Plumbing"}'::jsonb)$$,'Applicant submitted a case');
RESET ROLE;
SELECT public.map_operations_service_category(
 (SELECT category_id FROM public.vendor_intake_cases LIMIT 1),'trades',
 'ee000000-0000-4000-8000-000000000002'::uuid,
 'Synthetic category taxonomic review for offline regression only');
SELECT public.register_operations_region('PG-MPL','Morobe',
 'ee000000-0000-4000-8000-000000000002'::uuid,
 'Synthetic subdivision registry for local test only');
SELECT public.register_operations_case_jurisdiction(
 (SELECT id FROM public.vendor_intake_cases LIMIT 1),'PG-MPL',
 'ee000000-0000-4000-8000-000000000002'::uuid,
 'Synthetic case and province verification for offline test');
INSERT INTO public.operations_duty_grants(
 staff_user_id,duty,country_code,region_code,category_scope,assignment_reason)
VALUES
 ('ee000000-0000-4000-8000-000000000002','case_reviewer','PG','PG-MPL','trades',
 'Preliminary case review duty for synthetic test only'),
 ('ee000000-0000-4000-8000-000000000002','evidence_officer','PG','PG-MPL','trades',
 'Metadata evidence officer duty for synthetic test only');
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','ee000000-0000-4000-8000-000000000002',true);
SELECT lives_ok($$SELECT public.triage_vendor_intake_case(
 (SELECT id FROM public.vendor_intake_cases LIMIT 1),'start_review',NULL)$$,
 'Reviewer starts the case');
SELECT lives_ok($$SELECT public.request_vendor_evidence(
 (SELECT id FROM public.vendor_verification_checks WHERE requirement_key='identity_check'),
 'Provide identity evidence only when secure upload is available')$$,
 'Reviewer records an evidence requirement');
SELECT set_config('request.jwt.claim.sub','ee000000-0000-4000-8000-000000000001',true);
SELECT is((SELECT public.vendor_evidence_preflight(id)->>'status'
 FROM public.vendor_evidence_requests LIMIT 1),
 'requested','Applicant reads only request state');
SELECT is((SELECT public.vendor_evidence_preflight(id)->>'reason'
 FROM public.vendor_evidence_requests LIMIT 1),
 'secure_gateway_and_approved_notice_required',
 'Missing security and approved notice are explicit blockers');
SELECT ok((SELECT public.vendor_evidence_preflight(id)->'upload_allowed'='false'::jsonb
 FROM public.vendor_evidence_requests LIMIT 1),
 'No pending request authorises upload');
SELECT ok((SELECT public.vendor_evidence_preflight(id)->'identity_verified'='false'::jsonb
 FROM public.vendor_evidence_requests LIMIT 1),
 'No verification can be inferred');
SELECT is((SELECT (public.vendor_evidence_preflight(id)->>'request_id')::text=id::text
 FROM public.vendor_evidence_requests LIMIT 1),
 true,'Response binds to correct request ID');
SELECT set_config('request.jwt.claim.sub','ee000000-0000-4000-8000-000000000003',true);
SELECT throws_ok($$SELECT public.vendor_evidence_preflight(
 (SELECT id FROM public.vendor_evidence_requests LIMIT 1))$$,
 '42501','Evidence request unavailable','Foreign user cannot preflight');
SELECT ok(NOT has_function_privilege('anon',
 'public.vendor_evidence_preflight(uuid)','EXECUTE'),
 'Anonymous preflight execution is blocked');
SELECT * FROM finish();
ROLLBACK;
