-- E6T G8: rollback-only positive reproduction of pre-E6O audit helper.
-- Must run ONLY after isolated fixture grants, BEFORE E6O REVOKE migration.
-- Never apply to shared DB; does not imply actual HTTP or production exploit.
BEGIN;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SELECT plan(8);
SELECT is(
 (SELECT count(*)::integer FROM public.audit_events
  WHERE action='E6T_SYNTHETIC_PREPATCH_QA'),0,
 'disconnected test fixture has no prior synthetic audit record');
SELECT ok(has_function_privilege('anon',
 'public.write_audit_event(text,text,uuid,jsonb,uuid)','EXECUTE'),
 'anonymous SQL role has prepatch audit writer EXECUTE');
SELECT ok(has_function_privilege('authenticated',
 'public.write_audit_event(text,text,uuid,jsonb,uuid)','EXECUTE'),
 'ordinary authenticated SQL role has prepatch audit writer EXECUTE');
SELECT ok(has_function_privilege('anon',
 'public.enqueue_notification(uuid,text,text,text,jsonb,text,text,text)','EXECUTE'),
 'anonymous SQL role has prepatch notification EXECUTE');
SELECT ok(has_function_privilege('authenticated',
 'public.enqueue_notification(uuid,text,text,text,jsonb,text,text,text)','EXECUTE'),
 'ordinary authenticated SQL role has prepatch notification EXECUTE');
SET LOCAL ROLE anon;
SELECT lives_ok(
 'SELECT public.write_audit_event(''E6T_SYNTHETIC_PREPATCH_QA'',''e6t_fixture'',NULL,''{}''::jsonb,NULL)',
 'prepatch anonymous SQL role can invoke audit-writing function');
RESET ROLE;
SELECT is(
 (SELECT count(*)::integer FROM public.audit_events
  WHERE action='E6T_SYNTHETIC_PREPATCH_QA'),1,
 'prepatch anonymous SQL role caused exactly one synthetic privileged audit write');
SELECT ok(
 (SELECT actor_user_id IS NULL FROM public.audit_events
  WHERE action='E6T_SYNTHETIC_PREPATCH_QA' LIMIT 1),
 'prepatch synthetic privileged audit record does not require signed-in actor');
SELECT * FROM finish();
ROLLBACK;
