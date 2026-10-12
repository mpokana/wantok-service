-- E6N: prove E6 privileged function paths are explicit and scoped.
-- Runs only after source-only hardening migration in disposable test DB.
BEGIN;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SELECT plan(25);

WITH expected(signature) AS (
 VALUES
 ('public.admin_set_provider_service_status(uuid,text)'),
 ('public.configure_operations_provisioner(uuid,text,text,uuid,text,boolean)'),
 ('public.decide_operations_duty_change(uuid,boolean,text)'),
 ('public.emergency_revoke_vendor_clearance_trusted(uuid,uuid,text)'),
 ('public.has_operations_case_scope(text,uuid)'),
 ('public.has_operations_clearance_scope(text,uuid)'),
 ('public.has_operations_scope(text,text,text,text)'),
 ('public.has_operations_staged_scope(text,uuid)'),
 ('public.list_vendor_clearance_status()'),
 ('public.map_operations_service_category(uuid,text,uuid,text)'),
 ('public.pause_expired_vendor_clearances()'),
 ('public.record_operations_case_conflict_trusted(text,uuid,uuid,uuid,text)'),
 ('public.register_operations_case_jurisdiction(uuid,text,uuid,text)'),
 ('public.register_operations_region(text,text,uuid,text)'),
 ('public.request_operations_duty_change(text,uuid,text,text,text,text,timestamptz,uuid,text)'),
 ('public.review_provider_application(uuid,text)'),
 ('public.revoke_vendor_activation_clearance(uuid,text)'),
 ('public.submit_vendor_intake_case(text,text,text,text,text,text,text,text,text,text,text,text,text,text,jsonb)'),
 ('public.triage_vendor_intake_case(uuid,text,text)')
)
SELECT is(
 (SELECT array_to_string(proconfig,';') FROM pg_proc WHERE oid=signature::regprocedure),
 'search_path=public, auth, pg_temp',
 signature||' has pg_temp explicitly LAST'
) FROM expected;

SELECT is((
 SELECT count(*)::integer FROM pg_proc p
 JOIN pg_namespace n ON n.oid=p.pronamespace
 WHERE n.nspname='public' AND p.prosecdef
 AND (p.proname ~ '^(has_operations_|configure_operations_|request_operations_|decide_operations_|register_operations_|map_operations_|record_operations_|triage_vendor_|submit_vendor_intake_|list_vendor_clearance_|revoke_vendor_activation_|emergency_revoke_vendor_|pause_expired_vendor_)'
 OR p.proname IN ('admin_set_provider_service_status','review_provider_application'))
),19,'Selected E6 function inventory has exactly 19 privileged routines');

SELECT ok(NOT has_function_privilege('anon',
 'public.decide_operations_duty_change(uuid,boolean,text)','EXECUTE'),
 'Hardening does not open duty approval to anonymous');
SELECT ok(NOT has_function_privilege('authenticated',
 'public.configure_operations_provisioner(uuid,text,text,uuid,text,boolean)','EXECUTE'),
 'Trusted bootstrap remains restricted');
SELECT ok(has_function_privilege('authenticated',
 'public.request_operations_duty_change(text,uuid,text,text,text,text,timestamptz,uuid,text)','EXECUTE'),
 'Authorised requester RPC retains browser execution grant');
SELECT ok(has_function_privilege('service_role',
 'public.configure_operations_provisioner(uuid,text,text,uuid,text,boolean)','EXECUTE'),
 'Server-only trusted bootstrap retains explicit service-role permission');

SET LOCAL ROLE authenticated;
SELECT is(public.has_operations_scope('case_reviewer','PG',NULL,'trades'),
 false, 'Unauthenticated session cannot claim staff privileges after hardening');
RESET ROLE;
SELECT * FROM finish();
ROLLBACK;
