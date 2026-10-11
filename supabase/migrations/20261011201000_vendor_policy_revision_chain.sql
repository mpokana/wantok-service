-- Immutable version lineage. Superseded proposals remain readable to
-- administrators; no revision can inherit operative or legal approval.
ALTER TABLE public.vendor_policy_drafts
 ADD COLUMN replaces_policy_id uuid UNIQUE
 REFERENCES public.vendor_policy_drafts(id) ON DELETE RESTRICT;
ALTER TABLE public.vendor_policy_drafts ADD CONSTRAINT policy_revision_lineage CHECK(
  (revision=1 AND replaces_policy_id IS NULL) OR
  (revision>1 AND replaces_policy_id IS NOT NULL)
);
ALTER TABLE public.vendor_policy_events DROP CONSTRAINT vendor_policy_events_event_type_check;
ALTER TABLE public.vendor_policy_events
 ADD CONSTRAINT vendor_policy_events_event_type_check CHECK(event_type IN
 ('draft_created','revision_created','submitted','revision_requested',
  'internal_review_complete'));

CREATE OR REPLACE FUNCTION public.revise_vendor_policy_draft(
 p_prior_id uuid,p_notice_title text,p_notice_body text,
 p_collection_purpose text,p_legal_basis_notes text,
 p_retention_days integer,p_evidence_requirements jsonb
) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER
 SET search_path=public,auth AS $$
DECLARE v_old public.vendor_policy_drafts%ROWTYPE;v_new uuid;
BEGIN
 IF auth.uid() IS NULL OR NOT public.is_admin(auth.uid()) THEN
  RAISE EXCEPTION 'Operations policy administrator required' USING errcode='42501';
 END IF;
 SELECT * INTO v_old FROM public.vendor_policy_drafts
 WHERE id=p_prior_id FOR UPDATE;
 IF NOT FOUND OR v_old.state<>'revision_requested'
 OR v_old.created_by<>auth.uid() THEN
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
REVOKE ALL ON FUNCTION public.revise_vendor_policy_draft(
 uuid,text,text,text,text,integer,jsonb) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.revise_vendor_policy_draft(
 uuid,text,text,text,text,integer,jsonb) TO authenticated;
COMMENT ON FUNCTION public.revise_vendor_policy_draft(
 uuid,text,text,text,text,integer,jsonb) IS
 'Create new immutable numbered draft from a revision-requested predecessor. No publication, consent or activation.';
