BEGIN;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SELECT plan(6);
SELECT has_function('public','list_vendor_clearance_status',ARRAY[]::text[],
 'Authorised clearance status RPC exists');
INSERT INTO auth.users(id,aud,role,email,created_at,updated_at) VALUES
('d6000000-0000-0000-0000-000000000001','authenticated','authenticated',
 'clearance-status-user@wantok.local',now(),now()),
('d6000000-0000-0000-0000-000000000002','authenticated','authenticated',
 'clearance-status-admin@wantok.local',now(),now());
UPDATE public.profiles SET is_admin=true
 WHERE id='d6000000-0000-0000-0000-000000000002';
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub',
 'd6000000-0000-0000-0000-000000000001',true);
SELECT throws_ok($$SELECT public.list_vendor_clearance_status()$$,
 '42501','Scoped safety investigator required',
 'Ordinary user cannot list clearances');
SELECT set_config('request.jwt.claim.sub',
 'd6000000-0000-0000-0000-000000000002',true);
SELECT throws_ok($$SELECT public.list_vendor_clearance_status()$$,
 '42501','Scoped safety investigator required',
 'Old global-admin flag does not grant safety register access');
RESET ROLE;
INSERT INTO public.operations_duty_grants(
 staff_user_id,duty,country_code,region_code,category_scope,assignment_reason)
 VALUES('d6000000-0000-0000-0000-000000000002',
 'safety_investigator','PG',NULL,'trades',
 'Synthetic safety investigator duty for this rollback-only test');
SET LOCAL ROLE authenticated;
SELECT lives_ok($$SELECT * FROM public.list_vendor_clearance_status()$$,
 'Assigned safety officer can query scoped clearance health');
SELECT ok(NOT has_table_privilege('authenticated',
 'public.vendor_activation_clearances','SELECT'),
 'Raw clearance table remains closed to normal users');
SELECT ok(has_function_privilege('authenticated',
 'public.list_vendor_clearance_status()','EXECUTE'),
 'Only the guarded RPC is exposed to signed-in users');
SELECT * FROM finish();
ROLLBACK;
