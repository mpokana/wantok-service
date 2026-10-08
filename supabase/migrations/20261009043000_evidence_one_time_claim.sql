-- EAGLT02 DEVELOPMENT ONLY. One-time, server-only claim; no file or public upload route.
-- The service must FIRST verify the Supabase access token with GoTrue /auth/v1/user.
-- The subject UUID is then derived from GoTrue, NEVER from the caller's JSON.
alter table public.staged_evidence_intake_intents
  add column claimed_at timestamptz,
  add column claim_id uuid;

alter table public.staged_evidence_intake_intents
  drop constraint staged_evidence_intake_intents_state_check,
  drop constraint staged_evidence_intent_withdrawn_consistency;

alter table public.staged_evidence_intake_intents
  add constraint staged_evidence_intake_intents_state_check
    check (state in ('awaiting_secure_gateway','claimed_for_quarantine','withdrawn')),
  add constraint staged_evidence_intent_lifecycle_check
    check (
      (state='awaiting_secure_gateway' and claim_id is null and claimed_at is null and withdrawn_at is null)
      or (state='claimed_for_quarantine' and claim_id is not null and claimed_at is not null and withdrawn_at is null)
      or (state='withdrawn' and withdrawn_at is not null
          and ((claim_id is null and claimed_at is null) or
               (claim_id is not null and claimed_at is not null)))
    );

create unique index staged_evidence_intent_claim_id_unique
  on public.staged_evidence_intake_intents(claim_id) where claim_id is not null;

-- Internal operational receipt, not an immutable/off-host audit ledger.
-- Client roles cannot read/write it and there is deliberately no reviewer API.
create table public.staged_evidence_intent_claim_receipts (
  intent_id uuid primary key references public.staged_evidence_intake_intents(id) on delete restrict,
  claim_id uuid not null unique,
  applicant_id uuid not null references public.profiles(id) on delete restrict,
  application_id uuid not null references public.staged_provider_applications(id) on delete restrict,
  check_id uuid not null references public.staged_verification_checks(id) on delete restrict,
  claimed_at timestamptz not null default clock_timestamp()
);
alter table public.staged_evidence_intent_claim_receipts enable row level security;
revoke all on public.staged_evidence_intent_claim_receipts from public, anon, authenticated;

-- A single UPDATE is the atomic contention point. The receipt INSERT is in
-- the SAME PostgreSQL transaction; any INSERT failure rolls the claim back.
-- No document bytes, filenames, keys, JWTs or upload capability are returned.
create function public.claim_staged_evidence_intake(
  p_intent_id uuid, p_applicant_id uuid, p_application_id uuid, p_check_id uuid
) returns uuid language plpgsql security definer set search_path=public,auth as $$
declare
  v_claim_id uuid;
  v_claimed_at timestamptz;
begin
  if p_intent_id is null or p_applicant_id is null or
     p_application_id is null or p_check_id is null then
    raise exception 'Invalid evidence claim identity' using errcode='22023';
  end if;

  update public.staged_evidence_intake_intents i
  set state='claimed_for_quarantine',
      claim_id=gen_random_uuid(),
      claimed_at=clock_timestamp()
  from public.staged_verification_checks c,
       public.staged_evidence_requirements e,
       public.staged_provider_applications a,
       public.provider_onboarding_policies p,
       public.service_categories sc
  where i.id=p_intent_id and i.applicant_id=p_applicant_id
    and i.application_id=p_application_id and i.check_id=p_check_id
    and i.state='awaiting_secure_gateway'
    and i.consent_notice_version='WANTOK-EVIDENCE-INTAKE-DRAFT-2026-10'
    and c.id=i.check_id and c.application_id=i.application_id
    and e.check_id=c.id and e.application_id=i.application_id and e.state='planned'
    and a.id=i.application_id and a.user_id=i.applicant_id and a.status='in_review'
    and p.category_id=a.category_id and p.intake_status='staged'
    and sc.id=a.category_id and sc.is_active
    and sc.booking_mode='information'
    and sc.metadata->>'provider_onboarding_enabled'='false'
  returning i.claim_id,i.claimed_at into v_claim_id,v_claimed_at;

  if v_claim_id is null then
    raise exception 'Evidence intent not eligible for one-time claim'
      using errcode='22023';
  end if;

  insert into public.staged_evidence_intent_claim_receipts
    (intent_id,claim_id,applicant_id,application_id,check_id,claimed_at)
  values
    (p_intent_id,v_claim_id,p_applicant_id,p_application_id,p_check_id,v_claimed_at);

  return v_claim_id;
end;
$$;
revoke all on function public.claim_staged_evidence_intake(uuid,uuid,uuid,uuid)
  from public, anon, authenticated;
grant execute on function public.claim_staged_evidence_intake(uuid,uuid,uuid,uuid)
  to service_role;

-- Withdrawal is allowed even after a claim: it revokes further use, but does
-- not erase the minimal receipt required to investigate an attempted intake.
create or replace function public.withdraw_staged_evidence_intake(p_intent_id uuid)
 returns public.staged_evidence_intake_intents
 language plpgsql security definer set search_path=public,auth as $$
declare v_user uuid := auth.uid();
 v_result public.staged_evidence_intake_intents%rowtype;
begin
 if v_user is null then
  raise exception 'Authentication required' using errcode='28000';
 end if;
 update public.staged_evidence_intake_intents
 set state='withdrawn',withdrawn_at=clock_timestamp()
 where id=p_intent_id and applicant_id=v_user
   and state in ('awaiting_secure_gateway','claimed_for_quarantine')
 returning * into v_result;
 if not found then
  raise exception 'Active intake intent not found' using errcode='22023';
 end if;
 return v_result;
end;
$$;
revoke all on function public.withdraw_staged_evidence_intake(uuid) from public,anon;
grant execute on function public.withdraw_staged_evidence_intake(uuid) to authenticated;

comment on function public.claim_staged_evidence_intake(uuid,uuid,uuid,uuid) is
 'Service-role-only one-time metadata claim AFTER external GoTrue JWT verification. No upload/storage permission; draft notice is NOT informed consent.';
