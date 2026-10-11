-- E6: explicit scoped Operations duties for internal compliance policy governance.
-- No inherited all-country grants; no evidence intake, clearance issuance, vendor activation.
CREATE TABLE public.operations_duty_grants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  staff_user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  duty text NOT NULL CHECK (duty IN (
    'policy_author','policy_reviewer','evidence_officer',
    'final_approver','safety_investigator')),
  country_code text NOT NULL CHECK (country_code ~ '^[A-Z]{2}$'),
  region_code text CHECK (region_code IS NULL OR
    region_code ~ '^[A-Z]{2}-[A-Z0-9]{1,6}$'),
  category_scope text NOT NULL CHECK (category_scope IN (
    'all','transport','food','trades','equipment','accommodation','other')),
  issued_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  expires_at timestamptz,
  revoked_at timestamptz,
  issued_by uuid REFERENCES auth.users(id) ON DELETE RESTRICT,
  revoke_reason text,
  assignment_reason text NOT NULL CHECK(length(btrim(assignment_reason)) BETWEEN 20 AND 1000),
  CONSTRAINT duty_grant_region_country CHECK(
    region_code IS NULL OR left(region_code,2)=country_code),
  CONSTRAINT duty_grant_valid_period CHECK(
    expires_at IS NULL OR expires_at>issued_at),
  CONSTRAINT duty_grant_revocation_reason CHECK(
    (revoked_at IS NULL AND revoke_reason IS NULL) OR
    (revoked_at IS NOT NULL AND length(btrim(revoke_reason)) BETWEEN 20 AND 1000))
);
CREATE INDEX operations_duty_grants_active_idx
 ON public.operations_duty_grants(staff_user_id,duty,country_code,region_code,category_scope)
 WHERE revoked_at IS NULL;
CREATE TABLE public.operations_duty_events (
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 grant_id uuid NOT NULL REFERENCES public.operations_duty_grants(id) ON DELETE RESTRICT,
 event_type text NOT NULL CHECK(event_type IN('granted','revoked')),
 actor_id uuid REFERENCES auth.users(id) ON DELETE RESTRICT,
 notes text NOT NULL,
 recorded_at timestamptz NOT NULL DEFAULT clock_timestamp()
);
CREATE TABLE public.operations_policy_recusals (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 policy_id uuid NOT NULL REFERENCES public.vendor_policy_drafts(id) ON DELETE RESTRICT,
 staff_user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
 reason text NOT NULL CHECK(length(btrim(reason)) BETWEEN 20 AND 1000),
 recorded_by uuid REFERENCES auth.users(id) ON DELETE RESTRICT,
 recorded_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 UNIQUE(policy_id,staff_user_id)
);
ALTER TABLE public.operations_duty_grants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.operations_duty_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.operations_policy_recusals ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.operations_duty_grants FROM PUBLIC,anon,authenticated;
REVOKE ALL ON public.operations_duty_events FROM PUBLIC,anon,authenticated;
REVOKE ALL ON public.operations_policy_recusals FROM PUBLIC,anon,authenticated;
GRANT SELECT ON public.operations_duty_grants TO authenticated;
CREATE POLICY own_operations_duties ON public.operations_duty_grants
 FOR SELECT TO authenticated USING (staff_user_id=auth.uid());

-- The role is deliberately bound to the server-issued JWT. Clients cannot
-- pass an arbitrary staff ID to test or obtain somebody else's authority.
CREATE FUNCTION public.has_operations_scope(
 p_duty text,p_country_code text,p_region_code text,p_category_scope text
) RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
 SET search_path=public,auth AS $$
 SELECT auth.uid() IS NOT NULL AND p_duty IN (
   'policy_author','policy_reviewer','evidence_officer',
   'final_approver','safety_investigator')
 AND p_country_code ~ '^[A-Z]{2}$'
 AND (p_region_code IS NULL OR
   (p_region_code ~ '^[A-Z]{2}-[A-Z0-9]{1,6}$'
    AND left(p_region_code,2)=p_country_code))
 AND p_category_scope IN (
   'all','transport','food','trades','equipment','accommodation','other')
 AND EXISTS(
  SELECT 1 FROM public.operations_duty_grants g
  WHERE g.staff_user_id=auth.uid()
   AND g.duty=p_duty AND g.country_code=p_country_code
   AND g.revoked_at IS NULL
   AND g.issued_at<=now() AND (g.expires_at IS NULL OR g.expires_at>now())
   AND (g.region_code IS NULL OR g.region_code=p_region_code)
   AND (g.category_scope='all' OR g.category_scope=p_category_scope)
 );
$$;
REVOKE ALL ON FUNCTION public.has_operations_scope(text,text,text,text)
 FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.has_operations_scope(text,text,text,text)
 TO authenticated;
-- The audited assignment/revocation interfaces are exclusively service-role
-- provisioned until independent staff-credential governance is implemented.
CREATE FUNCTION public.provision_operations_duty(
 p_staff_user_id uuid,p_duty text,p_country_code text,p_region_code text,
 p_category_scope text,p_expires_at timestamptz,p_reason text
) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,auth AS $$
DECLARE v_id uuid;
BEGIN
 IF p_reason IS NULL OR length(btrim(p_reason)) NOT BETWEEN 20 AND 1000 THEN
  RAISE EXCEPTION 'Assignment reason is required' USING errcode='22023';
 END IF;
 INSERT INTO public.operations_duty_grants(
  staff_user_id,duty,country_code,region_code,category_scope,
  expires_at,assignment_reason,issued_by)
 VALUES(p_staff_user_id,p_duty,p_country_code,p_region_code,p_category_scope,
  p_expires_at,btrim(p_reason),auth.uid())
 RETURNING id INTO v_id;
 INSERT INTO public.operations_duty_events(grant_id,event_type,actor_id,notes)
 VALUES(v_id,'granted',auth.uid(),btrim(p_reason));
 RETURN v_id;
END $$;
CREATE FUNCTION public.revoke_operations_duty(
 p_grant_id uuid,p_reason text
) RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,auth AS $$
DECLARE v_id uuid;
BEGIN
 IF p_reason IS NULL OR length(btrim(p_reason)) NOT BETWEEN 20 AND 1000 THEN
  RAISE EXCEPTION 'Revocation reason is required' USING errcode='22023';
 END IF;
 UPDATE public.operations_duty_grants SET revoked_at=clock_timestamp(),
  revoke_reason=btrim(p_reason) WHERE id=p_grant_id AND revoked_at IS NULL
 RETURNING id INTO v_id;
 IF v_id IS NULL THEN RETURN false; END IF;
 INSERT INTO public.operations_duty_events(grant_id,event_type,actor_id,notes)
 VALUES(v_id,'revoked',auth.uid(),btrim(p_reason));
 RETURN true;
END $$;
CREATE FUNCTION public.record_policy_recusal(
 p_policy_id uuid,p_staff_user_id uuid,p_reason text
) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,auth AS $$
DECLARE v_id uuid;
BEGIN
 INSERT INTO public.operations_policy_recusals(
  policy_id,staff_user_id,reason,recorded_by)
 VALUES(p_policy_id,p_staff_user_id,btrim(p_reason),auth.uid())
 RETURNING id INTO v_id;
 RETURN v_id;
END $$;
REVOKE ALL ON FUNCTION public.provision_operations_duty(
 uuid,text,text,text,text,timestamptz,text) FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.revoke_operations_duty(uuid,text)
 FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.record_policy_recusal(uuid,uuid,text)
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.provision_operations_duty(
 uuid,text,text,text,text,timestamptz,text) TO service_role;
GRANT EXECUTE ON FUNCTION public.revoke_operations_duty(uuid,text) TO service_role;
GRANT EXECUTE ON FUNCTION public.record_policy_recusal(uuid,uuid,text) TO service_role;

-- The prior RLS admin flags are replaced by jurisdiction AND task scopes.
DROP POLICY policy_admin_read ON public.vendor_policy_drafts;
CREATE POLICY policy_scoped_read ON public.vendor_policy_drafts FOR SELECT
 TO authenticated USING (
 public.has_operations_scope('policy_author',country_code,region_code,category_scope)
 OR public.has_operations_scope('policy_reviewer',country_code,region_code,category_scope)
);
DROP POLICY policy_events_admin_read ON public.vendor_policy_events;
CREATE POLICY policy_events_scoped_read ON public.vendor_policy_events FOR SELECT
 TO authenticated USING (EXISTS(
  SELECT 1 FROM public.vendor_policy_drafts d WHERE d.id=policy_id
));

-- Preserve Phase 2E validation, transactions, immutable revisions and audit.
CREATE OR REPLACE FUNCTION public.create_vendor_policy_draft(
 p_country_code text,p_region_code text,p_category_scope text,
 p_notice_title text,p_notice_body text,p_collection_purpose text,
 p_legal_basis_notes text,p_retention_days integer,
 p_evidence_requirements jsonb
) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER
 SET search_path=public,auth AS $$
DECLARE v_id uuid;
BEGIN
 IF auth.uid() IS NULL THEN
  RAISE EXCEPTION 'Operations policy administrator required' USING errcode='42501';
 END IF;
 IF p_country_code IS NULL OR p_country_code !~ '^[A-Z]{2}$'
    OR (p_region_code IS NOT NULL AND
        (p_region_code !~ '^[A-Z]{2}-[A-Z0-9]{1,6}$'
        OR left(p_region_code,2)<>p_country_code))
    OR p_category_scope NOT IN
     ('all','transport','food','trades','equipment','accommodation','other')
    OR length(btrim(coalesce(p_notice_title,''))) NOT BETWEEN 12 AND 150
    OR length(btrim(coalesce(p_notice_body,''))) NOT BETWEEN 80 AND 5000
    OR length(btrim(coalesce(p_collection_purpose,''))) NOT BETWEEN 30 AND 1500
    OR length(btrim(coalesce(p_legal_basis_notes,''))) NOT BETWEEN 30 AND 1500
    OR p_retention_days NOT BETWEEN 1 AND 3650
    OR jsonb_typeof(p_evidence_requirements) IS DISTINCT FROM 'array'
    OR jsonb_array_length(p_evidence_requirements) NOT BETWEEN 1 AND 16
    OR EXISTS(SELECT 1 FROM jsonb_array_elements(p_evidence_requirements) item
      WHERE jsonb_typeof(item)<>'string'
      OR length(btrim(item #>> '{}')) NOT BETWEEN 5 AND 120)
 THEN RAISE EXCEPTION 'Policy draft details are incomplete or invalid'
  USING errcode='22023'; END IF;
 IF NOT public.has_operations_scope('policy_author',
  p_country_code,p_region_code,p_category_scope) THEN
  RAISE EXCEPTION 'Operations policy administrator required' USING errcode='42501';
 END IF;
 INSERT INTO public.vendor_policy_drafts(
  country_code,region_code,category_scope,notice_title,notice_body,
  collection_purpose,legal_basis_notes,retention_days,
  evidence_requirements,created_by)
 VALUES(p_country_code,p_region_code,p_category_scope,
   btrim(p_notice_title),btrim(p_notice_body),btrim(p_collection_purpose),
   btrim(p_legal_basis_notes),p_retention_days,p_evidence_requirements,auth.uid())
 RETURNING id INTO v_id;
 INSERT INTO public.vendor_policy_events(
   policy_id,actor_id,event_type,next_state)
 VALUES(v_id,auth.uid(),'draft_created','draft');
 RETURN v_id;
END $$;

CREATE OR REPLACE FUNCTION public.submit_vendor_policy_draft(p_policy_id uuid)
RETURNS public.vendor_policy_drafts LANGUAGE plpgsql SECURITY DEFINER
 SET search_path=public,auth AS $$
DECLARE v_row public.vendor_policy_drafts%ROWTYPE;
BEGIN
 IF auth.uid() IS NULL THEN
  RAISE EXCEPTION 'Operations policy administrator required' USING errcode='42501';
 END IF;
 SELECT * INTO v_row FROM public.vendor_policy_drafts
   WHERE id=p_policy_id FOR UPDATE;
 IF NOT FOUND OR v_row.created_by<>auth.uid() OR v_row.state<>'draft'
 OR NOT public.has_operations_scope('policy_author',
  v_row.country_code,v_row.region_code,v_row.category_scope) THEN
  RAISE EXCEPTION 'Draft is unavailable for submission' USING errcode='42501';
 END IF;
 UPDATE public.vendor_policy_drafts
  SET state='submitted',submitted_at=clock_timestamp(),
  updated_at=clock_timestamp()
 WHERE id=p_policy_id RETURNING * INTO v_row;
 INSERT INTO public.vendor_policy_events(
   policy_id,actor_id,event_type,prior_state,next_state)
 VALUES(p_policy_id,auth.uid(),'submitted','draft','submitted');
 RETURN v_row;
END $$;

CREATE OR REPLACE FUNCTION public.review_vendor_policy_draft(
 p_policy_id uuid,p_decision text,p_notes text
) RETURNS public.vendor_policy_drafts LANGUAGE plpgsql SECURITY DEFINER
 SET search_path=public,auth AS $$
DECLARE v_row public.vendor_policy_drafts%ROWTYPE;
BEGIN
 IF auth.uid() IS NULL THEN
  RAISE EXCEPTION 'Operations policy reviewer required' USING errcode='42501';
 END IF;
 IF p_decision NOT IN ('revision_requested','internal_review_complete')
 OR length(btrim(coalesce(p_notes,''))) NOT BETWEEN 20 AND 1500 THEN
  RAISE EXCEPTION 'Independent decision and reason are required'
   USING errcode='22023'; END IF;
 SELECT * INTO v_row FROM public.vendor_policy_drafts
  WHERE id=p_policy_id FOR UPDATE;
 IF NOT FOUND OR v_row.state<>'submitted' OR
    v_row.created_by=auth.uid() OR NOT public.has_operations_scope(
  'policy_reviewer',v_row.country_code,v_row.region_code,v_row.category_scope)
  OR EXISTS(SELECT 1 FROM public.operations_policy_recusals c
    WHERE c.policy_id=v_row.id AND c.staff_user_id=auth.uid()) THEN
  RAISE EXCEPTION 'Independent reviewer required for submitted draft'
   USING errcode='42501';
 END IF;
 UPDATE public.vendor_policy_drafts
 SET state=p_decision,reviewer_id=auth.uid(),reviewer_notes=btrim(p_notes),
   reviewed_at=clock_timestamp(),updated_at=clock_timestamp()
 WHERE id=p_policy_id RETURNING * INTO v_row;
 INSERT INTO public.vendor_policy_events(
  policy_id,actor_id,event_type,prior_state,next_state,notes)
 VALUES(p_policy_id,auth.uid(),p_decision,'submitted',p_decision,btrim(p_notes));
 RETURN v_row;
END $$;

CREATE OR REPLACE FUNCTION public.revise_vendor_policy_draft(
 p_prior_id uuid,p_notice_title text,p_notice_body text,
 p_collection_purpose text,p_legal_basis_notes text,
 p_retention_days integer,p_evidence_requirements jsonb
) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER
 SET search_path=public,auth AS $$
DECLARE v_old public.vendor_policy_drafts%ROWTYPE;v_new uuid;
BEGIN
 IF auth.uid() IS NULL THEN
  RAISE EXCEPTION 'Operations policy administrator required' USING errcode='42501';
 END IF;
 SELECT * INTO v_old FROM public.vendor_policy_drafts
 WHERE id=p_prior_id FOR UPDATE;
 IF NOT FOUND OR v_old.state<>'revision_requested'
 OR v_old.created_by<>auth.uid()
 OR NOT public.has_operations_scope('policy_author',
   v_old.country_code,v_old.region_code,v_old.category_scope) THEN
   RAISE EXCEPTION 'Only the original author can revise a returned policy'
     USING errcode='42501';
 END IF;
 IF EXISTS(SELECT 1 FROM public.vendor_policy_drafts
   WHERE replaces_policy_id=p_prior_id) THEN
   RAISE EXCEPTION 'Policy has already been revised' USING errcode='23505';
 END IF;
 v_new:=public.create_vendor_policy_draft(
   v_old.country_code,v_old.region_code,v_old.category_scope,
   p_notice_title,p_notice_body,p_collection_purpose,p_legal_basis_notes,
   p_retention_days,p_evidence_requirements);
 UPDATE public.vendor_policy_drafts
  SET replaces_policy_id=p_prior_id,revision=v_old.revision+1
 WHERE id=v_new;
 INSERT INTO public.vendor_policy_events(
  policy_id,actor_id,event_type,prior_state,next_state,notes)
 VALUES(v_new,auth.uid(),'revision_created','revision_requested','draft',
  'Revised version of prior reviewed proposal '||p_prior_id::text);
 RETURN v_new;
END $$;
