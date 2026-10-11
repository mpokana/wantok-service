BEGIN;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SELECT plan(34);
SELECT has_function('public','has_operations_clearance_scope',
 ARRAY['text','uuid'],'Clearance scope binds case to actual provider');
SELECT has_function('public','emergency_revoke_vendor_clearance_trusted',
 ARRAY['uuid','uuid','text'],'Server emergency stop exists');
SELECT ok(NOT has_function_privilege('authenticated',
 'public.emergency_revoke_vendor_clearance_trusted(uuid,uuid,text)','EXECUTE'),
 'Browser users cannot invoke trusted emergency stop');
SELECT ok(NOT has_function_privilege('anon',
 'public.emergency_revoke_vendor_clearance_trusted(uuid,uuid,text)','EXECUTE'),
 'Anonymous users cannot invoke trusted emergency stop');
SELECT ok(has_function_privilege('service_role',
 'public.emergency_revoke_vendor_clearance_trusted(uuid,uuid,text)','EXECUTE'),
 'Only service role is assigned emergency-stop execution');
SELECT ok(NOT has_table_privilege('authenticated',
 'public.vendor_activation_clearances','SELECT'),
 'Clearance table is not directly visible to browser');
SELECT ok(NOT has_table_privilege('authenticated',
 'public.vendor_clearance_revocation_events','INSERT'),
 'Investigator cannot fabricate an audit event');
SELECT ok(NOT has_function_privilege('authenticated',
 'public.pause_expired_vendor_clearances()','EXECUTE'),
 'Scheduled expiry hook stays trusted only');

INSERT INTO auth.users(id,aud,role,email,created_at,updated_at)
SELECT ('c6200000-0000-4000-8000-'||lpad(n::text,12,'0'))::uuid,
 'authenticated','authenticated','e6c-synthetic-'||n||'@wantok.local',
 now(),now() FROM generate_series(1,11) n;
UPDATE public.profiles SET is_admin=true
 WHERE id='c6200000-0000-4000-8000-000000000005';
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','c6200000-0000-4000-8000-000000000001',true);
SELECT lives_ok($$SELECT public.submit_vendor_intake_case(
 'home-services','individual','Synthetic PNG provider','PG','Morobe','Lae',
 'Lot 07 Delta Street','e6c-pg@example.test','+67570002020',
 'national_id','1234',NULL,NULL,'Electrical and plumbing servicing',
 '{"trade_speciality":"Electrical"}'::jsonb)$$,
 'PG synthetic vendor can submit metadata-only case');
SELECT set_config('request.jwt.claim.sub','c6200000-0000-4000-8000-000000000002',true);
SELECT lives_ok($$SELECT public.submit_vendor_intake_case(
 'home-services','individual','Synthetic AU provider','AU','New South Wales','Sydney',
 'Lot 08 Victoria Street','e6c-au@example.test','+61700020202',
 'passport','5678',NULL,NULL,'Building repair and plumbing service',
 '{"trade_speciality":"Plumbing"}'::jsonb)$$,
 'AU synthetic vendor can submit unrelated case');
RESET ROLE;
SELECT public.map_operations_service_category(
 (SELECT category_id FROM public.vendor_intake_cases
 WHERE applicant_id='c6200000-0000-4000-8000-000000000001'),'trades',
 'c6200000-0000-4000-8000-000000000003',
 'Synthetic verified service family for closed transaction only');
SELECT public.register_operations_region('PG-MPL','Morobe',
 'c6200000-0000-4000-8000-000000000003',
 'Independent registry mapping in rolled back test');
SELECT public.register_operations_region('AU-NSW','New South Wales',
 'c6200000-0000-4000-8000-000000000004',
 'Independent Australian registry in rolled back test');
SELECT public.register_operations_case_jurisdiction(
 (SELECT id FROM public.vendor_intake_cases
 WHERE applicant_id='c6200000-0000-4000-8000-000000000001'),
 'PG-MPL','c6200000-0000-4000-8000-000000000003',
 'Synthetic trusted PG provider and case link for safety suite');
SELECT public.register_operations_case_jurisdiction(
 (SELECT id FROM public.vendor_intake_cases
 WHERE applicant_id='c6200000-0000-4000-8000-000000000002'),
 'AU-NSW','c6200000-0000-4000-8000-000000000004',
 'Synthetic trusted AU provider and case link for safety suite');

INSERT INTO public.provider_profiles(provider_id,display_name,is_active,verification_status)
VALUES
 ('c6200000-0000-4000-8000-000000000001','Synthetic PNG provider',true,'verified'),
 ('c6200000-0000-4000-8000-000000000002','Synthetic AU provider',true,'verified'),
 ('c6200000-0000-4000-8000-000000000010','Synthetic mislinked provider',true,'verified');
INSERT INTO public.vendor_activation_clearances(
 provider_id,identity_reviewer,approving_officer,clearance_type,evidence_case_id,expires_at)
SELECT provider_id,'c6200000-0000-4000-8000-000000000006'::uuid,
 'c6200000-0000-4000-8000-000000000007'::uuid,
 'final_independent_review',
 (SELECT id FROM public.vendor_intake_cases WHERE applicant_id=
   CASE WHEN provider_id='c6200000-0000-4000-8000-000000000002'
    THEN 'c6200000-0000-4000-8000-000000000002'::uuid
    ELSE 'c6200000-0000-4000-8000-000000000001'::uuid END),
 now()+interval '30 days'
FROM (VALUES
 ('c6200000-0000-4000-8000-000000000001'::uuid),
 ('c6200000-0000-4000-8000-000000000002'::uuid),
 ('c6200000-0000-4000-8000-000000000010'::uuid)) t(provider_id);
INSERT INTO public.provider_services(provider_id,category_id,title,status)
SELECT p.provider_id,c.category_id,
 'Synthetic scope-only service '||p.provider_id::text,'active'
FROM public.vendor_activation_clearances p
JOIN public.vendor_intake_cases c ON c.id=p.evidence_case_id;
INSERT INTO public.operations_duty_grants
 (staff_user_id,duty,country_code,region_code,category_scope,assignment_reason,
 issued_at,expires_at,revoked_at,revoke_reason)
VALUES
 ('c6200000-0000-4000-8000-000000000003','safety_investigator',
 'PG','PG-MPL','trades','Synthetic authorised independent investigator only',
 clock_timestamp()-interval '1 day',NULL,NULL,NULL),
 ('c6200000-0000-4000-8000-000000000004','safety_investigator',
 'AU','AU-NSW','trades','Synthetic foreign country investigator only',
 clock_timestamp()-interval '1 day',NULL,NULL,NULL),
 ('c6200000-0000-4000-8000-000000000006','safety_investigator',
 'PG','PG-MPL','trades','Synthetic identity reviewer with conflict',
 clock_timestamp()-interval '1 day',NULL,NULL,NULL),
 ('c6200000-0000-4000-8000-000000000007','safety_investigator',
 'PG','PG-MPL','trades','Synthetic final approval conflict record',
 clock_timestamp()-interval '1 day',NULL,NULL,NULL),
 ('c6200000-0000-4000-8000-000000000008','safety_investigator',
 'PG','PG-MPL','trades','Synthetic expired regional safety officer',
 clock_timestamp()-interval '3 days',clock_timestamp()-interval '1 day',NULL,NULL),
 ('c6200000-0000-4000-8000-000000000009','safety_investigator',
 'PG','PG-MPL','food','Synthetic incorrect category safety officer',
 clock_timestamp()-interval '1 day',NULL,NULL,NULL),
 ('c6200000-0000-4000-8000-000000000011','safety_investigator',
 'PG','PG-MPL','trades','Synthetic revoked safety staff assignment',
 clock_timestamp()-interval '1 day',NULL,clock_timestamp(),
 'Synthetic revocation of case and emergency authority');

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','c6200000-0000-4000-8000-000000000005',true);
SELECT throws_ok($$SELECT public.list_vendor_clearance_status()$$,
 '42501','Scoped safety investigator required',
 'Global admin flag alone cannot list any clearances');
SELECT throws_ok($$SELECT public.revoke_vendor_activation_clearance(
 'c6200000-0000-4000-8000-000000000001',
 'Admin without duty must not revoke a clearance')$$,
 '42501','Scoped independent safety investigator required',
 'Global admin flag alone cannot revoke a clearance');
SELECT set_config('request.jwt.claim.sub','c6200000-0000-4000-8000-000000000003',true);
SELECT is((SELECT count(*)::integer FROM public.list_vendor_clearance_status()),
 1,'PNG investigator sees only correctly linked PNG clearance');
SELECT ok(public.has_operations_clearance_scope(
 'safety_investigator','c6200000-0000-4000-8000-000000000001'),
 'Verified case grants safety read for actual provider');
SELECT ok(NOT public.has_operations_clearance_scope(
 'safety_investigator','c6200000-0000-4000-8000-000000000010'),
 'Mismatched provider-to-case reference does not create safety access');
SELECT throws_ok($$SELECT public.revoke_vendor_activation_clearance(
 'c6200000-0000-4000-8000-000000000010',
 'Cannot revoke a falsely linked foreign provider case')$$,
 '42501','Scoped independent safety investigator required',
 'Bad case linkage cannot be used for scoped revocation');

SELECT set_config('request.jwt.claim.sub','c6200000-0000-4000-8000-000000000004',true);
SELECT is((SELECT count(*)::integer FROM public.list_vendor_clearance_status()),
 1,'AU investigator sees AU only');
SELECT ok(NOT public.has_operations_clearance_scope(
 'safety_investigator','c6200000-0000-4000-8000-000000000001'),
 'Foreign investigator cannot inspect PNG clearance');
SELECT throws_ok($$SELECT public.revoke_vendor_activation_clearance(
 'c6200000-0000-4000-8000-000000000001',
 'Foreign investigator cannot suspend this provider')$$,
 '42501','Scoped independent safety investigator required',
 'Foreign investigator cannot revoke PNG clearance');
SELECT set_config('request.jwt.claim.sub','c6200000-0000-4000-8000-000000000009',true);
SELECT is((SELECT count(*)::integer FROM public.list_vendor_clearance_status()),
 0,'Incorrect category grants no clearance');
SELECT set_config('request.jwt.claim.sub','c6200000-0000-4000-8000-000000000008',true);
SELECT throws_ok($$SELECT public.list_vendor_clearance_status()$$,
 '42501','Scoped safety investigator required','Expired safety duty does not list');
SELECT set_config('request.jwt.claim.sub','c6200000-0000-4000-8000-000000000011',true);
SELECT throws_ok($$SELECT public.list_vendor_clearance_status()$$,
 '42501','Scoped safety investigator required','Revoked safety duty does not list');
SELECT set_config('request.jwt.claim.sub','c6200000-0000-4000-8000-000000000006',true);
SELECT throws_ok($$SELECT public.revoke_vendor_activation_clearance(
 'c6200000-0000-4000-8000-000000000001',
 'Identity reviewer must not review their own clearance')$$,
 '42501','Scoped independent safety investigator required',
 'Identity reviewer conflict cannot revoke clearance');
SELECT set_config('request.jwt.claim.sub','c6200000-0000-4000-8000-000000000007',true);
SELECT throws_ok($$SELECT public.revoke_vendor_activation_clearance(
 'c6200000-0000-4000-8000-000000000001',
 'Original approval officer may not revoke own clearance')$$,
 '42501','Scoped independent safety investigator required',
 'Final approval officer conflict cannot revoke clearance');
SELECT set_config('request.jwt.claim.sub','c6200000-0000-4000-8000-000000000003',true);
SELECT is(public.revoke_vendor_activation_clearance(
 'c6200000-0000-4000-8000-000000000001',
 'Independently investigated urgent safety incident'),1,
 'Scoped independent investigator revokes and pauses services');
SELECT throws_ok($$SELECT public.revoke_vendor_activation_clearance(
 'c6200000-0000-4000-8000-000000000001',
 'Repeated investigation does not duplicate the record')$$,
 '22023','No current clearance available for revocation',
 'Second revocation cannot double-count the event');
SELECT is((SELECT count(*)::integer FROM public.vendor_clearance_revocation_events),
 1,'Assigned investigator sees one recorded audit event');
SELECT throws_ok($$SELECT public.admin_set_provider_service_status(
 NULL,'active')$$,
 '42501','New service activation disabled pending independent release',
 'No new active service transition while release gate remains closed');
SELECT throws_ok($$SELECT public.review_provider_application(NULL,'approved')$$,
 '42501','Legacy provider approval disabled pending scoped review',
 'Old global provider decision cannot approve applicant');
RESET ROLE;
SELECT is((SELECT status FROM public.provider_services
 WHERE provider_id='c6200000-0000-4000-8000-000000000001' LIMIT 1),
 'paused','Authorised stop changed the actual provider service');
SET LOCAL ROLE service_role;
SELECT is(public.emergency_revoke_vendor_clearance_trusted(
 'c6200000-0000-4000-8000-000000000010',
 'c6200000-0000-4000-8000-000000000003',
 'Confirmed urgent legacy provider safety incident requiring suspension'),1,
 'Server-only emergency stop protects an unclassified or mismatched provider');
RESET ROLE;
SELECT is((SELECT status FROM public.provider_services
 WHERE provider_id='c6200000-0000-4000-8000-000000000010' LIMIT 1),
 'paused','Trusted emergency stop pauses the historical provider');
SELECT is((SELECT count(*)::integer FROM public.vendor_clearance_revocation_events
 WHERE provider_id IN ('c6200000-0000-4000-8000-000000000001',
                       'c6200000-0000-4000-8000-000000000010')),2,
 'Scoped and trusted emergency stops each preserve exactly one audit');
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','c6200000-0000-4000-8000-000000000005',true);
SELECT is((SELECT count(*)::integer FROM public.vendor_clearance_revocation_events),
 0,'Global administrator cannot read foreign clearance audit');
SELECT * FROM finish();
ROLLBACK;
