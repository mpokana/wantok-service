begin;

create extension if not exists pgtap with schema extensions;
select plan(38);

insert into auth.users (
  id, aud, role, email, raw_user_meta_data, created_at, updated_at
) values
  ('d1000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated',
   'platform-admin@wantok.local', '{"full_name":"Platform Admin"}'::jsonb, now(), now()),
  ('d1000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated',
   'operations-admin@wantok.local', '{"full_name":"Operations Admin"}'::jsonb, now(), now()),
  ('d1000000-0000-0000-0000-000000000003', 'authenticated', 'authenticated',
   'tech-admin@wantok.local', '{"full_name":"Tech Admin"}'::jsonb, now(), now()),
  ('d1000000-0000-0000-0000-000000000004', 'authenticated', 'authenticated',
   'module-admin@wantok.local', '{"full_name":"Module Admin"}'::jsonb, now(), now()),
  ('d1000000-0000-0000-0000-000000000005', 'authenticated', 'authenticated',
   'tech-support@wantok.local', '{"full_name":"Tech Support"}'::jsonb, now(), now()),
  ('d1000000-0000-0000-0000-000000000006', 'authenticated', 'authenticated',
   'outsider@wantok.local', '{"full_name":"Outsider"}'::jsonb, now(), now());

update public.profiles
set is_admin = true
where id = 'd1000000-0000-0000-0000-000000000002'::uuid;

-- Keep last-platform-admin assertions deterministic even when a developer
-- already has local technical platform access. This entire test is rolled back.
delete from public.user_roles
where role_code = 'tech_platform_admin';

insert into public.user_roles (
  user_id, role_code, granted_by
) values (
  'd1000000-0000-0000-0000-000000000001',
  'tech_platform_admin',
  null
);

select is(
  (
    select count(*)::integer
    from public.app_roles
    where code in (
      'tech_platform_admin',
      'tech_admin',
      'tech_module_admin',
      'tech_support',
      'tech_auditor'
    )
  ),
  5,
  'five technical application roles are registered'
);

select is(
  (select count(*)::integer from public.technical_modules),
  19,
  'technical module registry contains initial nineteen modules'
);

select is(
  (select count(*)::integer from public.technical_permissions),
  14,
  'technical permission catalogue contains module and platform capabilities'
);

select ok(
  public.is_technical_platform_admin(
    'd1000000-0000-0000-0000-000000000001'::uuid
  ),
  'technical platform administrator role is recognised'
);

select ok(
  public.can_access_technical_console(
    'd1000000-0000-0000-0000-000000000001'::uuid
  ),
  'platform administrator can access technical console'
);

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  'd1000000-0000-0000-0000-000000000001',
  true
);

select is(
  (select count(*)::integer from public.list_my_technical_modules()),
  19,
  'platform administrator can see every technical module'
);

select ok(
  public.has_technical_permission(
    'mobility.taxi',
    'module.configure'
  ),
  'platform administrator has module configuration permission'
);

select ok(
  public.has_platform_permission('platform.audit'),
  'platform administrator has platform audit permission'
);

select lives_ok(
  $$select public.grant_technical_module_access(
    'd1000000-0000-0000-0000-000000000003'::uuid,
    'mobility.taxi',
    'tech_admin',
    null,
    'Taxi technical owner'
  )$$,
  'platform administrator can grant technical admin module access'
);

select is(
  public.effective_technical_access_level(
    'mobility.taxi',
    'd1000000-0000-0000-0000-000000000003'::uuid
  ),
  'tech_admin',
  'technical admin effective module level is resolved'
);

select ok(
  public.has_technical_permission(
    'mobility.taxi',
    'module.permissions',
    'd1000000-0000-0000-0000-000000000003'::uuid
  ),
  'technical admin receives module permission administration capability'
);

select lives_ok(
  $$select public.grant_technical_module_access(
    'd1000000-0000-0000-0000-000000000004'::uuid,
    'mobility.taxi',
    'tech_module_admin',
    null,
    'Taxi module administrator'
  )$$,
  'platform administrator can grant module administrator access'
);

select lives_ok(
  $$select public.grant_technical_module_access(
    'd1000000-0000-0000-0000-000000000005'::uuid,
    'mobility.taxi',
    'tech_support',
    null,
    'Taxi support'
  )$$,
  'platform administrator can grant support access'
);

select set_config(
  'request.jwt.claim.sub',
  'd1000000-0000-0000-0000-000000000003',
  true
);

select ok(
  public.can_access_technical_console(),
  'assigned technical administrator can access technical console'
);

select is(
  (select count(*)::integer from public.list_my_technical_modules()),
  1,
  'technical administrator sees only assigned modules'
);

select is(
  (select module_key from public.list_my_technical_modules()),
  'mobility.taxi',
  'technical administrator sees the assigned Taxi module'
);

select ok(
  public.has_technical_permission(
    'mobility.taxi',
    'module.configure'
  ),
  'technical administrator can configure assigned module'
);

select ok(
  not public.has_platform_permission('platform.audit'),
  'module-scoped technical administrator does not receive platform audit authority'
);

select throws_ok(
  $$select public.grant_technical_module_access(
    'd1000000-0000-0000-0000-000000000006'::uuid,
    'mobility.taxi',
    'tech_admin',
    null,
    null
  )$$,
  'P0001',
  'Technical module access administration not permitted',
  'technical administrator cannot grant an equal technical level'
);

select lives_ok(
  $$select public.set_technical_module_state(
    'mobility.taxi',
    null,
    true
  )$$,
  'technical administrator can enter assigned module maintenance mode'
);

select set_config(
  'request.jwt.claim.sub',
  'd1000000-0000-0000-0000-000000000004',
  true
);

select ok(
  public.has_technical_permission(
    'mobility.taxi',
    'module.maintenance'
  ),
  'module administrator has maintenance permission'
);

select lives_ok(
  $$select public.set_technical_module_state(
    'mobility.taxi',
    null,
    false
  )$$,
  'module administrator can leave maintenance mode'
);

select throws_ok(
  $$select public.grant_technical_module_access(
    'd1000000-0000-0000-0000-000000000006'::uuid,
    'mobility.taxi',
    'tech_auditor',
    null,
    null
  )$$,
  'P0001',
  'Technical module access administration not permitted',
  'module administrator cannot delegate technical access'
);

select set_config(
  'request.jwt.claim.sub',
  'd1000000-0000-0000-0000-000000000005',
  true
);

select ok(
  public.has_technical_permission(
    'mobility.taxi',
    'module.jobs'
  ),
  'technical support has module job permission'
);

select ok(
  not public.has_technical_permission(
    'mobility.taxi',
    'module.configure'
  ),
  'technical support cannot configure module'
);

select throws_ok(
  $$select public.set_technical_module_state(
    'mobility.taxi',
    false,
    null
  )$$,
  'P0001',
  'Module disable permission required',
  'technical support cannot disable a module'
);

select set_config(
  'request.jwt.claim.sub',
  'd1000000-0000-0000-0000-000000000006',
  true
);

select ok(
  not public.can_access_technical_console(),
  'unassigned ordinary user cannot access technical console'
);

select is(
  (select count(*)::integer from public.list_my_technical_modules()),
  0,
  'unassigned ordinary user receives no technical modules'
);

select throws_ok(
  $$insert into public.technical_user_module_access (
    user_id,
    module_key,
    access_level_code,
    granted_by
  ) values (
    'd1000000-0000-0000-0000-000000000006'::uuid,
    'mobility.taxi',
    'tech_admin',
    'd1000000-0000-0000-0000-000000000006'::uuid
  )$$,
  '42501',
  null,
  'authenticated users cannot directly grant module access'
);

select set_config(
  'request.jwt.claim.sub',
  'd1000000-0000-0000-0000-000000000002',
  true
);

select throws_ok(
  $$select public.grant_user_role(
    'd1000000-0000-0000-0000-000000000006'::uuid,
    'tech_support',
    null
  )$$,
  'P0001',
  'Technical platform admin access required',
  'Operations Admin cannot grant technical roles'
);

select lives_ok(
  $$select public.grant_user_role(
    'd1000000-0000-0000-0000-000000000006'::uuid,
    'support',
    null
  )$$,
  'Operations Admin can still grant ordinary operations/support roles'
);

select set_config(
  'request.jwt.claim.sub',
  'd1000000-0000-0000-0000-000000000001',
  true
);

select throws_ok(
  $$select public.grant_user_role(
    'd1000000-0000-0000-0000-000000000006'::uuid,
    'operations',
    null
  )$$,
  'P0001',
  'Operations admin access required',
  'Technical Platform Admin does not inherit Operations Admin role authority'
);

select lives_ok(
  $$select public.grant_user_role(
    'd1000000-0000-0000-0000-000000000006'::uuid,
    'tech_auditor',
    null
  )$$,
  'Technical Platform Admin can grant a technical role'
);

select ok(
  public.has_role(
    'tech_auditor',
    'd1000000-0000-0000-0000-000000000006'::uuid
  ),
  'granted technical role becomes active'
);

select is(
  public.revoke_technical_module_access(
    'd1000000-0000-0000-0000-000000000003'::uuid,
    'mobility.taxi'
  ),
  true,
  'platform administrator can revoke technical module access'
);

select throws_ok(
  $$select public.revoke_user_role(
    'd1000000-0000-0000-0000-000000000001'::uuid,
    'tech_platform_admin'
  )$$,
  'P0001',
  'Cannot revoke the last technical platform administrator',
  'last Technical Platform Administrator is protected'
);

reset role;

select ok(
  (
    select count(*) > 0
    from public.audit_events
    where action = 'technical_module_state_changed'
      and metadata ->> 'module_key' = 'mobility.taxi'
  ),
  'technical module state changes are audited'
);

select ok(
  not public.can_access_technical_console(
    'd1000000-0000-0000-0000-000000000003'::uuid
  ),
  'revoked technical administrator without technical role no longer has console access'
);

select * from finish();
rollback;
