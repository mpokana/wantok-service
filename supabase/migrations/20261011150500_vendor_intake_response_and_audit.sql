-- Traceable applicant follow-up; no attachments, no full identity numbers.
ALTER TABLE public.vendor_intake_events
 DROP CONSTRAINT vendor_intake_events_event_type_check;
ALTER TABLE public.vendor_intake_events ADD CONSTRAINT
 vendor_intake_events_event_type_check CHECK(event_type IN
 ('submitted','review_started','information_requested','applicant_replied','declined'));

CREATE OR REPLACE FUNCTION public.triage_vendor_intake_case(
 p_case_id uuid,p_action text,p_reason text DEFAULT NULL
) RETURNS public.vendor_intake_cases
LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,auth AS $$
DECLARE v_case public.vendor_intake_cases%ROWTYPE;
DECLARE v_prior text;v_next text;v_event text;
BEGIN
 IF auth.uid() IS NULL OR NOT public.is_admin(auth.uid()) THEN
   RAISE EXCEPTION 'Operations reviewer required' USING errcode='42501'; END IF;
 SELECT * INTO v_case FROM public.vendor_intake_cases
   WHERE id=p_case_id FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Application not found'; END IF;
 v_prior:=v_case.status;
 IF p_action='start_review' AND v_prior='submitted' THEN
   v_next:='in_review';v_event:='review_started';
 ELSIF p_action='request_information' AND v_prior IN ('submitted','in_review')
   AND length(btrim(coalesce(p_reason,''))) BETWEEN 10 AND 1000 THEN
   v_next:='needs_information';v_event:='information_requested';
 ELSIF p_action='decline' AND v_prior IN
   ('submitted','in_review','needs_information')
   AND length(btrim(coalesce(p_reason,''))) BETWEEN 10 AND 1000 THEN
   v_next:='declined';v_event:='declined';
 ELSE RAISE EXCEPTION 'Invalid application state or missing explanation'
   USING errcode='22023'; END IF;
 UPDATE public.vendor_intake_cases SET status=v_next,
   assigned_reviewer=coalesce(assigned_reviewer,auth.uid()),
   reviewed_at=now(),updated_at=now()
 WHERE id=p_case_id RETURNING * INTO v_case;
 INSERT INTO public.vendor_intake_events(
   case_id,actor_id,event_type,previous_status,next_status,reason)
 VALUES(p_case_id,auth.uid(),v_event,v_prior,v_next,
   nullif(btrim(coalesce(p_reason,'')),''));
 RETURN v_case;
END $$;

CREATE OR REPLACE FUNCTION public.respond_vendor_intake_case(
 p_case_id uuid,p_response text
) RETURNS public.vendor_intake_cases
LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,auth AS $$
DECLARE v_case public.vendor_intake_cases%ROWTYPE;
BEGIN
 IF auth.uid() IS NULL THEN
   RAISE EXCEPTION 'Sign in required' USING errcode='28000'; END IF;
 IF length(btrim(coalesce(p_response,''))) NOT BETWEEN 10 AND 1000 THEN
   RAISE EXCEPTION 'Provide a response between 10 and 1000 characters'
     USING errcode='22023'; END IF;
 UPDATE public.vendor_intake_cases SET status='submitted',updated_at=now()
 WHERE id=p_case_id AND applicant_id=auth.uid() AND status='needs_information'
 RETURNING * INTO v_case;
 IF NOT FOUND THEN
   RAISE EXCEPTION 'No information request for this application'
     USING errcode='42501'; END IF;
 INSERT INTO public.vendor_intake_events(
   case_id,actor_id,event_type,previous_status,next_status,reason)
 VALUES(p_case_id,auth.uid(),'applicant_replied','needs_information',
   'submitted',btrim(p_response));
 RETURN v_case;
END $$;
REVOKE ALL ON FUNCTION public.respond_vendor_intake_case(uuid,text)
 FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.respond_vendor_intake_case(uuid,text)
 TO authenticated;
