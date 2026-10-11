BEGIN;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SELECT plan(13);
SELECT has_table('public','vendor_verification_checks','Restricted review tasks exist');
SELECT has_table('public','vendor_verification_check_events','Review audit events exist');
SELECT has_function('public','record_vendor_verification_review',
 ARRAY['uuid','text','text'],'Controlled review endpoint exists');
INSERT INTO auth.users(id,aud,role,email,created_at,updated_at) VALUES
('d9000000-0000-0000-0000-000000000001','authenticated','authenticated','case-applicant@wantok.local',now(),now()),
('d9000000-0000-0000-0000-000000000002','authenticated','authenticated','case-reviewer-one@wantok.local',now(),now()),
('d9000000-0000-0000-0000-000000000003','authenticated','authenticated','case-reviewer-two@wantok.local',now(),now());
UPDATE public.profiles SET is_admin=true WHERE id IN(
'd9000000-0000-0000-0000-000000000002',
'd9000000-0000-0000-0000-000000000003');
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','d9000000-0000-0000-0000-000000000001',true);
SELECT lives_ok($$SELECT public.submit_vendor_intake_case(
 'home-services','individual','Plumbing Review Test','PG','Morobe','Lae',
 'Section 03 Lot 07','test-review@example.com','+67570000000',
 'national_id','4321',NULL,NULL,'Plumbing and water pipe installation',
 '{"trade_speciality":"Plumbing"}'::jsonb)$$,'Applicant submits a case');
SELECT is((SELECT count(*)::integer FROM public.vendor_verification_checks),0,
 'Applicant cannot read internal verification tasks');
SELECT set_config('request.jwt.claim.sub','d9000000-0000-0000-0000-000000000002',true);
SELECT ok((SELECT count(*)>=4 FROM public.vendor_verification_checks),
 'Category and baseline checklist seeded');
SELECT lives_ok($$SELECT public.triage_vendor_intake_case(
 (SELECT id FROM public.vendor_intake_cases LIMIT 1),'start_review',NULL)$$,
 'Admin assigns case to first reviewer');
SELECT lives_ok($$SELECT public.record_vendor_verification_review(
 (SELECT id FROM public.vendor_verification_checks WHERE requirement_key='identity_check'),
 'start','Started metadata review and independent evidence planning')$$,
 'Assigned officer can start a review');
SELECT lives_ok($$SELECT public.record_vendor_verification_review(
 (SELECT id FROM public.vendor_verification_checks WHERE requirement_key='identity_check'),
 'record_first','First procedural check recorded; no original document received')$$,
 'Assigned officer can record preliminary first review');
SELECT throws_ok($$SELECT public.record_vendor_verification_review(
 (SELECT id FROM public.vendor_verification_checks WHERE requirement_key='identity_check'),
 'record_second','Attempt to self-authorise a second review is blocked')$$,
 '42501','An independent second reviewer is required',
 'The same officer cannot perform the second review');
SELECT set_config('request.jwt.claim.sub','d9000000-0000-0000-0000-000000000003',true);
SELECT lives_ok($$SELECT public.record_vendor_verification_review(
 (SELECT id FROM public.vendor_verification_checks WHERE requirement_key='identity_check'),
 'record_second','Different officer records second procedural review without certifying identity')$$,
 'Independent second officer can record review');
SELECT is((SELECT state FROM public.vendor_verification_checks
 WHERE requirement_key='identity_check'),'second_review_recorded',
 'Independent review does not create verified state');
SELECT is((SELECT count(*)::integer FROM public.vendor_verification_check_events),
 3,'All three review events audited');
SELECT * FROM finish();
ROLLBACK;
