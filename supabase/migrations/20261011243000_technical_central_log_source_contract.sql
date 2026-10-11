-- T2.4E: source provenance/retention registry for future central logs.
-- NO collectors, network ingress, event table, credentials or active state.
-- An approved human change process is required before trusted-role registration.
CREATE TABLE public.technical_log_source_contracts (
 source_key text PRIMARY KEY
   CHECK (source_key ~ '^[a-z][a-z0-9_.-]{2,63}$'),
 module_key text NOT NULL REFERENCES public.technical_modules(module_key)
   ON DELETE RESTRICT,
 source_kind text NOT NULL CHECK
   (source_kind IN ('application','container','worker','gateway')),
 provenance_ticket text NOT NULL
   CHECK (provenance_ticket ~ '^SEC-[A-Z0-9-]{8,64}$'),
 retention_days integer NOT NULL CHECK (retention_days BETWEEN 1 AND 90),
 redaction_profile text NOT NULL DEFAULT 'strict_metadata_only'
   CHECK (redaction_profile = 'strict_metadata_only'),
 connection_state text NOT NULL DEFAULT 'not_connected'
   CHECK (connection_state = 'not_connected'),
 registered_at timestamptz NOT NULL DEFAULT statement_timestamp(),
 UNIQUE (module_key,source_key)
);
CREATE INDEX technical_log_source_contract_module_idx
 ON public.technical_log_source_contracts(module_key);

ALTER TABLE public.technical_log_source_contracts ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.technical_log_source_contracts
 FROM PUBLIC,anon,authenticated;
GRANT SELECT,INSERT,UPDATE,DELETE
 ON public.technical_log_source_contracts TO service_role;

COMMENT ON TABLE public.technical_log_source_contracts IS
 'Future log-source contracts only; trusted registration with external approval, never event ingestion, credentials, delivery, worker liveness or connectivity.';

-- Aggregate-only, server-authorised readiness. A record is never proof
-- a collector exists: an actual trusted ingestion/verification migration and
-- acceptance gate will be needed before connection_state can change.
CREATE FUNCTION public.get_technical_central_log_readiness(p_module_key text)
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $function$
DECLARE v_registered integer;
BEGIN
 IF auth.uid() IS NULL OR p_module_key IS NULL OR NOT (
   public.has_technical_permission(p_module_key,'module.view',auth.uid())
   AND public.has_technical_permission(p_module_key,'module.logs',auth.uid())
 ) THEN
   RAISE EXCEPTION 'Technical module central log permission required'
     USING errcode='42501';
 END IF;

 SELECT count(*)::integer INTO v_registered
   FROM public.technical_log_source_contracts
   WHERE module_key=p_module_key;
 RETURN jsonb_build_object(
   'module_key',p_module_key,
   'registered_source_contracts',v_registered,
   'connection_state','not_connected',
   'collector_verified',false,
   'central_logs_available',false,
   'source_health','unknown',
   'observed_at',statement_timestamp()
 );
END;
$function$;
REVOKE ALL ON FUNCTION public.get_technical_central_log_readiness(text)
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.get_technical_central_log_readiness(text)
 TO authenticated;
COMMENT ON FUNCTION public.get_technical_central_log_readiness(text) IS
 'Per-module read-only central log contract readiness. Does not claim any actual collector or event source is connected.';
