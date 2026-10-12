-- E6P: anonymous direct SQL/RPC role and platform-control attempts must fail.
-- Disposable, network-disabled staging ONLY. The pgTAP test is rolled back.
BEGIN;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SELECT plan(23);
-- The nine selected routines are all SECURITY DEFINER. This is a subset only.
SELECT ok((SELECT prosecdef FROM pg_proc WHERE oid=
 'public.grant_user_role(uuid,text,timestamptz)'::regprocedure),
 'grant_user_role stays SECURITY DEFINER');
SELECT ok((SELECT prosecdef FROM pg_proc WHERE oid=
 'public.revoke_user_role(uuid,text)'::regprocedure),
 'revoke_user_role stays SECURITY DEFINER');
SELECT ok((SELECT prosecdef FROM pg_proc WHERE oid=
 'public.grant_technical_module_access(uuid,text,text,timestamptz,text)'::regprocedure),
 'technical module role grant stays SECURITY DEFINER');
SELECT ok((SELECT prosecdef FROM pg_proc WHERE oid=
 'public.manage_service_category(text,jsonb,uuid,timestamptz)'::regprocedure),
 'category editor stays SECURITY DEFINER');

SET LOCAL ROLE anon;
SELECT throws_ok(
 $$SELECT public.grant_user_role('00000000-0000-0000-0000-000000000001'::uuid,'tech_platform_admin',NULL)$$,
 'P0001','Authentication required','anonymous cannot grant platform admin');
SELECT throws_ok(
 $$SELECT public.revoke_user_role('00000000-0000-0000-0000-000000000001'::uuid,'tech_platform_admin')$$,
 'P0001','Authentication required','anonymous cannot revoke platform admin');
SELECT throws_ok(
 $$SELECT public.grant_technical_module_access('00000000-0000-0000-0000-000000000001'::uuid,'messaging','admin',NULL,NULL)$$,
 'P0001','Authentication required','anonymous cannot grant technical module access');
SELECT throws_ok(
 $$SELECT public.revoke_technical_module_access('00000000-0000-0000-0000-000000000001'::uuid,'messaging')$$,
 'P0001','Authentication required','anonymous cannot revoke technical module access');
SELECT throws_ok(
 $$SELECT public.set_technical_module_state('messaging',false,false)$$,
 'P0001','Authentication required','anonymous cannot change technical module state');
SELECT throws_ok(
 $$SELECT public.publish_wantok_branding_draft(1,1)$$,
 'P0001','Technical platform administrator required','anonymous cannot publish branding');
SELECT throws_ok(
 $$SELECT public.restore_wantok_branding_version(1,1)$$,
 'P0001','Technical platform administrator required','anonymous cannot restore branding');
SELECT throws_ok(
 $$SELECT public.admin_set_public_services_enabled(true)$$,
 'P0001','Admin access required','anonymous cannot expose public-services category');
SELECT throws_ok(
 $$SELECT public.manage_service_category('create','{}'::jsonb,NULL,NULL)$$,
 'P0001','Technical Platform Administrator required','anonymous cannot create service category');
RESET ROLE;
-- authenticated database role without any valid session identity is not
-- genuine GoTrue authentication; it must also fail closed in this synthetic QA.
SET LOCAL ROLE authenticated;
SELECT throws_ok(
 $$SELECT public.grant_user_role('00000000-0000-0000-0000-000000000001'::uuid,'tech_platform_admin',NULL)$$,
 'P0001','Authentication required',
 'authenticated DB role with no session identity cannot grant platform admin');
SELECT throws_ok(
 $$SELECT public.revoke_user_role('00000000-0000-0000-0000-000000000001'::uuid,'tech_platform_admin')$$,
 'P0001','Authentication required',
 'authenticated DB role with no session identity cannot revoke platform admin');
SELECT throws_ok(
 $$SELECT public.set_technical_module_state('messaging',false,false)$$,
 'P0001','Authentication required',
 'authenticated DB role with no session identity cannot change module state');
SELECT throws_ok(
 $$SELECT public.publish_wantok_branding_draft(1,1)$$,
 'P0001','Technical platform administrator required',
 'authenticated DB role with no session identity cannot publish branding');
SELECT throws_ok(
 $$SELECT public.manage_service_category('create','{}'::jsonb,NULL,NULL)$$,
 'P0001','Technical Platform Administrator required',
 'authenticated DB role with no session identity cannot create category');
RESET ROLE;
SELECT is((SELECT count(*)::integer FROM public.user_roles),0,
 'denied anonymous tests did not add a role');
SELECT is((SELECT count(*)::integer FROM public.technical_user_module_access),0,
 'denied anonymous tests did not add technical grants');
SELECT is((SELECT count(*)::integer FROM public.wantok_branding_history),0,
 'denied anonymous tests did not add branding versions');
SELECT is((SELECT count(*)::integer FROM public.audit_events),0,
 'denied anonymous tests did not add audit entries');
SELECT is((SELECT count(*)::integer FROM public.notification_outbox),0,
 'denied anonymous tests did not enqueue notifications');
SELECT * FROM finish();
ROLLBACK;
