-- Phase 2B-1: explicit clearance revocation and fail-closed activation guard.
-- No new clearance is issued by this migration.
ALTER TABLE public.vendor_activation_clearances
 ADD COLUMN revoked_at timestamptz,
 ADD COLUMN revoked_by uuid REFERENCES auth.users(id) ON DELETE RESTRICT,
 ADD COLUMN revocation_reason text,
 ADD CONSTRAINT clearance_revocation_consistency CHECK (
 (revoked_at IS NULL AND revoked_by IS NULL AND revocation_reason IS NULL)
 OR (revoked_at IS NOT NULL AND revoked_by IS NOT NULL AND
     length(btrim(revocation_reason)) BETWEEN 15 AND 1000));

CREATE TABLE public.vendor_clearance_revocation_events (
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 provider_id uuid NOT NULL REFERENCES public.provider_profiles(provider_id)
   ON DELETE RESTRICT,
 actor_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
 reason text NOT NULL CHECK(length(btrim(reason)) BETWEEN 15 AND 1000),
 paused_service_count integer NOT NULL CHECK(paused_service_count>=0),
 revoked_at timestamptz NOT NULL DEFAULT clock_timestamp()
);
ALTER TABLE public.vendor_clearance_revocation_events ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.vendor_clearance_revocation_events
 FROM PUBLIC,anon,authenticated;
GRANT SELECT ON public.vendor_clearance_revocation_events TO authenticated;
CREATE POLICY vendor_clearance_revocation_audit_admin
 ON public.vendor_clearance_revocation_events FOR SELECT TO authenticated
 USING(public.is_admin(auth.uid()));

CREATE OR REPLACE FUNCTION public.revoke_vendor_activation_clearance(
 p_provider_id uuid,p_reason text
) RETURNS integer LANGUAGE plpgsql SECURITY DEFINER
 SET search_path=public,auth AS $$
DECLARE v_count integer;
BEGIN
 IF auth.uid() IS NULL OR NOT public.is_admin(auth.uid()) THEN
  RAISE EXCEPTION 'Operations administrator required' USING errcode='42501';
 END IF;
 IF length(btrim(coalesce(p_reason,''))) NOT BETWEEN 15 AND 1000 THEN
  RAISE EXCEPTION 'Revocation reason must be 15–1000 characters'
   USING errcode='22023';
 END IF;
 UPDATE public.vendor_activation_clearances
 SET revoked_at=clock_timestamp(),revoked_by=auth.uid(),
     revocation_reason=btrim(p_reason)
 WHERE provider_id=p_provider_id AND revoked_at IS NULL;
 IF NOT FOUND THEN
  RAISE EXCEPTION 'No current clearance available for revocation'
   USING errcode='22023';
 END IF;
 UPDATE public.provider_services SET status='paused'
 WHERE provider_id=p_provider_id AND status='active';
 GET DIAGNOSTICS v_count=ROW_COUNT;
 INSERT INTO public.vendor_clearance_revocation_events
 (provider_id,actor_id,reason,paused_service_count)
 VALUES(p_provider_id,auth.uid(),btrim(p_reason),v_count);
 RETURN v_count;
END $$;
REVOKE ALL ON FUNCTION public.revoke_vendor_activation_clearance(uuid,text)
 FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.revoke_vendor_activation_clearance(uuid,text)
 TO authenticated;

-- Safe-status maintenance hook for a scheduled, trusted server process.
-- Service-role only: not a user, browser, or Operations RPC.
CREATE OR REPLACE FUNCTION public.pause_expired_vendor_clearances()
RETURNS integer LANGUAGE plpgsql SECURITY DEFINER
 SET search_path=public,auth AS $$
DECLARE v_count integer;
BEGIN
 UPDATE public.provider_services s SET status='paused'
 FROM public.vendor_activation_clearances c
 WHERE c.provider_id=s.provider_id
   AND s.status='active'
   AND (c.expires_at<=clock_timestamp() OR c.revoked_at IS NOT NULL);
 GET DIAGNOSTICS v_count=ROW_COUNT;
 RETURN v_count;
END $$;
REVOKE ALL ON FUNCTION public.pause_expired_vendor_clearances()
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.pause_expired_vendor_clearances()
 TO service_role;

CREATE OR REPLACE FUNCTION public.admin_set_provider_service_status(
 p_service_id uuid,p_status text
) RETURNS public.provider_services
LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,auth AS $$
DECLARE v_service public.provider_services%ROWTYPE;
BEGIN
 IF auth.uid() IS NULL OR NOT public.is_admin(auth.uid()) THEN
  RAISE EXCEPTION 'Operations reviewer required' USING errcode='42501'; END IF;
 IF p_status NOT IN ('draft','pending_review','active','paused','rejected') THEN
  RAISE EXCEPTION 'Invalid status' USING errcode='22023'; END IF;
 SELECT * INTO v_service FROM public.provider_services
   WHERE id=p_service_id FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Service not found'
  USING errcode='22023'; END IF;
 IF p_status='active' AND NOT EXISTS (
   SELECT 1 FROM public.vendor_activation_clearances clearance
   JOIN public.provider_profiles p ON p.provider_id=clearance.provider_id
   WHERE clearance.provider_id=v_service.provider_id
     AND clearance.revoked_at IS NULL
     AND clearance.expires_at>clock_timestamp()
     AND p.is_active AND p.verification_status='verified'
 ) THEN RAISE EXCEPTION
    'Unexpired, non-revoked independent clearance required before activation'
    USING errcode='42501'; END IF;
 UPDATE public.provider_services SET status=p_status
 WHERE id=p_service_id RETURNING * INTO v_service;
 RETURN v_service;
END $$;
REVOKE ALL ON FUNCTION public.admin_set_provider_service_status(uuid,text)
 FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.admin_set_provider_service_status(uuid,text)
 TO authenticated;
COMMENT ON FUNCTION public.revoke_vendor_activation_clearance(uuid,text) IS
 'Emergency stop: authorised Operations revokes an existing clearance and pauses the provider active services in one database transaction.';
