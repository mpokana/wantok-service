-- Phase 2C: applicant-owned preflight status, never an upload grant.
-- Privacy notice is still DRAFT. All returned paths must fail closed.
CREATE OR REPLACE FUNCTION public.vendor_evidence_preflight(p_request_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER
SET search_path=public,auth AS $$
DECLARE v_row public.vendor_evidence_requests%ROWTYPE;
BEGIN
 IF auth.uid() IS NULL THEN
   RAISE EXCEPTION 'Authentication required' USING errcode='42501';
 END IF;
 SELECT req.* INTO v_row
 FROM public.vendor_evidence_requests req
 JOIN public.vendor_intake_cases c ON c.id=req.case_id
 WHERE req.id=p_request_id AND c.applicant_id=auth.uid();
 IF NOT FOUND THEN
   RAISE EXCEPTION 'Evidence request unavailable' USING errcode='42501';
 END IF;
 -- No document identifiers, names, notes or storage URLs are returned.
 RETURN jsonb_build_object(
   'request_id',v_row.id,
   'status',v_row.status,
   'expires_at',v_row.expires_at,
   'notice_version',v_row.notice_version,
   'expired',v_row.expires_at<=clock_timestamp(),
   'upload_allowed',false,
   'reviewer_access_allowed',false,
   'identity_verified',false,
   'reason','secure_gateway_and_approved_notice_required'
 );
END $$;
REVOKE ALL ON FUNCTION public.vendor_evidence_preflight(uuid)
 FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.vendor_evidence_preflight(uuid)
 TO authenticated;
COMMENT ON FUNCTION public.vendor_evidence_preflight(uuid) IS
 'Authenticated applicant may inspect only own request status. Never a file upload/release/approval grant.';
