-- EAGLT02 LOCAL DEVELOPMENT ONLY. METADATA-ONLY custody reconciliation; upload SEALED.
-- No file path, document bytes, encryption key, signed URL, reviewer read or approval.
create table public.staged_evidence_custody_manifests (
  claim_id uuid primary key
    references public.staged_evidence_intent_claim_receipts(claim_id) on delete restrict,
  intent_id uuid not null
    references public.staged_evidence_intent_claim_receipts(intent_id) on delete restrict,
  applicant_id uuid not null references public.profiles(id) on delete restrict,
  application_id uuid not null
    references public.staged_provider_applications(id) on delete restrict,
  check_id uuid not null
    references public.staged_verification_checks(id) on delete restrict,
  plain_sha256 text not null check (plain_sha256 ~ '^[0-9a-f]{64}$'),
  sealed_sha256 text not null check (sealed_sha256 ~ '^[0-9a-f]{64}$'),
  plain_bytes bigint not null check (plain_bytes between 12 and 5242880),
  sealed_bytes bigint not null,
  mime text not null check (mime in ('application/pdf','image/jpeg','image/png')),
  key_id text not null check (key_id ~ '^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$'),
  envelope_version smallint not null default 2 check (envelope_version=2),
  state text not null default 'pending_independent_reconciliation'
    check (state='pending_independent_reconciliation'),
  recorded_at timestamptz not null default clock_timestamp(),
  constraint custody_manifest_envelope_bounds check
    (sealed_bytes > plain_bytes and sealed_bytes <= plain_bytes + 8192)
);
create index staged_custody_manifest_intent_idx
 on public.staged_evidence_custody_manifests(intent_id);

alter table public.staged_evidence_custody_manifests enable row level security;
revoke all on public.staged_evidence_custody_manifests from public,anon,authenticated;
-- No client SELECT policies; no reviewer interface, release or status transition.
-- service_role is not granted direct mutation; only narrowly scoped RPC is granted.

create function public.record_staged_evidence_custody_manifest(
 p_claim_id uuid, p_intent_id uuid, p_applicant_id uuid,
 p_application_id uuid, p_check_id uuid,
 p_plain_sha256 text, p_sealed_sha256 text,
 p_plain_bytes bigint, p_sealed_bytes bigint, p_mime text, p_key_id text
) returns uuid
language plpgsql security definer set search_path='' as $$
declare v_id uuid;
begin
  -- Caller is the separate internal service only; never a client or browser.
  -- Validate all identity associations against the same immutable claim receipt
  -- and current non-withdrawn intent before writing metadata.
  if p_claim_id is null or p_intent_id is null or p_applicant_id is null
     or p_application_id is null or p_check_id is null
     or p_plain_sha256 is null or p_sealed_sha256 is null
     or p_plain_bytes is null or p_sealed_bytes is null
     or p_mime is null or p_key_id is null then
    raise exception 'Custody metadata is invalid' using errcode='22023';
  end if;
  if p_plain_sha256 !~ '^[0-9a-f]{64}$'
     or p_sealed_sha256 !~ '^[0-9a-f]{64}$'
     or p_plain_bytes not between 12 and 5242880
     or p_sealed_bytes <= p_plain_bytes or p_sealed_bytes > p_plain_bytes+8192
     or p_mime not in ('application/pdf','image/jpeg','image/png')
     or p_key_id !~ '^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$' then
    raise exception 'Custody metadata is invalid' using errcode='22023';
  end if;

  insert into public.staged_evidence_custody_manifests
    (claim_id,intent_id,applicant_id,application_id,check_id,
     plain_sha256,sealed_sha256,plain_bytes,sealed_bytes,mime,key_id)
  select r.claim_id,r.intent_id,r.applicant_id,r.application_id,r.check_id,
         p_plain_sha256,p_sealed_sha256,p_plain_bytes,p_sealed_bytes,p_mime,p_key_id
  from public.staged_evidence_intent_claim_receipts r
  join public.staged_evidence_intake_intents i
    on i.id=r.intent_id and i.claim_id=r.claim_id
  join public.staged_evidence_requirements e
    on e.check_id=r.check_id and e.application_id=r.application_id
  where r.claim_id=p_claim_id and r.intent_id=p_intent_id
    and r.applicant_id=p_applicant_id and r.application_id=p_application_id
    and r.check_id=p_check_id
    and i.state='claimed_for_quarantine' and i.withdrawn_at is null
    and e.state='planned'
    and not exists (
      select 1 from public.staged_evidence_custody_manifests m
      where m.claim_id=r.claim_id
    )
  on conflict (claim_id) do nothing
  returning claim_id into v_id;

  if v_id is null then
    raise exception 'Custody claim unavailable or already recorded'
      using errcode='22023';
  end if;
  return v_id;
end;
$$;
revoke all on function public.record_staged_evidence_custody_manifest(
 uuid,uuid,uuid,uuid,uuid,text,text,bigint,bigint,text,text
) from public,anon,authenticated;
grant execute on function public.record_staged_evidence_custody_manifest(
 uuid,uuid,uuid,uuid,uuid,text,text,bigint,bigint,text,text
) to service_role;

comment on table public.staged_evidence_custody_manifests is
 'Internal single-write claimed evidence digest metadata. Pending independent reconciliation ONLY: NOT proof of physical custody, no uploads/reviewer read/approval.';
comment on function public.record_staged_evidence_custody_manifest(
 uuid,uuid,uuid,uuid,uuid,text,text,bigint,bigint,text,text
) is
 'Metadata-only restricted RPC. Requires pre-existing one-time claim receipt and non-withdrawn intent. No file verification or approval.';
