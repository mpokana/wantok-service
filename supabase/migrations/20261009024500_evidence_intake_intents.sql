-- CX1E sealed candidate admission: account-bound intent for a future quarantine gateway.
-- NO Storage INSERT/SELECT policies, NO upload URL, NO credential collection.
create table public.staged_evidence_intake_intents (
 id uuid primary key default gen_random_uuid(),
 check_id uuid not null references public.staged_verification_checks(id) on delete restrict,
 application_id uuid not null references public.staged_provider_applications(id) on delete restrict,
 applicant_id uuid not null references public.profiles(id) on delete restrict,
 consent_notice_version text not null
  check (consent_notice_version = 'WANTOK-EVIDENCE-INTAKE-DRAFT-2026-10'),
 state text not null default 'awaiting_secure_gateway'
  check(state in ('awaiting_secure_gateway','withdrawn')),
 created_at timestamptz not null default now(),
 withdrawn_at timestamptz,
 constraint staged_evidence_intent_withdrawn_consistency check(
   (state='awaiting_secure_gateway' and withdrawn_at is null) or
   (state='withdrawn' and withdrawn_at is not null)
 ),
 unique(check_id,applicant_id)
);
create index staged_evidence_intents_app_idx
 on public.staged_evidence_intake_intents(application_id,created_at desc);
alter table public.staged_evidence_intake_intents enable row level security;
revoke all on public.staged_evidence_intake_intents from public,anon,authenticated;
grant select on public.staged_evidence_intake_intents to authenticated;
create policy staged_intents_read_owner_admin
 on public.staged_evidence_intake_intents for select to authenticated
 using (applicant_id=auth.uid() or public.is_admin(auth.uid()));

create or replace function public.prepare_staged_evidence_intake(
 p_check_id uuid, p_notice_version text
) returns uuid language plpgsql security definer
set search_path=public,auth as $$
declare v_user uuid := auth.uid();
  v_existing public.staged_evidence_intake_intents%rowtype;
  v_app public.staged_provider_applications%rowtype;
  v_id uuid;
begin
 if v_user is null then
   raise exception 'Authentication required' using errcode='28000';
 end if;
 if p_notice_version is distinct from 'WANTOK-EVIDENCE-INTAKE-DRAFT-2026-10' then
   raise exception 'Consent notice version mismatch' using errcode='22023';
 end if;
 select a.* into v_app
 from public.staged_verification_checks c
 join public.staged_provider_applications a on a.id=c.application_id
 join public.staged_evidence_requirements e on e.check_id=c.id
 join public.provider_onboarding_policies p on p.category_id=a.category_id
 join public.service_categories sc on sc.id=a.category_id
 where c.id=p_check_id
   and a.user_id=v_user and a.status='in_review'
   and e.state='planned' and e.application_id=a.id
   and p.intake_status='staged'
   and sc.is_active and sc.booking_mode='information'
   and sc.metadata->>'provider_onboarding_enabled'='false'
 for update of a;
 if not found then
   raise exception 'Evidence intake is not eligible' using errcode='22023';
 end if;
 select * into v_existing from public.staged_evidence_intake_intents
 where check_id=p_check_id and applicant_id=v_user;
 if found then
   if v_existing.state='awaiting_secure_gateway' then
     return v_existing.id;
   end if;
   raise exception 'Evidence intent already withdrawn' using errcode='22023';
 end if;
 insert into public.staged_evidence_intake_intents
  (check_id,application_id,applicant_id,consent_notice_version)
 values(p_check_id,v_app.id,v_user,p_notice_version)
 returning id into v_id;
 return v_id;
end;
$$;

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
 set state='withdrawn',withdrawn_at=now()
 where id=p_intent_id and applicant_id=v_user
 and state='awaiting_secure_gateway'
 returning * into v_result;
 if not found then
  raise exception 'Active intake intent not found' using errcode='22023';
 end if;
 return v_result;
end;
$$;
revoke all on function public.prepare_staged_evidence_intake(uuid,text) from public,anon;
revoke all on function public.withdraw_staged_evidence_intake(uuid) from public,anon;
grant execute on function public.prepare_staged_evidence_intake(uuid,text) to authenticated;
grant execute on function public.withdraw_staged_evidence_intake(uuid) to authenticated;
comment on table public.staged_evidence_intake_intents is
 'NON-UPLOADING eligibility/notice record only; NO documents, upload URLs, scan verdicts or provider approval.';
