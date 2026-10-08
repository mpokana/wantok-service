-- CX1 staged verification progress. Deliberately does NOT store sensitive documents.
-- Legacy provider-documents storage policies are NOT used, modified or exposed.
-- No verification outcome here grants provider rights, listings, bookings or payments.
create table public.staged_verification_checks (
  id uuid primary key default gen_random_uuid(),
  application_id uuid not null references public.staged_provider_applications(id)
    on delete cascade,
  requirement_index integer not null check (requirement_index between 1 and 20),
  requirement_label text not null check (length(requirement_label) between 3 and 240),
  review_status text not null default 'pending'
    check (review_status in ('pending','under_review','needs_followup')),
  last_reviewed_by uuid references public.profiles(id) on delete set null,
  last_reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  unique (application_id, requirement_index)
);
create index staged_verification_checks_app_idx
  on public.staged_verification_checks(application_id, requirement_index);

create table public.staged_verification_audit (
  id bigint generated always as identity primary key,
  application_id uuid not null references public.staged_provider_applications(id)
    on delete cascade,
  check_id uuid not null references public.staged_verification_checks(id)
    on delete cascade,
  reviewed_by uuid not null references public.profiles(id) on delete restrict,
  previous_status text not null,
  next_status text not null,
  reviewed_at timestamptz not null default now()
);
create index staged_verification_audit_app_idx
  on public.staged_verification_audit(application_id, reviewed_at desc);

alter table public.staged_verification_checks enable row level security;
alter table public.staged_verification_audit enable row level security;
revoke all on public.staged_verification_checks from public, anon, authenticated;
revoke all on public.staged_verification_audit from public, anon, authenticated;
grant select on public.staged_verification_checks to authenticated;
grant select on public.staged_verification_audit to authenticated;

create policy staged_verification_checks_owner_admin
 on public.staged_verification_checks
 for select to authenticated
 using (exists (
   select 1 from public.staged_provider_applications a
   where a.id = application_id
     and (a.user_id = auth.uid() or public.is_admin(auth.uid()))
 ));
create policy staged_verification_audit_admin_only
 on public.staged_verification_audit
 for select to authenticated
 using (public.is_admin(auth.uid()));

create or replace function public.populate_staged_verification_checks()
returns trigger language plpgsql security definer
set search_path = public, auth as $$
begin
  insert into public.staged_verification_checks
    (application_id, requirement_index, requirement_label)
  select new.id, r.idx::integer, r.label
  from public.provider_onboarding_policies p,
       unnest(p.requirements) with ordinality as r(label, idx)
  where p.category_id = new.category_id
    and p.intake_status = 'staged'
    and r.idx <= 20;
  return new;
end;
$$;
revoke all on function public.populate_staged_verification_checks() from public, anon, authenticated;
create trigger staged_verification_checks_after_application
  after insert on public.staged_provider_applications
  for each row execute function public.populate_staged_verification_checks();

-- Backfill any existing preliminary applications without altering current review state.
insert into public.staged_verification_checks
 (application_id, requirement_index, requirement_label)
select a.id, r.idx::integer, r.label
from public.staged_provider_applications a
join public.provider_onboarding_policies p on p.category_id = a.category_id
cross join lateral unnest(p.requirements) with ordinality as r(label, idx)
where p.intake_status = 'staged' and r.idx <= 20
on conflict (application_id, requirement_index) do nothing;

create or replace function public.update_staged_verification_check(
  p_check_id uuid, p_status text
) returns public.staged_verification_checks
language plpgsql security definer
set search_path = public, auth as $$
declare
  v_old public.staged_verification_checks%rowtype;
  v_updated public.staged_verification_checks%rowtype;
  v_application public.staged_provider_applications%rowtype;
  v_policy_status text;
begin
  if auth.uid() is null or not public.is_admin(auth.uid()) then
    raise exception 'Admin access required' using errcode='42501';
  end if;
  if p_status is null
    or p_status not in ('pending','under_review','needs_followup') then
    raise exception 'Only preliminary review progress is supported'
      using errcode='22023';
  end if;
  select * into v_old
  from public.staged_verification_checks where id = p_check_id for update;
  if not found then
    raise exception 'Verification check not found' using errcode='22023';
  end if;
  select * into v_application
  from public.staged_provider_applications
  where id = v_old.application_id for update;
  select intake_status into v_policy_status
  from public.provider_onboarding_policies
  where category_id = v_application.category_id;
  if v_application.status <> 'in_review' or v_policy_status <> 'staged' then
    raise exception 'Application is not in preliminary review'
      using errcode='22023';
  end if;
  if v_old.review_status = p_status then
    return v_old;
  end if;
  update public.staged_verification_checks
  set review_status=p_status,last_reviewed_by=auth.uid(),last_reviewed_at=now()
  where id=p_check_id returning * into v_updated;
  insert into public.staged_verification_audit
    (application_id,check_id,reviewed_by,previous_status,next_status)
  values (v_old.application_id,p_check_id,auth.uid(),v_old.review_status,p_status);
  return v_updated;
end;
$$;
revoke all on function public.update_staged_verification_check(uuid,text) from public, anon;
grant execute on function public.update_staged_verification_check(uuid,text) to authenticated;
comment on table public.staged_verification_checks is
  'Preliminary reviewer workflow only: pending/under_review/needs_followup; no document evidence, no approval.';
comment on table public.staged_verification_audit is
  'Read-only administrator change audit. Review progress never grants verified provider status.';
