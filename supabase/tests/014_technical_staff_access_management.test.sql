begin;

create extension if not exists pgtap with schema extensions;
select plan(27);

insert into auth.users (
  id, aud, role, email, raw_user_meta_data, created_at, updated_at
) values
  ('e1000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated',
   't21-platform@wantok.local', '{"full_name":"T21 Platform Admin"}'::jsonb, now(), now()),
  ('e1000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated',
   't21-tech-admin@wantok.local', '{"full_name":"T21 Tech Admin"}'::jsonb, now(), now()),
  ('e1000000-0000-0000-0000-000000000003', 'authenticated', 'authenticated',
   't21-module-admin@wantok.local', '{"full_name":"T21 Module Admin"}'::jsonb, now(), now()),
  ('e1000000-0000-0000-0000-000000000004', 'authenticated', 'authenticated',
   't21-support@wantok.local', '{"full_name":"T21 Support"}'::jsonb, now(), now()),
  ('e1000000-0000-0000-0000-000000000005', 'authenticated', 'authenticated',
   'alice.target@wantok.local', '{"full_name":"Alice Target"}'::jsonb, now(), now()),
  ('e1000000-0000-0000-0000-000000000006', 'authenticated', 'authenticated',
   't21-operations@wantok.local', '{"full_name":"T21 Operations Admin"}'::jsonb, now(), now());

update public.profiles
set is_admin = true
where id = 'e1000000-0000-0000-0000-000000000006'::uuid;

-- Make this transaction deterministic even when local developers have the
-- global technical role. The entire test is rolled back.
delete from public.user_roles
where role_code = 'tech_platform_admin';

insert into public.user_roles (
  user_id, role_code, granted_by
) values (
  'e1000000-0000-0000-0000-000000000001',
  'tech_platform_admin',
  null
);

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  'e1000000-0000-0000-0000-000000000001',
  true
);

select ok(
  public.can_manage_technical_module_access('mobility.taxi'),
  'platform administrator can manage Taxi technical access'
);

select is(
  (
    select count(*)::integer
    from public.list_assignable_technical_access_levels('mobility.taxi')
  ),
  4,
  'platform administrator can assign all four module access levels'
);

select is(
  (
    select code
    from public.list_assignable_technical_access_levels('mobility.taxi')
    order by rank desc
    limit 1
  ),
  'tech_admin',
  'highest module assignment offered to platform administrator is Technical Administrator'
);

select lives_ok(
  $$select public.grant_technical_module_access(
    'e1000000-0000-0000-0000-000000000002'::uuid,
    'mobility.taxi',
    'tech_admin',
    null,
    'Taxi technical owner'
  )$$,
  'platform administrator can assign a Technical Administrator'
);

select lives_ok(
  $$select public.grant_technical_module_access(
    'e1000000-0000-0000-0000-000000000003'::uuid,
    'mobility.taxi',
    'tech_module_admin',
    null,
    'Taxi module administrator'
  )$$,
  'platform administrator can assign a Module Administrator'
);

select lives_ok(
  $$select public.grant_technical_module_access(
    'e1000000-0000-0000-0000-000000000004'::uuid,
    'mobility.taxi',
    'tech_support',
    null,
    'Taxi support'
  )$$,
  'platform administrator can assign Technical Support'
);

do $setup$
begin
  perform public.grant_technical_module_access(
    'e1000000-0000-0000-0000-000000000004'::uuid,
    'mobility.taxi',
    'tech_admin',
    null,
    'Peer Technical Administrator for overwrite protection test'
  );
end;
$setup$;

select set_config(
  'request.jwt.claim.sub',
  'e1000000-0000-0000-0000-000000000002',
  true
);

select ok(
  public.can_manage_technical_module_access('mobility.taxi'),
  'Technical Administrator can manage access for their assigned module'
);

select is(
  (
    select count(*)::integer
    from public.list_assignable_technical_access_levels('mobility.taxi')
  ),
  3,
  'Technical Administrator can assign only lower access levels'
);

select is(
  (
    select max(rank)
    from public.list_assignable_technical_access_levels('mobility.taxi')
  ),
  30,
  'Technical Administrator cannot assign another equal Technical Administrator'
);

select throws_ok(
  $$select public.grant_technical_module_access(
    'e1000000-0000-0000-0000-000000000004'::uuid,
    'mobility.taxi',
    'tech_support',
    null,
    'Attempted peer downgrade'
  )$$,
  'P0001',
  'Technical module access administration not permitted',
  'Technical Administrator cannot downgrade an equal Technical Administrator'
);

select is(
  (
    select user_id
    from public.search_technical_accounts(
      'mobility.taxi',
      'alice.target@wantok.local'
    )
    limit 1
  ),
  'e1000000-0000-0000-0000-000000000005'::uuid,
  'authorised technical administrator can find an account by exact email'
);

select is(
  (
    select full_name
    from public.search_technical_accounts(
      'mobility.taxi',
      'Alice'
    )
    limit 1
  ),
  'Alice Target',
  'authorised technical administrator can search an account by name'
);

select throws_ok(
  $$select * from public.search_technical_accounts(
    'mobility.taxi',
    'a'
  )$$,
  'P0001',
  'Search requires at least 2 characters',
  'technical account search refuses broad one-character directory searches'
);

select lives_ok(
  $$select public.grant_technical_module_access(
    'e1000000-0000-0000-0000-000000000005'::uuid,
    'mobility.taxi',
    'tech_module_admin',
    null,
    'Delegated by Taxi technical administrator'
  )$$,
  'Technical Administrator can delegate a lower Module Administrator level'
);

select is(
  (
    select current_access_level_code
    from public.search_technical_accounts(
      'mobility.taxi',
      'alice.target@wantok.local'
    )
    limit 1
  ),
  'tech_module_admin',
  'account search reports the current module assignment'
);

select is(
  (
    select count(*)::integer
    from public.list_technical_module_staff('mobility.taxi')
  ),
  4,
  'staff list contains all four direct Taxi module assignments'
);

select is(
  (
    select email
    from public.list_technical_module_staff('mobility.taxi')
    where user_id = 'e1000000-0000-0000-0000-000000000005'::uuid
  ),
  'alice.target@wantok.local',
  'staff list exposes only the controlled email field needed for administration'
);

select is(
  (
    select granted_by_name
    from public.list_technical_module_staff('mobility.taxi')
    where user_id = 'e1000000-0000-0000-0000-000000000005'::uuid
  ),
  'T21 Tech Admin',
  'staff list records the administrator who delegated access'
);

select throws_ok(
  $$select public.grant_technical_module_access(
    'e1000000-0000-0000-0000-000000000005'::uuid,
    'mobility.taxi',
    'tech_admin',
    null,
    null
  )$$,
  'P0001',
  'Technical module access administration not permitted',
  'Technical Administrator cannot elevate a user to an equal level'
);

select set_config(
  'request.jwt.claim.sub',
  'e1000000-0000-0000-0000-000000000003',
  true
);

select ok(
  not public.can_manage_technical_module_access('mobility.taxi'),
  'Module Administrator cannot delegate module access'
);

select throws_ok(
  $$select * from public.list_technical_module_staff('mobility.taxi')$$,
  'P0001',
  'Technical module access administration not permitted',
  'Module Administrator cannot list staff-management data'
);

select throws_ok(
  $$select * from public.search_technical_accounts(
    'mobility.taxi',
    'Alice'
  )$$,
  'P0001',
  'Technical module access administration not permitted',
  'Module Administrator cannot search the account directory for access management'
);

select set_config(
  'request.jwt.claim.sub',
  'e1000000-0000-0000-0000-000000000006',
  true
);

select throws_ok(
  $$select * from public.search_technical_accounts(
    'mobility.taxi',
    'Alice'
  )$$,
  'P0001',
  'Technical module access administration not permitted',
  'Operations Administrator cannot use Technical staff search'
);

select set_config(
  'request.jwt.claim.sub',
  'e1000000-0000-0000-0000-000000000001',
  true
);

select ok(
  (
    select is_platform_admin
    from public.search_technical_accounts(
      'mobility.taxi',
      't21-platform@wantok.local'
    )
    limit 1
  ),
  'account search identifies global Technical Platform Administrators'
);

select throws_ok(
  $$select public.grant_technical_module_access(
    'e1000000-0000-0000-0000-000000000001'::uuid,
    'mobility.taxi',
    'tech_admin',
    null,
    null
  )$$,
  'P0001',
  'Technical Platform Administrators do not require module assignments',
  'global Technical Platform Administrators cannot receive redundant module assignments'
);

select set_config(
  'request.jwt.claim.sub',
  'e1000000-0000-0000-0000-000000000002',
  true
);

select is(
  public.revoke_technical_module_access(
    'e1000000-0000-0000-0000-000000000005'::uuid,
    'mobility.taxi'
  ),
  true,
  'Technical Administrator can revoke lower module access they are authorised to manage'
);

select is(
  (
    select count(*)::integer
    from public.list_technical_module_staff('mobility.taxi')
    where user_id = 'e1000000-0000-0000-0000-000000000005'::uuid
  ),
  0,
  'revoked module access disappears from the staff list'
);

select * from finish();
rollback;
