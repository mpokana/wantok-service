-- E6D: independent, audited signed-in staff-duty provisioning.
-- No automatic admin inheritance. Bootstrap authorisers are inserted only
-- by the trusted service role after independent offline verification.
CREATE TABLE public.operations_provisioning_authorities (
 staff_user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
 country_code text NOT NULL CHECK(country_code ~ '^[A-Z]{2}$'),
 authority text NOT NULL CHECK(authority IN ('requester','approver')),
 authorised_by uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
 provenance text NOT NULL CHECK(length(btrim(provenance)) BETWEEN 30 AND 1200),
 issued_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 revoked_at timestamptz,
 PRIMARY KEY (staff_user_id,country_code,authority),
 CHECK(staff_user_id<>authorised_by)
);
CREATE TABLE public.operations_duty_change_requests (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 action text NOT NULL CHECK(action IN ('grant','revoke')),
 staff_user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
 duty text NOT NULL CHECK(duty IN (
 'policy_author','policy_reviewer','case_reviewer','evidence_officer',
 'final_approver','safety_investigator')),
 country_code text NOT NULL CHECK(country_code ~ '^[A-Z]{2}$'),
 region_code text,
 category_scope text NOT NULL CHECK(category_scope IN (
 'all','transport','food','trades','equipment','accommodation','other')),
 expires_at timestamptz,
 target_grant_id uuid REFERENCES public.operations_duty_grants(id) ON DELETE RESTRICT,
 proposed_by uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
 proposed_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 proposed_reason text NOT NULL CHECK(length(btrim(proposed_reason)) BETWEEN 30 AND 1000),
 status text NOT NULL DEFAULT 'pending' CHECK(status IN('pending','approved','rejected')),
 decided_by uuid REFERENCES public.profiles(id) ON DELETE RESTRICT,
 decided_at timestamptz,
 decision_reason text,
 resulting_grant_id uuid REFERENCES public.operations_duty_grants(id) ON DELETE RESTRICT,
 CHECK (region_code IS NULL OR
   (region_code ~ '^[A-Z]{2}-[A-Z0-9]{1,6}$'
   AND left(region_code,2)=country_code)),
 CHECK ((action='grant' AND target_grant_id IS NULL) OR
        (action='revoke' AND target_grant_id IS NOT NULL)),
 CHECK(staff_user_id<>proposed_by),
 CHECK((status='pending' AND decided_by IS NULL AND decided_at IS NULL
         AND decision_reason IS NULL) OR
       (status<>'pending' AND decided_by IS NOT NULL AND decided_at IS NOT NULL
        AND length(btrim(decision_reason)) BETWEEN 30 AND 1000
        AND decided_by<>proposed_by AND decided_by<>staff_user_id))
);
CREATE TABLE public.operations_duty_change_events (
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 request_id uuid NOT NULL REFERENCES public.operations_duty_change_requests(id) ON DELETE RESTRICT,
 actor_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
 action text NOT NULL CHECK(action IN ('requested','approved','rejected')),
 reason text NOT NULL,
 occurred_at timestamptz NOT NULL DEFAULT clock_timestamp()
);
CREATE UNIQUE INDEX operations_change_one_pending_revoke
 ON public.operations_duty_change_requests(target_grant_id)
 WHERE action='revoke' AND status='pending';
CREATE UNIQUE INDEX operations_change_one_pending_grant
 ON public.operations_duty_change_requests(
 staff_user_id,duty,country_code,coalesce(region_code,''),
 category_scope) WHERE action='grant' AND status='pending';
ALTER TABLE public.operations_provisioning_authorities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.operations_duty_change_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.operations_duty_change_events ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.operations_provisioning_authorities FROM PUBLIC,anon,authenticated;
REVOKE ALL ON public.operations_duty_change_requests FROM PUBLIC,anon,authenticated;
REVOKE ALL ON public.operations_duty_change_events FROM PUBLIC,anon,authenticated;
GRANT SELECT ON public.operations_provisioning_authorities TO authenticated;
GRANT SELECT ON public.operations_duty_change_requests TO authenticated;
CREATE POLICY my_provisioning_authority ON public.operations_provisioning_authorities
 FOR SELECT TO authenticated USING(staff_user_id=auth.uid());
CREATE POLICY my_change_requests ON public.operations_duty_change_requests
 FOR SELECT TO authenticated USING(
 staff_user_id=auth.uid() OR proposed_by=auth.uid() OR decided_by=auth.uid()
 OR EXISTS(
  SELECT 1 FROM public.operations_provisioning_authorities a
  WHERE a.staff_user_id=auth.uid() AND a.authority='approver'
   AND a.country_code=operations_duty_change_requests.country_code
   AND a.revoked_at IS NULL AND a.issued_at<=statement_timestamp()));

-- Human authorisers are mutually accountable. Only trusted service-role
-- operators may seed/disable credentials after recording physical identity
-- and delegated authority provenance outside this app.
CREATE FUNCTION public.configure_operations_provisioner(
 p_staff uuid,p_country text,p_authority text,p_verified_by uuid,
 p_provenance text,p_enabled boolean
) RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER
 SET search_path=public,auth AS $$
BEGIN
 IF p_staff IS NULL OR p_verified_by IS NULL OR p_staff=p_verified_by
 OR p_country IS NULL OR p_country !~ '^[A-Z]{2}$'
 OR p_authority NOT IN ('requester','approver')
 OR length(btrim(coalesce(p_provenance,''))) NOT BETWEEN 30 AND 1200
 OR NOT EXISTS(SELECT 1 FROM public.profiles WHERE id=p_staff)
 OR NOT EXISTS(SELECT 1 FROM public.profiles WHERE id=p_verified_by) THEN
  RAISE EXCEPTION 'Independently verified authority provenance required'
  USING errcode='22023';
 END IF;
 INSERT INTO public.operations_provisioning_authorities
 (staff_user_id,country_code,authority,authorised_by,provenance,revoked_at)
 VALUES(p_staff,p_country,p_authority,p_verified_by,btrim(p_provenance),
  CASE WHEN p_enabled THEN NULL ELSE clock_timestamp() END)
 ON CONFLICT (staff_user_id,country_code,authority) DO UPDATE
 SET authorised_by=EXCLUDED.authorised_by,
 provenance=EXCLUDED.provenance,issued_at=clock_timestamp(),
 revoked_at=EXCLUDED.revoked_at;
 RETURN true;
END $$;
REVOKE ALL ON FUNCTION public.configure_operations_provisioner(
 uuid,text,text,uuid,text,boolean) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.configure_operations_provisioner(
 uuid,text,text,uuid,text,boolean) TO service_role;

CREATE FUNCTION public.request_operations_duty_change(
 p_action text,p_staff uuid,p_duty text,p_country text,p_region text,
 p_category text,p_expires timestamptz,p_target uuid,p_reason text
) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,auth AS $$
DECLARE v_actor uuid:=auth.uid();v_id uuid;
 v_grant public.operations_duty_grants%ROWTYPE;
BEGIN
 IF v_actor IS NULL OR v_actor=p_staff OR
 NOT EXISTS(SELECT 1 FROM public.operations_provisioning_authorities a
 WHERE a.staff_user_id=v_actor AND a.authority='requester'
 AND a.country_code=p_country AND a.revoked_at IS NULL
 AND a.issued_at<=statement_timestamp()) THEN
  RAISE EXCEPTION 'Independent authorised requester required'
   USING errcode='42501';
 END IF;
 IF p_action NOT IN ('grant','revoke')
 OR p_duty NOT IN('policy_author','policy_reviewer','case_reviewer',
 'evidence_officer','final_approver','safety_investigator')
 OR p_country IS NULL OR p_country !~ '^[A-Z]{2}$'
 OR p_category NOT IN('all','transport','food','trades','equipment',
 'accommodation','other')
 OR length(btrim(coalesce(p_reason,''))) NOT BETWEEN 30 AND 1000
 OR NOT EXISTS(SELECT 1 FROM public.profiles WHERE id=p_staff)
 OR (p_region IS NOT NULL AND NOT EXISTS (
  SELECT 1 FROM public.operations_approved_regions r
  WHERE r.region_code=p_region AND r.country_code=p_country AND r.is_enabled))
 THEN RAISE EXCEPTION 'Verified assignment scope and purpose required'
  USING errcode='22023'; END IF;
 IF p_action='grant' THEN
  IF p_target IS NOT NULL OR p_expires IS NULL
  OR p_expires<=statement_timestamp()
  OR p_expires>statement_timestamp()+interval '366 days' THEN
   RAISE EXCEPTION 'Bounded grant expiry required' USING errcode='22023'; END IF;
  IF EXISTS(SELECT 1 FROM public.operations_duty_grants g
   WHERE g.staff_user_id=p_staff AND g.duty=p_duty AND g.country_code=p_country
   AND g.region_code IS NOT DISTINCT FROM p_region
   AND g.category_scope=p_category AND g.revoked_at IS NULL
   AND (g.expires_at IS NULL OR g.expires_at>statement_timestamp())) THEN
    RAISE EXCEPTION 'Active equivalent duty already exists' USING errcode='23505';
  END IF;
 ELSE
  SELECT * INTO v_grant FROM public.operations_duty_grants
   WHERE id=p_target AND revoked_at IS NULL FOR UPDATE;
  IF NOT FOUND OR v_grant.staff_user_id<>p_staff OR v_grant.duty<>p_duty
  OR v_grant.country_code<>p_country
  OR v_grant.region_code IS DISTINCT FROM p_region
  OR v_grant.category_scope<>p_category
  OR p_expires IS NOT NULL THEN
   RAISE EXCEPTION 'Current exact duty target required'
    USING errcode='22023'; END IF;
 END IF;
 INSERT INTO public.operations_duty_change_requests(
 action,staff_user_id,duty,country_code,region_code,category_scope,
 expires_at,target_grant_id,proposed_by,proposed_reason)
 VALUES(p_action,p_staff,p_duty,p_country,p_region,p_category,
 p_expires,p_target,v_actor,btrim(p_reason)) RETURNING id INTO v_id;
 INSERT INTO public.operations_duty_change_events(request_id,actor_id,action,reason)
 VALUES(v_id,v_actor,'requested',btrim(p_reason));
 RETURN v_id;
END $$;
REVOKE ALL ON FUNCTION public.request_operations_duty_change(
 text,uuid,text,text,text,text,timestamptz,uuid,text)
 FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.request_operations_duty_change(
 text,uuid,text,text,text,text,timestamptz,uuid,text) TO authenticated;

CREATE FUNCTION public.decide_operations_duty_change(
 p_request uuid,p_accept boolean,p_reason text
) RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,auth AS $$
DECLARE v_actor uuid:=auth.uid();
 v_request public.operations_duty_change_requests%ROWTYPE;
 v_grant uuid;v_updated boolean:=false;
BEGIN
 IF length(btrim(coalesce(p_reason,''))) NOT BETWEEN 30 AND 1000 THEN
  RAISE EXCEPTION 'Independent decision rationale required'
   USING errcode='22023'; END IF;
 SELECT * INTO v_request FROM public.operations_duty_change_requests
 WHERE id=p_request FOR UPDATE;
 IF NOT FOUND OR v_request.status<>'pending' THEN
  RAISE EXCEPTION 'Open change request required' USING errcode='22023'; END IF;
 IF v_actor IS NULL OR v_actor IN (
  v_request.staff_user_id,v_request.proposed_by)
 OR NOT EXISTS(SELECT 1 FROM public.operations_provisioning_authorities a
  WHERE a.staff_user_id=v_actor AND a.authority='approver'
  AND a.country_code=v_request.country_code AND a.revoked_at IS NULL
  AND a.issued_at<=statement_timestamp()) OR
 NOT EXISTS(SELECT 1 FROM public.operations_provisioning_authorities a
  WHERE a.staff_user_id=v_request.proposed_by
  AND a.authority='requester' AND a.country_code=v_request.country_code
  AND a.revoked_at IS NULL AND a.issued_at<=statement_timestamp()) THEN
  RAISE EXCEPTION 'Different current independent approver required'
   USING errcode='42501';
 END IF;
 IF p_accept THEN
  IF v_request.action='grant' THEN
   IF v_request.expires_at<=statement_timestamp() OR
    (v_request.region_code IS NOT NULL AND NOT EXISTS(
      SELECT 1 FROM public.operations_approved_regions r
      WHERE r.region_code=v_request.region_code
      AND r.country_code=v_request.country_code AND r.is_enabled)) OR
    EXISTS(SELECT 1 FROM public.operations_duty_grants g
      WHERE g.staff_user_id=v_request.staff_user_id
      AND g.duty=v_request.duty AND g.country_code=v_request.country_code
      AND g.region_code IS NOT DISTINCT FROM v_request.region_code
      AND g.category_scope=v_request.category_scope AND g.revoked_at IS NULL
      AND (g.expires_at IS NULL OR g.expires_at>statement_timestamp())) THEN
    RAISE EXCEPTION 'Grant is expired, invalid or duplicate' USING errcode='22023';
   END IF;
   INSERT INTO public.operations_duty_grants(
    staff_user_id,duty,country_code,region_code,category_scope,
    expires_at,assignment_reason,issued_by)
   VALUES(v_request.staff_user_id,v_request.duty,v_request.country_code,
    v_request.region_code,v_request.category_scope,v_request.expires_at,
    v_request.proposed_reason,v_actor) RETURNING id INTO v_grant;
   INSERT INTO public.operations_duty_events(grant_id,event_type,actor_id,notes)
   VALUES(v_grant,'granted',v_actor,btrim(p_reason));
  ELSE
   UPDATE public.operations_duty_grants
   SET revoked_at=clock_timestamp(),revoke_reason=btrim(p_reason)
   WHERE id=v_request.target_grant_id AND staff_user_id=v_request.staff_user_id
   AND duty=v_request.duty AND country_code=v_request.country_code
   AND region_code IS NOT DISTINCT FROM v_request.region_code
   AND category_scope=v_request.category_scope AND revoked_at IS NULL
   RETURNING id INTO v_grant;
   IF v_grant IS NULL THEN
    RAISE EXCEPTION 'Revocation target is no longer current'
    USING errcode='22023'; END IF;
   INSERT INTO public.operations_duty_events(grant_id,event_type,actor_id,notes)
   VALUES(v_grant,'revoked',v_actor,btrim(p_reason));
  END IF;
 END IF;
 UPDATE public.operations_duty_change_requests
 SET status=CASE WHEN p_accept THEN 'approved' ELSE 'rejected' END,
 decided_by=v_actor,decided_at=clock_timestamp(),
 decision_reason=btrim(p_reason),resulting_grant_id=v_grant
 WHERE id=p_request;
 INSERT INTO public.operations_duty_change_events(request_id,actor_id,action,reason)
 VALUES(p_request,v_actor,
   CASE WHEN p_accept THEN 'approved' ELSE 'rejected' END,btrim(p_reason));
 RETURN p_accept;
END $$;
REVOKE ALL ON FUNCTION public.decide_operations_duty_change(uuid,boolean,text)
 FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.decide_operations_duty_change(uuid,boolean,text)
 TO authenticated;
COMMENT ON FUNCTION public.decide_operations_duty_change(uuid,boolean,text) IS
 'E6D dual human authorisation; no implicit global administrator authority.';
