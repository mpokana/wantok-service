-- E6N Operations SECURITY DEFINER search_path hardening.
-- SOURCE ONLY until a dedicated backed-up parity stage is explicitly authorised.
-- This migration does not change function bodies, ownership or grants.
-- pg_temp placed explicitly LAST following PostgreSQL CREATE FUNCTION guidance.
-- Apply after 20261011233000 E6H so replaced source bodies inherit this path.
BEGIN;
ALTER FUNCTION public.admin_set_provider_service_status(uuid,text) SET search_path = public, auth, pg_temp;
ALTER FUNCTION public.configure_operations_provisioner(uuid,text,text,uuid,text,boolean) SET search_path = public, auth, pg_temp;
ALTER FUNCTION public.decide_operations_duty_change(uuid,boolean,text) SET search_path = public, auth, pg_temp;
ALTER FUNCTION public.emergency_revoke_vendor_clearance_trusted(uuid,uuid,text) SET search_path = public, auth, pg_temp;
ALTER FUNCTION public.has_operations_case_scope(text,uuid) SET search_path = public, auth, pg_temp;
ALTER FUNCTION public.has_operations_clearance_scope(text,uuid) SET search_path = public, auth, pg_temp;
ALTER FUNCTION public.has_operations_scope(text,text,text,text) SET search_path = public, auth, pg_temp;
ALTER FUNCTION public.has_operations_staged_scope(text,uuid) SET search_path = public, auth, pg_temp;
ALTER FUNCTION public.list_vendor_clearance_status() SET search_path = public, auth, pg_temp;
ALTER FUNCTION public.map_operations_service_category(uuid,text,uuid,text) SET search_path = public, auth, pg_temp;
ALTER FUNCTION public.pause_expired_vendor_clearances() SET search_path = public, auth, pg_temp;
ALTER FUNCTION public.record_operations_case_conflict_trusted(text,uuid,uuid,uuid,text) SET search_path = public, auth, pg_temp;
ALTER FUNCTION public.register_operations_case_jurisdiction(uuid,text,uuid,text) SET search_path = public, auth, pg_temp;
ALTER FUNCTION public.register_operations_region(text,text,uuid,text) SET search_path = public, auth, pg_temp;
ALTER FUNCTION public.request_operations_duty_change(text,uuid,text,text,text,text,timestamptz,uuid,text) SET search_path = public, auth, pg_temp;
ALTER FUNCTION public.review_provider_application(uuid,text) SET search_path = public, auth, pg_temp;
ALTER FUNCTION public.revoke_vendor_activation_clearance(uuid,text) SET search_path = public, auth, pg_temp;
ALTER FUNCTION public.submit_vendor_intake_case(text,text,text,text,text,text,text,text,text,text,text,text,text,text,jsonb) SET search_path = public, auth, pg_temp;
ALTER FUNCTION public.triage_vendor_intake_case(uuid,text,text) SET search_path = public, auth, pg_temp;
COMMIT;
