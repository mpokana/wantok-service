begin;

create extension if not exists pgtap with schema extensions;
select plan(48);

insert into auth.users (
  id, aud, role, email, raw_user_meta_data, created_at, updated_at
) values
  ('a2300000-0000-0000-0000-000000000001', 'authenticated', 'authenticated',
   't23-platform@wantok.local', '{"full_name":"T23 Platform Admin"}'::jsonb, now(), now()),
  ('a2300000-0000-0000-0000-000000000002', 'authenticated', 'authenticated',
   't23-module-admin@wantok.local', '{"full_name":"T23 Module Admin"}'::jsonb, now(), now()),
  ('a2300000-0000-0000-0000-000000000003', 'authenticated', 'authenticated',
   't23-auditor@wantok.local', '{"full_name":"T23 Auditor"}'::jsonb, now(), now()),
  ('a2300000-0000-0000-0000-000000000004', 'authenticated', 'authenticated',
   't23-operations@wantok.local', '{"full_name":"T23 Operations"}'::jsonb, now(), now()),
  ('a2300000-0000-0000-0000-000000000005', 'authenticated', 'authenticated',
   't23-user@wantok.local', '{"full_name":"T23 Ordinary User"}'::jsonb, now(), now());

update public.profiles
set is_admin = true
where id = 'a2300000-0000-0000-0000-000000000004'::uuid;

delete from public.user_roles
where role_code = 'tech_platform_admin';

insert into public.user_roles (user_id, role_code, granted_by)
values (
  'a2300000-0000-0000-0000-000000000001',
  'tech_platform_admin',
  null
);

select has_table(
  'public', 'technical_module_dependencies',
  'module dependency registry exists'
);

select has_table(
  'public', 'technical_module_health_probes',
  'health probe registry exists'
);

select has_table(
  'public', 'technical_module_health_reports',
  'current health report store exists'
);

select has_table(
  'public', 'technical_module_health_state',
  'current aggregate health state exists'
);

select has_table(
  'public', 'technical_module_health_history',
  'health transition history exists'
);

select ok(
  (select count(*) from public.technical_module_dependencies) > 40,
  'initial dependency graph contains substantive module relationships'
);

select ok(
  exists (
    select 1
    from public.technical_module_dependencies
    where module_key = 'mobility.taxi'
      and depends_on_module_key = 'core.account'
      and dependency_type = 'required'
      and failure_effect = 'down'
  ),
  'Taxi has a required Accounts dependency'
);

select ok(
  exists (
    select 1
    from public.technical_module_dependencies
    where module_key = 'mobility.taxi'
      and depends_on_module_key = 'core.messaging'
      and dependency_type = 'optional'
      and failure_effect = 'degraded'
  ),
  'Taxi has optional Messaging degradation dependency'
);

select is(
  (
    select count(*)::integer
    from public.technical_module_dependencies
    where module_key = depends_on_module_key
  ),
  0,
  'dependency registry contains no direct self-dependencies'
);

select throws_ok(
  $$insert into public.technical_module_dependencies (
    module_key, depends_on_module_key, dependency_type, failure_effect
  ) values (
    'core.identity', 'core.account', 'required', 'down'
  )$$,
  'P0001',
  'Technical module dependency cycle detected',
  'dependency-cycle trigger rejects an indirect cycle'
);

select is(
  (
    select count(*)::integer
    from public.technical_module_health_probes
    where probe_key = 'control.state'
  ),
  19,
  'all nineteen modules receive the built-in control-state probe'
);

select is(
  (select count(*)::integer from public.technical_module_health_state),
  19,
  'all nineteen modules have an aggregate health-state row'
);

select is(
  public.technical_module_reported_health('payments'),
  'unknown',
  'disabled Wantok Pay reports unknown control-state health'
);

select is(
  public.technical_module_effective_health('payments'),
  'down',
  'disabled Wantok Pay is effectively down'
);

select is(
  public.technical_module_reported_health('mobility.taxi'),
  'healthy',
  'enabled Taxi reports healthy built-in control state'
);

select is(
  public.technical_module_effective_health('mobility.taxi'),
  'healthy',
  'Taxi is effectively healthy while required dependencies are available'
);

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  'a2300000-0000-0000-0000-000000000001',
  true
);

select is(
  (select count(*)::integer from public.list_my_technical_modules()),
  19,
  'platform administrator sees all nineteen modules with effective health'
);

select is(
  (
    select effective_status
    from public.get_technical_module_health('mobility.taxi')
  ),
  'healthy',
  'platform administrator can read Taxi health detail'
);

select is(
  (
    select count(*)::integer
    from public.list_technical_module_health_probes('mobility.taxi')
  ),
  1,
  'Taxi currently exposes one registered built-in health probe'
);

select is(
  (
    select count(*)::integer
    from public.list_technical_module_dependencies('mobility.taxi')
  ),
  5,
  'Taxi exposes five direct dependencies'
);

select ok(
  (
    public.get_technical_module_state_impact('core.catalog')
      ->> 'impacted_count'
  )::integer > 0,
  'Service Catalogue impact preview reports dependent modules'
);

select lives_ok(
  $$select public.grant_technical_module_access(
    'a2300000-0000-0000-0000-000000000002'::uuid,
    'mobility.taxi',
    'tech_module_admin',
    null,
    'T2.3 Taxi module administrator'
  )$$,
  'platform administrator assigns Taxi Module Administrator'
);

select lives_ok(
  $$select public.grant_technical_module_access(
    'a2300000-0000-0000-0000-000000000003'::uuid,
    'mobility.taxi',
    'tech_auditor',
    null,
    'T2.3 Taxi technical auditor'
  )$$,
  'platform administrator assigns Taxi Technical Auditor'
);

select lives_ok(
  $$select public.set_technical_module_state(
    'core.catalog', false, null
  )$$,
  'platform administrator can disable Service Catalogue for dependency test'
);

select is(
  (
    select effective_status
    from public.get_technical_module_health('mobility.taxi')
  ),
  'down',
  'required disabled Service Catalogue makes Taxi effectively down'
);

select is(
  (
    select effective_status
    from public.get_technical_module_health('mobility.taxi')
  ),
  'down',
  'Taxi aggregate health API reflects dependency unavailability'
);

select ok(
  exists (
    select 1
    from public.list_technical_module_health_history('mobility.taxi', 50)
    where effective_status = 'down'
  ),
  'Taxi history API records dependency-driven down transition'
);

select ok(
  exists (
    select 1
    from jsonb_array_elements(
      public.get_technical_module_state_impact('core.catalog')
        -> 'visible_impacted'
    ) item
    where item ->> 'module_key' = 'mobility.taxi'
  ),
  'platform impact preview identifies Taxi as affected by Service Catalogue'
);

select lives_ok(
  $$select public.set_technical_module_state(
    'core.catalog', true, null
  )$$,
  'platform administrator re-enables Service Catalogue'
);

select is(
  (
    select effective_status
    from public.get_technical_module_health('mobility.taxi')
  ),
  'healthy',
  'Taxi returns healthy after required dependency recovers'
);

select lives_ok(
  $$select public.set_technical_module_state(
    'core.catalog', null, true
  )$$,
  'platform administrator places Service Catalogue into maintenance'
);

select is(
  (
    select effective_status
    from public.get_technical_module_health('mobility.taxi')
  ),
  'degraded',
  'required dependency maintenance degrades Taxi effective health'
);

select lives_ok(
  $$select public.set_technical_module_state(
    'core.catalog', null, false
  )$$,
  'platform administrator restores Service Catalogue from maintenance'
);

select set_config(
  'request.jwt.claim.sub',
  'a2300000-0000-0000-0000-000000000002',
  true
);

select is(
  (
    select effective_status
    from public.get_technical_module_health('mobility.taxi')
  ),
  'healthy',
  'Taxi Module Administrator can read assigned module health'
);

select is(
  (
    select count(*)::integer
    from public.list_technical_module_dependencies('mobility.taxi')
  ),
  5,
  'Taxi Module Administrator can read assigned module dependency summary'
);

select ok(
  not exists (
    select 1
    from public.list_technical_module_dependencies('mobility.taxi')
    where not is_visible
      and (
        dependency_module_key is not null
        or dependency_name is not null
        or description is not null
      )
  ),
  'dependencies outside technical scope do not reveal identity or description'
);

select ok(
  (
    select count(*)
    from public.list_technical_module_health_history('mobility.taxi', 50)
  ) > 0,
  'Taxi Module Administrator can read assigned module health history'
);

select ok(
  (
    select can_run
    from public.list_technical_module_health_probes('mobility.taxi')
    where probe_key = 'control.state'
  ),
  'Taxi Module Administrator sees the built-in probe as runnable'
);

select lives_ok(
  $$select * from public.run_technical_module_health_probe(
    'mobility.taxi', 'control.state'
  )$$,
  'Taxi Module Administrator can run an authorised built-in health probe'
);

select throws_ok(
  $$select * from public.get_technical_module_health('core.catalog')$$,
  'P0001',
  'Technical module view permission required',
  'module-scoped administrator cannot read unrelated module health'
);

select throws_ok(
  $$select public.get_technical_module_state_impact('core.catalog')$$,
  'P0001',
  'Technical module view permission required',
  'module-scoped administrator cannot inspect unrelated dependency impact'
);

select set_config(
  'request.jwt.claim.sub',
  'a2300000-0000-0000-0000-000000000003',
  true
);

select ok(
  not (
    select can_run
    from public.list_technical_module_health_probes('mobility.taxi')
    where probe_key = 'control.state'
  ),
  'Technical Auditor sees health probes as read-only'
);

select throws_ok(
  $$select * from public.run_technical_module_health_probe(
    'mobility.taxi', 'control.state'
  )$$,
  'P0001',
  'Technical module health-run permission required',
  'Technical Auditor cannot run health probes'
);

select is(
  (
    select count(*)::integer
    from public.list_technical_module_dependencies('mobility.taxi')
  ),
  5,
  'Technical Auditor can read assigned module dependencies'
);

select set_config(
  'request.jwt.claim.sub',
  'a2300000-0000-0000-0000-000000000004',
  true
);

select throws_ok(
  $$select * from public.get_technical_module_health('mobility.taxi')$$,
  'P0001',
  'Technical module view permission required',
  'Operations Admin cannot read Technical module health'
);

select set_config(
  'request.jwt.claim.sub',
  'a2300000-0000-0000-0000-000000000005',
  true
);

select throws_ok(
  $$select * from public.get_technical_module_health('mobility.taxi')$$,
  'P0001',
  'Technical module view permission required',
  'ordinary user cannot read Technical module health'
);

select throws_ok(
  $$select count(*) from public.technical_module_health_reports$$,
  '42501',
  null,
  'authenticated users cannot directly read raw health-report tables'
);

select throws_ok(
  $$insert into public.technical_module_health_reports (
    module_key, probe_key, status, details
  ) values (
    'mobility.taxi', 'control.state', 'down', '{}'::jsonb
  )$$,
  '42501',
  null,
  'authenticated users cannot directly write raw health reports'
);

select * from finish();
rollback;
