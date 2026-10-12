-- E6U: Positive trusted-worker continuity after E6O least-privilege patch.
-- Network-disconnected disposable database ONLY. Every fixture rolls back.
BEGIN;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SELECT plan(7);
SELECT ok(has_function_privilege('service_role',
  'public.write_audit_event(text,text,uuid,jsonb,uuid)','EXECUTE'),
  'service_role retains intended trusted audit helper EXECUTE');
SELECT ok(NOT has_function_privilege('anon',
  'public.write_audit_event(text,text,uuid,jsonb,uuid)','EXECUTE'),
  'anonymous role is not granted audit-write execution');
SELECT ok(NOT has_function_privilege('authenticated',
  'public.write_audit_event(text,text,uuid,jsonb,uuid)','EXECUTE'),
  'ordinary authenticated role is not granted audit-write execution');
SELECT is((SELECT count(*)::integer FROM public.audit_events
  WHERE action='E6U_SYNTHETIC_TRUSTED_WORKER'),0,
  'precondition: no synthetic trusted-worker audit row');
SET LOCAL ROLE service_role;
SELECT lives_ok(
  'SELECT public.write_audit_event(''E6U_SYNTHETIC_TRUSTED_WORKER'',''e6u_fixture'',NULL,''{}''::jsonb,NULL)',
  'trusted service_role can successfully invoke audit helper after patch');
RESET ROLE;
SELECT is((SELECT count(*)::integer FROM public.audit_events
  WHERE action='E6U_SYNTHETIC_TRUSTED_WORKER'),1,
  'exactly one synthetic trusted audit record was created inside rollback transaction');
SELECT ok((SELECT actor_user_id IS NULL FROM public.audit_events
  WHERE action='E6U_SYNTHETIC_TRUSTED_WORKER' LIMIT 1),
  'trusted server writer still supports its existing explicit NULL actor contract');
SELECT * FROM finish();
ROLLBACK;
