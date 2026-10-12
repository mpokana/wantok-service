-- E6O two known shared internal privileged helpers must be server-only.
-- Execute only in disconnected disposable staging; no personal or business rows.
BEGIN;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SELECT plan(14);

SELECT ok(NOT has_function_privilege('anon',
 'public.write_audit_event(text,text,uuid,jsonb,uuid)','EXECUTE'),
 'anonymous cannot call privileged audit event writer');
SELECT ok(NOT has_function_privilege('authenticated',
 'public.write_audit_event(text,text,uuid,jsonb,uuid)','EXECUTE'),
 'ordinary signed-in users cannot forge privileged audit rows');
SELECT ok(has_function_privilege('service_role',
 'public.write_audit_event(text,text,uuid,jsonb,uuid)','EXECUTE'),
 'trusted server worker retains audit helper');
SELECT ok(NOT has_function_privilege('anon',
 'public.enqueue_notification(uuid,text,text,text,jsonb,text,text,text)','EXECUTE'),
 'anonymous cannot enqueue arbitrary notifications');
SELECT ok(NOT has_function_privilege('authenticated',
 'public.enqueue_notification(uuid,text,text,text,jsonb,text,text,text)','EXECUTE'),
 'ordinary signed-in users cannot enqueue privileged notification payloads');
SELECT ok(has_function_privilege('service_role',
 'public.enqueue_notification(uuid,text,text,text,jsonb,text,text,text)','EXECUTE'),
 'trusted server worker retains notification helper');
SELECT ok((SELECT prosecdef FROM pg_proc
 WHERE oid='public.write_audit_event(text,text,uuid,jsonb,uuid)'::regprocedure),
 'audit helper still executes under its configured definer');
SELECT ok((SELECT prosecdef FROM pg_proc
 WHERE oid='public.enqueue_notification(uuid,text,text,text,jsonb,text,text,text)'::regprocedure),
 'notification helper still executes under its configured definer');
SELECT ok((SELECT proconfig IS NOT NULL FROM pg_proc
 WHERE oid='public.write_audit_event(text,text,uuid,jsonb,uuid)'::regprocedure),
 'audit helper retains explicit search_path');
SELECT ok((SELECT proconfig IS NOT NULL FROM pg_proc
 WHERE oid='public.enqueue_notification(uuid,text,text,text,jsonb,text,text,text)'::regprocedure),
 'notification helper retains explicit search_path');
SET LOCAL ROLE anon;
SELECT throws_ok(
 'SELECT public.write_audit_event(''SYNTHETIC_DENIED'',''test'',NULL,''{}''::jsonb,NULL)',
 '42501','permission denied for function write_audit_event',
 'anonymous direct SQL audit-event forgery is denied');
SELECT throws_ok(
 'SELECT public.enqueue_notification(NULL,''SYNTHETIC'',''synthetic'',''no actual notification'',''{}''::jsonb,''in_app'',''generic'',NULL)',
 '42501','permission denied for function enqueue_notification',
 'anonymous direct notification enqueue is denied');
RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT throws_ok(
 'SELECT public.write_audit_event(''SYNTHETIC_DENIED'',''test'',NULL,''{}''::jsonb,NULL)',
 '42501','permission denied for function write_audit_event',
 'authenticated direct SQL audit-event forgery is denied');
SELECT throws_ok(
 'SELECT public.enqueue_notification(NULL,''SYNTHETIC'',''synthetic'',''no actual notification'',''{}''::jsonb,''in_app'',''generic'',NULL)',
 '42501','permission denied for function enqueue_notification',
 'authenticated direct notification enqueue is denied');
RESET ROLE;
SELECT * FROM finish();
ROLLBACK;
