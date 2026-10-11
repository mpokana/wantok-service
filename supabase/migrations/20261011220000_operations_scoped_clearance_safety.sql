-- E6C: bounded safety investigations; no vendor identity approval or activation.
CREATE OR REPLACE FUNCTION public.has_operations_case_scope(p_duty text,p_case_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path=public,auth AS $$
 SELECT auth.uid() IS NOT NULL
 AND p_duty IN ('case_reviewer','evidence_officer','safety_investigator')
 AND EXISTS (
  SELECT 1 FROM public.vendor_intake_cases c
  JOIN public.operations_case_jurisdictions j ON j.case_id=c.id
  JOIN public.operations_service_category_scopes m ON m.category_id=c.category_id
  JOIN public.operations_approved_regions r ON
    r.region_code=j.region_code AND r.country_code=j.country_code AND r.is_enabled
  WHERE c.id=p_case_id AND c.country_code=j.country_code
    AND j.category_scope=m.category_scope
    AND public.has_operations_scope(p_duty,j.country_code,j.region_code,j.category_scope)
 );
$$;

CREATE FUNCTION public.has_operations_clearance_scope(p_duty text,p_provider_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path=public,auth AS $$
 SELECT p_duty='safety_investigator' AND auth.uid() IS NOT NULL AND EXISTS (
  SELECT 1 FROM public.vendor_activation_clearances a
  JOIN public.vendor_intake_cases c ON c.id=a.evidence_case_id
    AND c.applicant_id=a.provider_id
  WHERE a.provider_id=p_provider_id
  AND public.has_operations_case_scope('safety_investigator',c.id)
 );
$$;
REVOKE ALL ON FUNCTION public.has_operations_clearance_scope(text,uuid)
 FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.has_operations_clearance_scope(text,uuid)
 TO authenticated;

DROP POLICY vendor_clearance_revocation_audit_admin ON public.vendor_clearance_revocation_events;
CREATE POLICY vendor_clearance_revocation_audit_scoped
 ON public.vendor_clearance_revocation_events FOR SELECT TO authenticated
 USING(public.has_operations_clearance_scope('safety_investigator',provider_id));

CREATE OR REPLACE FUNCTION public.list_vendor_clearance_status()
RETURNS TABLE(provider_id uuid,display_name text,expires_at timestamptz,
 revoked_at timestamptz) LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,auth AS $$
BEGIN
 IF auth.uid() IS NULL OR NOT EXISTS (
  SELECT 1 FROM public.operations_duty_grants g
  WHERE g.staff_user_id=auth.uid() AND g.duty='safety_investigator'
  AND g.revoked_at IS NULL AND g.issued_at<=statement_timestamp()
  AND (g.expires_at IS NULL OR g.expires_at>statement_timestamp())
 ) THEN
  RAISE EXCEPTION 'Scoped safety investigator required' USING errcode='42501';
 END IF;
 RETURN QUERY SELECT a.provider_id,p.display_name,a.expires_at,a.revoked_at
 FROM public.vendor_activation_clearances a
 JOIN public.provider_profiles p ON p.provider_id=a.provider_id
 WHERE public.has_operations_clearance_scope('safety_investigator',a.provider_id)
 ORDER BY a.expires_at ASC LIMIT 200;
END $$;
COMMENT ON FUNCTION public.list_vendor_clearance_status() IS
 'Read-only clearance health with verified provider-to-case scope. Not approval.';

-- Staff-driven action requires case jurisdiction plus independence from
-- the provider and the two previously recorded clearance reviewers.
CREATE OR REPLACE FUNCTION public.revoke_vendor_activation_clearance(
 p_provider_id uuid,p_reason text
) RETURNS integer LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,auth AS $$
DECLARE v_count integer; v_clearance public.vendor_activation_clearances%ROWTYPE;
BEGIN
 IF length(btrim(coalesce(p_reason,''))) NOT BETWEEN 15 AND 1000 THEN
  RAISE EXCEPTION 'Revocation reason must be 15-1000 characters' USING errcode='22023';
 END IF;
 SELECT * INTO v_clearance FROM public.vendor_activation_clearances
 WHERE provider_id=p_provider_id FOR UPDATE;
 IF NOT FOUND OR NOT public.has_operations_clearance_scope(
     'safety_investigator',p_provider_id)
    OR auth.uid()=p_provider_id
    OR auth.uid() IN (v_clearance.identity_reviewer,v_clearance.approving_officer) THEN
  RAISE EXCEPTION 'Scoped independent safety investigator required' USING errcode='42501';
 END IF;
 IF v_clearance.revoked_at IS NOT NULL THEN
  RAISE EXCEPTION 'No current clearance available for revocation' USING errcode='22023';
 END IF;
 UPDATE public.vendor_activation_clearances
 SET revoked_at=clock_timestamp(),revoked_by=auth.uid(),revocation_reason=btrim(p_reason)
 WHERE provider_id=p_provider_id AND revoked_at IS NULL;
 UPDATE public.provider_services SET status='paused'
 WHERE provider_id=p_provider_id AND status='active';
 GET DIAGNOSTICS v_count=ROW_COUNT;
 INSERT INTO public.vendor_clearance_revocation_events
 (provider_id,actor_id,reason,paused_service_count)
 VALUES(p_provider_id,auth.uid(),btrim(p_reason),v_count);
 RETURN v_count;
END $$;
COMMENT ON FUNCTION public.revoke_vendor_activation_clearance(uuid,text) IS
 'Independent, jurisdiction-bound emergency revocation; atomic service pause and audit.';

-- Historical/unmapped vendors still need an urgent trusted shutdown channel.
-- Access is exclusively to the server role; no web/admin/anonymous grant.
CREATE FUNCTION public.emergency_revoke_vendor_clearance_trusted(
 p_provider_id uuid,p_operator_id uuid,p_reason text
) RETURNS integer LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,auth AS $$
DECLARE v_count integer;
BEGIN
 IF length(btrim(coalesce(p_reason,''))) NOT BETWEEN 25 AND 970
 OR NOT EXISTS(SELECT 1 FROM public.profiles WHERE id=p_operator_id) THEN
  RAISE EXCEPTION 'Trusted operator and incident justification required' USING errcode='22023';
 END IF;
 UPDATE public.vendor_activation_clearances
 SET revoked_at=clock_timestamp(),revoked_by=p_operator_id,
 revocation_reason='TRUSTED SAFETY STOP: '||btrim(p_reason)
 WHERE provider_id=p_provider_id AND revoked_at IS NULL;
 IF NOT FOUND THEN
  RAISE EXCEPTION 'No current clearance available for revocation' USING errcode='22023';
 END IF;
 UPDATE public.provider_services SET status='paused'
 WHERE provider_id=p_provider_id AND status='active';
 GET DIAGNOSTICS v_count=ROW_COUNT;
 INSERT INTO public.vendor_clearance_revocation_events
 (provider_id,actor_id,reason,paused_service_count)
 VALUES(p_provider_id,p_operator_id,'TRUSTED SAFETY STOP: '||btrim(p_reason),v_count);
 RETURN v_count;
END $$;
REVOKE ALL ON FUNCTION public.emergency_revoke_vendor_clearance_trusted(
 uuid,uuid,text) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.emergency_revoke_vendor_clearance_trusted(
 uuid,uuid,text) TO service_role;

-- Until E9, the legacy provider service status RPC permits only a local
-- independent safety pause. No activation, rejection or re-opening.
CREATE OR REPLACE FUNCTION public.admin_set_provider_service_status(
 p_service_id uuid,p_status text
) RETURNS public.provider_services
LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,auth AS $$
DECLARE v_service public.provider_services%ROWTYPE;
BEGIN
 IF p_status NOT IN ('draft','pending_review','active','paused','rejected') THEN
  RAISE EXCEPTION 'Invalid status' USING errcode='22023';
 END IF;
 IF p_status='active' THEN
  RAISE EXCEPTION 'New service activation disabled pending independent release'
  USING errcode='42501';
 END IF;
 SELECT * INTO v_service FROM public.provider_services
 WHERE id=p_service_id FOR UPDATE;
 IF NOT FOUND OR p_status<>'paused'
 OR NOT public.has_operations_clearance_scope('safety_investigator',v_service.provider_id)
 OR NOT EXISTS (
  SELECT 1 FROM public.vendor_activation_clearances a
  JOIN public.vendor_intake_cases c ON c.id=a.evidence_case_id
  WHERE a.provider_id=v_service.provider_id AND c.applicant_id=a.provider_id
  AND c.category_id=v_service.category_id
 ) THEN
  RAISE EXCEPTION 'Scoped safety pause required' USING errcode='42501';
 END IF;
 UPDATE public.provider_services SET status='paused'
 WHERE id=p_service_id AND status<>'paused'
 RETURNING * INTO v_service;
 IF NOT FOUND THEN
  SELECT * INTO v_service FROM public.provider_services WHERE id=p_service_id;
 END IF;
 RETURN v_service;
END $$;
COMMENT ON FUNCTION public.admin_set_provider_service_status(uuid,text) IS
 'E6C: activation blocked until E9; independently scoped service pause only.';

-- Legacy provider application approval lacks canonical jurisdiction linkage.
-- Seal only this decision path until an E6 scope and E9 release workflow exists.
CREATE OR REPLACE FUNCTION public.review_provider_application(
 p_application_id uuid,p_decision text
) RETURNS public.provider_applications
LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,auth AS $$
BEGIN
 RAISE EXCEPTION 'Legacy provider approval disabled pending scoped review'
 USING errcode='42501';
END $$;
COMMENT ON FUNCTION public.review_provider_application(uuid,text) IS
 'E6C: old provider accept/reject disabled until scoped independent review.';
