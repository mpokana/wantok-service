-- E6O shared privileged internal RPC grant correction, SOURCE ONLY.
-- Current local catalog grants anon/authenticated EXECUTE to these helpers
-- despite their 20261005010000 migration's intended service-role-only access.
-- Narrow two shared infrastructure helpers; do NOT modify Technical Control
-- functions while T2.4 is paused. Test in disconnected staging before approval.
BEGIN;
REVOKE ALL ON FUNCTION public.write_audit_event(text,text,uuid,jsonb,uuid)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.write_audit_event(text,text,uuid,jsonb,uuid)
  TO service_role;
REVOKE ALL ON FUNCTION public.enqueue_notification(uuid,text,text,text,jsonb,text,text,text)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.enqueue_notification(uuid,text,text,text,jsonb,text,text,text)
  TO service_role;
COMMIT;
