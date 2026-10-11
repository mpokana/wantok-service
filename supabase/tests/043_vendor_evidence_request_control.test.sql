BEGIN;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SELECT plan(22);
SELECT has_table('public','vendor_evidence_requests','Private evidence requests');
SELECT has_table('public','vendor_evidence_request_events','Evidence audit events');
SELECT has_function('public','request_vendor_evidence',ARRAY['uuid','text'],'Staff request endpoint');
SELECT has_function('public','respond_vendor_evidence_request',ARRAY['uuid','text'],'Applicant response endpoint');
SELECT has_function('public','cancel_vendor_evidence_request',ARRAY['uuid','text'],'Staff cancel endpoint');
SELECT has_function('public','revoke_vendor_activation_clearance',ARRAY['uuid','text'],'Emergency revocation endpoint');
SELECT has_function('public','pause_expired_vendor_clearances',ARRAY[]::text[],'Server-only expiry maintenance');
INSERT INTO auth.users(id,aud,role,email,created_at,updated_at) VALUES
('d8000000-0000-0000-0000-000000000011','authenticated','authenticated','evidence-applicant@wantok.local',now(),now()),
('d8000000-0000-0000-0000-000000000012','authenticated','authenticated','evidence-reviewer@wantok.local',now(),now()),
('d8000000-0000-0000-0000-000000000013','authenticated','authenticated','evidence-stranger@wantok.local',now(),now());
UPDATE public.profiles SET is_admin=true
 WHERE id='d8000000-0000-0000-0000-000000000012';
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','d8000000-0000-0000-0000-000000000011',true);
SELECT lives_ok($$SELECT public.submit_vendor_intake_case(
'home-services','individual','Evidence plumbing applicant','PG','Morobe','Lae',
'Lot 04 Second Street','evidence-applicant@example.test','+67570000011',
'national_id','1234',NULL,NULL,'Pipe repair and installation works',
'{"trade_speciality":"Plumbing"}'::jsonb)$$,'Applicant creates case');
SELECT is((SELECT count(*)::integer FROM public.vendor_evidence_requests),0,
 'No unsolicited applicant-visible requirements');
SELECT throws_ok($$SELECT public.request_vendor_evidence(
(SELECT id FROM public.vendor_verification_checks WHERE requirement_key='identity_check'),
'Please show a valid identity document')$$,'42501','Scoped evidence officer required',
'Applicant cannot request evidence');
RESET ROLE;
SELECT public.map_operations_service_category(
 (SELECT category_id FROM public.vendor_intake_cases LIMIT 1),'trades',
 'd8000000-0000-0000-0000-000000000012'::uuid,
 'Synthetic category taxonomic review for offline regression only');
SELECT public.register_operations_region('PG-MPL','Morobe',
 'd8000000-0000-0000-0000-000000000012'::uuid,
 'Synthetic subdivision registry for local test only');
SELECT public.register_operations_case_jurisdiction(
 (SELECT id FROM public.vendor_intake_cases LIMIT 1),'PG-MPL',
 'd8000000-0000-0000-0000-000000000012'::uuid,
 'Synthetic case and province verification for offline test');
INSERT INTO public.operations_duty_grants(
 staff_user_id,duty,country_code,region_code,category_scope,assignment_reason)
VALUES
 ('d8000000-0000-0000-0000-000000000012','case_reviewer','PG','PG-MPL','trades',
 'Preliminary case review duty for synthetic test only'),
 ('d8000000-0000-0000-0000-000000000012','evidence_officer','PG','PG-MPL','trades',
 'Metadata evidence officer duty for synthetic test only');
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','d8000000-0000-0000-0000-000000000012',true);
SELECT lives_ok($$SELECT public.triage_vendor_intake_case(
 (SELECT id FROM public.vendor_intake_cases LIMIT 1),
 'start_review',NULL)$$,'Staff begins review');
SELECT lives_ok($$SELECT public.request_vendor_evidence(
(SELECT id FROM public.vendor_verification_checks WHERE requirement_key='identity_check'),
'Official ID document requested; do not send until the secure gateway opens')$$,
 'Staff records a metadata-only request');
SELECT is((SELECT count(*)::integer FROM public.vendor_evidence_requests),1,
 'Only one request created');
SELECT throws_ok($$SELECT public.request_vendor_evidence(
(SELECT id FROM public.vendor_verification_checks WHERE requirement_key='identity_check'),
'Attempt to open duplicate evidence request')$$,'23505',
'An evidence request for this check is already open','Duplicate active request rejected');
SELECT set_config('request.jwt.claim.sub','d8000000-0000-0000-0000-000000000011',true);
SELECT is((SELECT count(*)::integer FROM public.vendor_evidence_requests),1,
 'Applicant can view own request');
SELECT lives_ok($$SELECT public.respond_vendor_evidence_request(
 (SELECT id FROM public.vendor_evidence_requests LIMIT 1),'acknowledged')$$,
 'Acknowledgement recorded without document intake');
SELECT lives_ok($$SELECT public.respond_vendor_evidence_request(
 (SELECT id FROM public.vendor_evidence_requests LIMIT 1),'withdrawn')$$,
 'Applicant may withdraw');
SELECT is((SELECT status FROM public.vendor_evidence_requests LIMIT 1),
 'withdrawn','Withdrawn state recorded');
SELECT is((SELECT count(*)::integer FROM public.vendor_evidence_request_events),3,
 'Request, acknowledgement and withdrawal audited');
SELECT ok(NOT has_table_privilege('authenticated',
 'public.vendor_activation_clearances','SELECT'),
 'Ordinary accounts cannot inspect sensitive activation clearances');
SELECT ok(NOT has_table_privilege('authenticated','public.vendor_evidence_requests','INSERT'),
 'Applicants cannot directly insert evidence records');
SELECT set_config('request.jwt.claim.sub','d8000000-0000-0000-0000-000000000013',true);
SELECT is((SELECT count(*)::integer FROM public.vendor_evidence_requests),0,
 'Other users cannot read case requests');
SELECT * FROM finish();
ROLLBACK;
