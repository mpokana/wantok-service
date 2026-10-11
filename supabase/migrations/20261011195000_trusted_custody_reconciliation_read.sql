-- Phase 2D laboratory: service_role-only read of CURRENT claim/manifest
-- metadata. No upload, key release, document read, clearance, mutation.
CREATE OR REPLACE FUNCTION public.read_staged_custody_reconciliation(
 p_claim_id uuid
) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER
 SET search_path=public,auth AS $$
DECLARE v_result jsonb;
BEGIN
 IF auth.role() IS DISTINCT FROM 'service_role' OR p_claim_id IS NULL THEN
   RAISE EXCEPTION 'Custody reconciliation unavailable' USING errcode='42501';
 END IF;
 SELECT jsonb_build_object(
  'claim_id',r.claim_id,
  'claim_state',i.state,
  'withdrawn_at',i.withdrawn_at,
  'snapshot', CASE WHEN m.claim_id IS NULL THEN NULL
   ELSE jsonb_build_object(
    'claim_id',m.claim_id,
    'intent_id',m.intent_id,
    'applicant_id',m.applicant_id,
    'application_id',m.application_id,
    'check_id',m.check_id,
    'plain_sha256',m.plain_sha256,
    'sealed_sha256',m.sealed_sha256,
    'plain_bytes',m.plain_bytes,
    'sealed_bytes',m.sealed_bytes,
    'mime',m.mime,
    'key_id',m.key_id,
    'state',m.state,
    'envelope_version',m.envelope_version
   )
  END
 ) INTO v_result
 FROM public.staged_evidence_intent_claim_receipts r
 JOIN public.staged_evidence_intake_intents i
   ON i.id=r.intent_id AND i.claim_id=r.claim_id
   AND i.applicant_id=r.applicant_id
   AND i.application_id=r.application_id AND i.check_id=r.check_id
 LEFT JOIN public.staged_evidence_custody_manifests m
   ON m.claim_id=r.claim_id AND m.intent_id=r.intent_id
   AND m.applicant_id=r.applicant_id
   AND m.application_id=r.application_id AND m.check_id=r.check_id
 WHERE r.claim_id=p_claim_id
   AND i.state IN ('claimed_for_quarantine','withdrawn');
 IF v_result IS NULL THEN
   RAISE EXCEPTION 'Custody reconciliation unavailable' USING errcode='42501';
 END IF;
 RETURN v_result;
END $$;
REVOKE ALL ON FUNCTION public.read_staged_custody_reconciliation(uuid)
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.read_staged_custody_reconciliation(uuid)
 TO service_role;
COMMENT ON FUNCTION public.read_staged_custody_reconciliation(uuid) IS
 'Laboratory read-only current metadata snapshot restricted to service_role. Neither source document nor verified custody; never an approval or release.';
