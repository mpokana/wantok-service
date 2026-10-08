-- Phase CX1: opt-in provider-category interest, NOT an application or approval.
-- All fields are minimal: auth user and controlled category. No phone/ID or medical documents.
create table public.provider_category_interests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  category_id uuid not null references public.service_categories(id) on delete restrict,
  status text not null default 'received' check (status = 'received'),
  created_at timestamptz not null default now(),
  unique (user_id, category_id)
);

create index provider_category_interests_category_idx
  on public.provider_category_interests(category_id, created_at desc);

alter table public.provider_category_interests enable row level security;
revoke all on public.provider_category_interests from PUBLIC, anon, authenticated;
grant select on public.provider_category_interests to authenticated;

create policy provider_category_interests_read_own_or_admin
  on public.provider_category_interests
  for select to authenticated
  using (user_id = auth.uid() or public.is_admin(auth.uid()));

-- All inserts go through this checked RPC. No generic table writes for clients.
create or replace function public.register_provider_category_interest(
  p_category_slug text
)
returns uuid
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_slug text := lower(btrim(coalesce(p_category_slug,'')));
  v_category public.service_categories%rowtype;
  v_interest_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;

  select * into v_category from public.service_categories
  where slug = v_slug
    and is_active = true
    and booking_mode = 'information'
    and metadata->>'rollout_status' = 'catalogue_only'
    and metadata->>'provider_onboarding_enabled' = 'false';

  if not found then
    raise exception 'Category is not accepting provider interest'
      using errcode = '22023';
  end if;

  insert into public.provider_category_interests(user_id, category_id)
  values(auth.uid(), v_category.id)
  on conflict(user_id, category_id) do nothing
  returning id into v_interest_id;

  if v_interest_id is null then
    select id into v_interest_id
    from public.provider_category_interests
    where user_id=auth.uid() and category_id=v_category.id;
  end if;

  return v_interest_id;
end;
$$;
revoke all on function public.register_provider_category_interest(text) from PUBLIC, anon;
grant execute on function public.register_provider_category_interest(text) to authenticated;

comment on table public.provider_category_interests is
  'Non-commercial opt-in interest only. Does not create applications, provider profiles, published services, notifications or booking permissions.';
