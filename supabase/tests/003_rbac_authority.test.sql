begin;

create extension if not exists pgtap with schema extensions;
select plan(9);

insert into auth.users (
  id, aud, role, email, raw_user_meta_data, created_at, updated_at
) values
  ('40000000-0000-0000-0000-000000000004', 'authenticated', 'authenticated', 'admin-rbac@wantok.local', '{"full_name":"RBAC Admin"}'::jsonb, now(), now()),
  ('50000000-0000-0000-0000-000000000005', 'authenticated', 'authenticated', 'target-rbac@wantok.local', '{"full_name":"RBAC Target"}'::jsonb, now(), now());

update public.profiles
set is_admin = true
where id = '40000000-0000-0000-0000-000000000004'::uuid;

select ok(
  public.has_role('admin', '40000000-0000-0000-0000-000000000004'::uuid),
  'trusted admin profile flag grants admin RBAC role'
);

update public.profiles
set is_provider = true
where id = '50000000-0000-0000-0000-000000000005'::uuid;

select ok(
  public.has_role('provider', '50000000-0000-0000-0000-000000000005'::uuid),
  'trusted provider flag grants provider RBAC role'
);

update public.profiles
set is_provider = false
where id = '50000000-0000-0000-0000-000000000005'::uuid;

select ok(
  not public.has_role('provider', '50000000-0000-0000-0000-000000000005'::uuid),
  'turning provider flag off removes provider RBAC role'
);

set local role authenticated;
select set_config('request.jwt.claim.sub', '40000000-0000-0000-0000-000000000004', true);

select lives_ok(
  $$select public.grant_user_role(
    '50000000-0000-0000-0000-000000000005'::uuid,
    'support',
    null
  )$$,
  'admin can grant support role through secured RPC'
);

select ok(
  public.has_role('support', '50000000-0000-0000-0000-000000000005'::uuid),
  'granted support role becomes active'
);

select is(
  public.revoke_user_role(
    '50000000-0000-0000-0000-000000000005'::uuid,
    'support'
  ),
  true,
  'admin can revoke support role through secured RPC'
);

select ok(
  not public.has_role('support', '50000000-0000-0000-0000-000000000005'::uuid),
  'revoked support role is no longer active'
);

reset role;

delete from public.user_roles
where user_id = '40000000-0000-0000-0000-000000000004'::uuid
  and role_code = 'admin';

select ok(
  (select is_admin from public.profiles where id = '40000000-0000-0000-0000-000000000004'::uuid),
  'legacy admin profile flag remains true for compatibility test'
);

select ok(
  not public.is_admin('40000000-0000-0000-0000-000000000004'::uuid),
  'legacy admin flag alone no longer grants server-side admin authority'
);

select * from finish();
rollback;
