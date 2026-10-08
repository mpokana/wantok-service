-- CX1E: evidence-vault boundary and no-upload requirement planning.
-- Intentionally NO Storage object policies, upload links, scanner bypass or document intake.
-- This migration does not change legacy provider-documents or existing approval behaviour.

insert into storage.buckets
  (id, name, public, file_size_limit, allowed_mime_types)
values
  ('staged-provider-evidence', 'staged-provider-evidence', false, 5242880,
   array['application/pdf','image/jpeg','image/png']::text[])
on conflict (id) do update
set public=false,
    file_size_limit=excluded.file_size_limit,
    allowed_mime_types=excluded.allowed_mime_types;

-- Deliberately do not create a SELECT / INSERT / UPDATE / DELETE policy on
-- storage.objects for staged-provider-evidence: every ordinary user is denied.
-- A future scanner and isolated service backend will need a separate,
-- reviewed migration and cannot use the legacy owner-editable bucket.

create table public.staged_evidence_requirements (
  check_id uuid primary key references public.staged_verification_checks(id)
    on delete restrict,
  application_id uuid not null references public.staged_provider_applications(id)
    on delete restrict,
  state text not null default 'planned'
    check (state in ('planned','cancelled')),
  planned_by uuid not null references public.profiles(id) on delete restrict,
  planned_at timestamptz not null default now(),
  cancelled_by uuid references public.profiles(id) on delete set null,
  cancelled_at timestamptz,
  constraint evidence_requirement_cancel_consistency check (
    (state='planned' and cancelled_by is null and cancelled_at is null)
    or (state='cancelled' and cancelled_by is not null and cancelled_at is not null)
  )
);
create index staged_evidence_requirements_application_idx
  on public.staged_evidence_requirements(application_id, planned_at desc);

create table public.staged_evidence_requirement_audit (
  id bigint generated always as identity primary key,
  check_id uuid not null references public.staged_verification_checks(id)
    on delete restrict,
  application_id uuid not null references public.staged_provider_applications(id)
    on delete restrict,
  actor_id uuid not null references public.profiles(id) on delete restrict,
  action text not null check (action in ('planned','cancelled')),
  event_at timestamptz not null default now()
);
create index staged_evidence_requirement_audit_application_idx
  on public.staged_evidence_requirement_audit(application_id, event_at desc);

alter table public.staged_evidence_requirements enable row level security;
alter table public.staged_evidence_requirement_audit enable row level security;
revoke all on public.staged_evidence_requirements from public, anon, authenticated;
revoke all on public.staged_evidence_requirement_audit from public, anon, authenticated;
grant select on public.staged_evidence_requirements to authenticated;
grant select on public.staged_evidence_requirement_audit to authenticated;

create policy staged_evidence_requirements_owner_admin
  on public.staged_evidence_requirements for select to authenticated
  using (exists (
    select 1 from public.staged_provider_applications a
    where a.id=application_id
      and (a.user_id=auth.uid() or public.is_admin(auth.uid()))
  ));
create policy staged_evidence_requirements_audit_admin
  on public.staged_evidence_requirement_audit for select to authenticated
  using (public.is_admin(auth.uid()));

create or replace function public.plan_staged_evidence_requirement(p_check_id uuid)
returns public.staged_evidence_requirements
language plpgsql security definer set search_path=public, auth as $$
declare
  v_check public.staged_verification_checks%rowtype;
  v_application public.staged_provider_applications%rowtype;
  v_result public.staged_evidence_requirements%rowtype;
begin
  if auth.uid() is null or not public.is_admin(auth.uid()) then
    raise exception 'Admin access required' using errcode='42501';
  end if;

  select * into v_check
    from public.staged_verification_checks where id=p_check_id;
  if not found then
    raise exception 'Review checklist item not found' using errcode='22023';
  end if;
  select * into v_application
    from public.staged_provider_applications
    where id=v_check.application_id for update;
  if v_application.status <> 'in_review'
     or not exists (
       select 1 from public.provider_onboarding_policies p
       where p.category_id=v_application.category_id
         and p.intake_status='staged'
     ) then
    raise exception 'Application is not in preliminary review'
      using errcode='22023';
  end if;

  insert into public.staged_evidence_requirements
    (check_id, application_id, planned_by)
  values(v_check.id,v_application.id,auth.uid())
  on conflict (check_id) do nothing
  returning * into v_result;

  if found then
    insert into public.staged_evidence_requirement_audit
      (check_id,application_id,actor_id,action)
    values (v_check.id,v_application.id,auth.uid(),'planned');
  else
    select * into v_result from public.staged_evidence_requirements
      where check_id=v_check.id;
  end if;

  return v_result;
end;
$$;

create or replace function public.cancel_staged_evidence_requirement(p_check_id uuid)
returns public.staged_evidence_requirements
language plpgsql security definer set search_path=public, auth as $$
declare
  v_result public.staged_evidence_requirements%rowtype;
begin
  if auth.uid() is null or not public.is_admin(auth.uid()) then
    raise exception 'Admin access required' using errcode='42501';
  end if;
  update public.staged_evidence_requirements
  set state='cancelled',cancelled_by=auth.uid(),cancelled_at=now()
  where check_id=p_check_id and state='planned'
  returning * into v_result;
  if not found then
    raise exception 'Active evidence requirement not found'
      using errcode='22023';
  end if;
  insert into public.staged_evidence_requirement_audit
    (check_id,application_id,actor_id,action)
  values(v_result.check_id,v_result.application_id,auth.uid(),'cancelled');
  return v_result;
end;
$$;
revoke all on function public.plan_staged_evidence_requirement(uuid)
  from public, anon;
revoke all on function public.cancel_staged_evidence_requirement(uuid)
  from public, anon;
grant execute on function public.plan_staged_evidence_requirement(uuid)
  to authenticated;
grant execute on function public.cancel_staged_evidence_requirement(uuid)
  to authenticated;

comment on table public.staged_evidence_requirements is
  'Admin-only planning signals. No notification, upload request, document collection, approval or activation.';
comment on table public.staged_evidence_requirement_audit is
  'Admin-only append-only planning history. Records no file content or personal document data.';
comment on column public.staged_evidence_requirements.state is
  'Planning state only. Secure upload is disabled until scanner, retention and evidence access controls are approved.';
