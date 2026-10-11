-- Phase 2B-1: restricted evidence request metadata, NOT file intake.
-- No Storage INSERT/SELECT policies, document URLs or clearance grants.
CREATE TABLE public.vendor_evidence_requests (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 case_id uuid NOT NULL REFERENCES public.vendor_intake_cases(id) ON DELETE RESTRICT,
 check_id uuid NOT NULL REFERENCES public.vendor_verification_checks(id)
   ON DELETE RESTRICT,
 requested_by uuid NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
 requirement_note text NOT NULL CHECK(length(btrim(requirement_note)) BETWEEN 15 AND 500),
 notice_version text NOT NULL DEFAULT 'WANTOK-EVIDENCE-NOTICE-DRAFT-2026-10'
   CHECK(notice_version='WANTOK-EVIDENCE-NOTICE-DRAFT-2026-10'),
 status text NOT NULL DEFAULT 'requested'
   CHECK(status IN ('requested','acknowledged','withdrawn','cancelled')),
 requested_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 expires_at timestamptz NOT NULL DEFAULT (clock_timestamp()+interval '14 days'),
 last_action_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 CONSTRAINT evidence_request_expiry_check CHECK(expires_at>requested_at),
 CONSTRAINT evidence_request_notice_check CHECK(
   length(notice_version)>0)
);
CREATE INDEX vendor_evidence_case_idx
 ON public.vendor_evidence_requests(case_id,requested_at DESC);
CREATE UNIQUE INDEX vendor_evidence_active_check_idx
 ON public.vendor_evidence_requests(check_id)
 WHERE status IN ('requested','acknowledged');

CREATE TABLE public.vendor_evidence_request_events (
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 request_id uuid NOT NULL REFERENCES public.vendor_evidence_requests(id) ON DELETE RESTRICT,
 actor_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
 action text NOT NULL CHECK(action IN
 ('requested','acknowledged','withdrawn','cancelled')),
 from_status text,
 to_status text NOT NULL,
 rationale text CHECK(rationale IS NULL OR
   length(btrim(rationale)) BETWEEN 15 AND 500),
 occurred_at timestamptz NOT NULL DEFAULT clock_timestamp()
);
CREATE INDEX vendor_evidence_events_request_idx
 ON public.vendor_evidence_request_events(request_id,occurred_at DESC);
ALTER TABLE public.vendor_evidence_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vendor_evidence_request_events ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.vendor_evidence_requests FROM PUBLIC,anon,authenticated;
REVOKE ALL ON public.vendor_evidence_request_events FROM PUBLIC,anon,authenticated;
GRANT SELECT ON public.vendor_evidence_requests TO authenticated;
GRANT SELECT ON public.vendor_evidence_request_events TO authenticated;
CREATE POLICY evidence_requests_owner_or_operations
 ON public.vendor_evidence_requests FOR SELECT TO authenticated
 USING(public.is_admin(auth.uid()) OR EXISTS(
   SELECT 1 FROM public.vendor_intake_cases c
   WHERE c.id=case_id AND c.applicant_id=auth.uid()));
CREATE POLICY evidence_events_owner_or_operations
 ON public.vendor_evidence_request_events FOR SELECT TO authenticated
 USING(public.is_admin(auth.uid()) OR EXISTS(
   SELECT 1 FROM public.vendor_evidence_requests req
   JOIN public.vendor_intake_cases c ON c.id=req.case_id
   WHERE req.id=request_id AND c.applicant_id=auth.uid()));

CREATE OR REPLACE FUNCTION public.request_vendor_evidence(
 p_check_id uuid,p_note text
) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER
SET search_path=public,auth AS $$
DECLARE v_id uuid; v_case public.vendor_intake_cases%ROWTYPE;
BEGIN
 IF auth.uid() IS NULL OR NOT public.is_admin(auth.uid()) THEN
  RAISE EXCEPTION 'Operations reviewer required' USING errcode='42501';
 END IF;
 IF length(btrim(coalesce(p_note,''))) NOT BETWEEN 15 AND 500 THEN
  RAISE EXCEPTION 'Explanation must contain 15–500 characters'
   USING errcode='22023';
 END IF;
 SELECT c.* INTO v_case
 FROM public.vendor_verification_checks k
 JOIN public.vendor_intake_cases c ON c.id=k.case_id
 WHERE k.id=p_check_id FOR UPDATE OF c;
 IF NOT FOUND OR v_case.status<>'in_review' THEN
  RAISE EXCEPTION 'Case is not in review' USING errcode='22023';
 END IF;
 IF v_case.applicant_id=auth.uid() THEN
  RAISE EXCEPTION 'Applicants may not request their own evidence'
   USING errcode='42501';
 END IF;
 IF EXISTS(SELECT 1 FROM public.vendor_evidence_requests r
  WHERE r.check_id=p_check_id AND r.status IN ('requested','acknowledged')) THEN
  RAISE EXCEPTION 'An evidence request for this check is already open'
   USING errcode='23505';
 END IF;
 INSERT INTO public.vendor_evidence_requests
  (case_id,check_id,requested_by,requirement_note)
 VALUES(v_case.id,p_check_id,auth.uid(),btrim(p_note))
 RETURNING id INTO v_id;
 INSERT INTO public.vendor_evidence_request_events
  (request_id,actor_id,action,to_status,rationale)
 VALUES(v_id,auth.uid(),'requested','requested',btrim(p_note));
 RETURN v_id;
END $$;

CREATE OR REPLACE FUNCTION public.respond_vendor_evidence_request(
 p_request_id uuid,p_action text
) RETURNS public.vendor_evidence_requests
LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,auth AS $$
DECLARE v_req public.vendor_evidence_requests%ROWTYPE;
DECLARE v_previous text;
BEGIN
 IF auth.uid() IS NULL THEN
  RAISE EXCEPTION 'Sign in required' USING errcode='28000'; END IF;
 IF p_action NOT IN ('acknowledged','withdrawn') THEN
  RAISE EXCEPTION 'Invalid action' USING errcode='22023'; END IF;
 SELECT r.* INTO v_req FROM public.vendor_evidence_requests r
 JOIN public.vendor_intake_cases c ON c.id=r.case_id
 WHERE r.id=p_request_id AND c.applicant_id=auth.uid() FOR UPDATE OF r;
 IF NOT FOUND OR v_req.expires_at<=clock_timestamp()
  OR (p_action='acknowledged' AND v_req.status<>'requested')
  OR (p_action='withdrawn' AND v_req.status NOT IN
      ('requested','acknowledged')) THEN
  RAISE EXCEPTION 'Request is unavailable, expired or already closed'
   USING errcode='42501'; END IF;
 v_previous:=v_req.status;
 UPDATE public.vendor_evidence_requests
  SET status=p_action,last_action_at=clock_timestamp()
 WHERE id=p_request_id RETURNING * INTO v_req;
 INSERT INTO public.vendor_evidence_request_events
   (request_id,actor_id,action,from_status,to_status)
 VALUES(p_request_id,auth.uid(),p_action,v_previous,p_action);
 RETURN v_req;
END $$;

CREATE OR REPLACE FUNCTION public.cancel_vendor_evidence_request(
 p_request_id uuid,p_reason text
) RETURNS public.vendor_evidence_requests
LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,auth AS $$
DECLARE v_req public.vendor_evidence_requests%ROWTYPE;
DECLARE v_previous text;
BEGIN
 IF auth.uid() IS NULL OR NOT public.is_admin(auth.uid()) THEN
  RAISE EXCEPTION 'Operations reviewer required' USING errcode='42501';
 END IF;
 IF length(btrim(coalesce(p_reason,''))) NOT BETWEEN 15 AND 500 THEN
  RAISE EXCEPTION 'Reason must contain 15–500 characters'
    USING errcode='22023'; END IF;
 SELECT * INTO v_req FROM public.vendor_evidence_requests
 WHERE id=p_request_id FOR UPDATE;
 IF NOT FOUND OR v_req.status NOT IN ('requested','acknowledged') THEN
  RAISE EXCEPTION 'No cancellable request found' USING errcode='22023';
 END IF;
 v_previous:=v_req.status;
 UPDATE public.vendor_evidence_requests
  SET status='cancelled',last_action_at=clock_timestamp()
 WHERE id=p_request_id RETURNING * INTO v_req;
 INSERT INTO public.vendor_evidence_request_events
  (request_id,actor_id,action,from_status,to_status,rationale)
 VALUES(p_request_id,auth.uid(),'cancelled',v_previous,'cancelled',
   btrim(p_reason));
 RETURN v_req;
END $$;

REVOKE ALL ON FUNCTION public.request_vendor_evidence(uuid,text)
 FROM PUBLIC,anon;
REVOKE ALL ON FUNCTION public.respond_vendor_evidence_request(uuid,text)
 FROM PUBLIC,anon;
REVOKE ALL ON FUNCTION public.cancel_vendor_evidence_request(uuid,text)
 FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.request_vendor_evidence(uuid,text)
 TO authenticated;
GRANT EXECUTE ON FUNCTION public.respond_vendor_evidence_request(uuid,text)
 TO authenticated;
GRANT EXECUTE ON FUNCTION public.cancel_vendor_evidence_request(uuid,text)
 TO authenticated;
COMMENT ON TABLE public.vendor_evidence_requests IS
 'Request/acknowledgement metadata only. DRAFT notice, no legal consent, no URLs, no files, no proof of verification.';
