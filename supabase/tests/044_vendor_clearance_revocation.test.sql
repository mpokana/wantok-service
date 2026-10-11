BEGIN;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SELECT plan(11);
SELECT has_column('public','vendor_activation_clearances','revoked_at',
 'Revoked clearance timestamp recorded');
SELECT has_table('public','vendor_clearance_revocation_events',
 'Revocation has durable audit events');
SELECT has_function('public','revoke_vendor_activation_clearance',
 ARRAY['uuid','text'],'Emergency revoke function exists');
INSERT INTO auth.users(id,aud,role,email,created_at,updated_at) VALUES
('d7000000-0000-0000-0000-000000000001','authenticated','authenticated','clearance-test-provider@wantok.local',now(),now()),
('d7000000-0000-0000-0000-000000000002','authenticated','authenticated','clearance-test-officer@wantok.local',now(),now()),
('d7000000-0000-0000-0000-000000000003','authenticated','authenticated','clearance-test-reviewer@wantok.local',now(),now());
UPDATE public.profiles SET is_admin=true
 WHERE id='d7000000-0000-0000-0000-000000000002';
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','d7000000-0000-0000-0000-000000000001',true);
SELECT lives_ok($$SELECT public.submit_vendor_intake_case(
 'home-services','individual','Synthetic Clearance Provider','PG','Morobe','Lae',
 'Section 12 Lot 22','synthetic-provider@example.test','+67570112222',
 'national_id','1234',NULL,NULL,'Electrical and home improvement trades',
 '{"trade_speciality":"Electrical"}'::jsonb)$$,
 'Synthetic application can be staged for rollback-only revocation test');
RESET ROLE;
INSERT INTO public.provider_profiles
 (provider_id,display_name,is_active,verification_status)
 VALUES ('d7000000-0000-0000-0000-000000000001',
 'Synthetic Clearance Provider',true,'verified');
INSERT INTO public.vendor_activation_clearances
 (provider_id,identity_reviewer,approving_officer,clearance_type,
  evidence_case_id,expires_at)
 SELECT 'd7000000-0000-0000-0000-000000000001',
  'd7000000-0000-0000-0000-000000000002',
  'd7000000-0000-0000-0000-000000000003',
  'final_independent_review',id,now()+interval '20 days'
 FROM public.vendor_intake_cases
 WHERE applicant_id='d7000000-0000-0000-0000-000000000001';
INSERT INTO public.provider_services
 (provider_id,category_id,title,status)
 SELECT 'd7000000-0000-0000-0000-000000000001',
 category_id,'Synthetic Service','active'
 FROM public.vendor_intake_cases
 WHERE applicant_id='d7000000-0000-0000-0000-000000000001';
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','d7000000-0000-0000-0000-000000000002',true);
SELECT is(public.revoke_vendor_activation_clearance(
 'd7000000-0000-0000-0000-000000000001',
 'Mandatory safety investigation and emergency suspension'),1,
 'Revocation pauses the active service in one transaction');
SELECT is((SELECT status FROM public.provider_services
 WHERE provider_id='d7000000-0000-0000-0000-000000000001'),
 'paused','Revoked provider service is paused');
SELECT throws_ok($$SELECT public.admin_set_provider_service_status(
 (SELECT id FROM public.provider_services
 WHERE provider_id='d7000000-0000-0000-0000-000000000001'),'active')$$,
 '42501',
 'Unexpired, non-revoked independent clearance required before activation',
 'Revoked provider cannot reactivate the service');
SELECT throws_ok($$SELECT public.revoke_vendor_activation_clearance(
 'd7000000-0000-0000-0000-000000000001',
 'Second cancellation should not produce duplicate action')$$,
 '22023','No current clearance available for revocation',
 'Repeated revocation is rejected');
SELECT is((SELECT count(*)::integer FROM public.vendor_clearance_revocation_events
 WHERE provider_id='d7000000-0000-0000-0000-000000000001'),1,
 'Audit event recorded once');
SELECT ok(NOT has_table_privilege('authenticated',
 'public.vendor_activation_clearances','UPDATE'),
 'Ordinary accounts cannot rewrite clearance status');
SELECT ok(NOT has_function_privilege('authenticated',
 'public.pause_expired_vendor_clearances()','EXECUTE'),
 'Applicants and Operations cannot invoke server-only expiry maintenance');
SELECT * FROM finish();
ROLLBACK;
