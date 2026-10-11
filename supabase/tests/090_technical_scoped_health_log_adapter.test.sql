begin;

create extension if not exists pgtap with schema extensions;
select plan(12);

insert into auth.users (
  id, aud, role, email, raw_user_meta_data, created_at, updated_at
) values
  ('b2400000-0000-0000-0000-000000000001', 'authenticated', 'authenticated',
   't24-auditor@wantok.local', '{"full_name":"T24 Audit Test"}'::jsonb, now(), now()),
  ('b2400000-0000-0000-0000-000000000002', 'authenticated', 'authenticated',
   't24-other@wantok.local', '{"full_name":"T24 Other Test"}'::jsonb, now(), now());

insert into public.technical_user_module_access (
  user_id, module_key, access_level_code
) values
  ('b2400000-0000-0000-0000-000000000001', 'mobility.taxi', 'tech_auditor'),
  ('b2400000-0000-0000-0000-000000000002', 'core.catalog', 'tech_auditor');

insert into public.technical_module_health_history (
  module_key, reported_status, effective_status,
  transition_reason, source_probe_key, summary, observed_at, recorded_at
)
select 'mobility.taxi', 'healthy', 'healthy',
       case when series.n = 1 then 'REDACTED; secret=TOKEN' else 'state_update' end,
       'secret_internal_probe', 'test-only secret material', now(),
       now() + make_interval(secs => series.n)
from generate_series(1, 36) as series(n);

select has_function(
  'public', 'list_technical_module_log_events',
  array['text','integer'],
  'dedicated scoped module log RPC exists'
);

select throws_ok(
  $$select count(*) from public.list_technical_module_log_events('mobility.taxi', 30)$$,
  'P0001', 'Authentication required',
  'unauthenticated direct invocation fails closed'
);

select ok(
  not has_function_privilege(
    'anon', 'public.list_technical_module_log_events(text,integer)', 'EXECUTE'
  ),
  'anonymous role cannot call log adapter'
);

set local role authenticated;
select set_config(
  'request.jwt.claim.sub', 'b2400000-0000-0000-0000-000000000001', true
);

select ok(
  public.has_technical_permission('mobility.taxi', 'module.view'),
  'auditor has the module view permission'
);

select ok(
  public.has_technical_permission('mobility.taxi', 'module.logs'),
  'auditor has the module log permission'
);

select is(
  (select count(*)::int
   from public.list_technical_module_log_events('mobility.taxi', 200)),
  30,
  'backend always caps results to 30'
);

select ok(
  (select bool_and(summary is null and source_probe_key is null)
   from public.list_technical_module_log_events('mobility.taxi', 30)),
  'raw summary and probe identifiers never leave the safe adapter'
);

select ok(
  (select bool_and(transition_reason ~ '^[a-z][a-z0-9_]{0,63}$')
   from public.list_technical_module_log_events('mobility.taxi', 30)),
  'transition reason is a restricted identifier, not free text'
);

select throws_ok(
  $$select count(*) from public.list_technical_module_log_events('core.catalog', 30)$$,
  'P0001', 'Technical module log permission required',
  'cross-module requests are denied'
);

reset role;
delete from public.technical_access_level_permissions
where access_level_code = 'tech_auditor' and permission_code = 'module.logs';

set local role authenticated;
select set_config(
  'request.jwt.claim.sub', 'b2400000-0000-0000-0000-000000000001', true
);

select ok(
  public.has_technical_permission('mobility.taxi', 'module.view')
  and not public.has_technical_permission('mobility.taxi', 'module.logs'),
  'view-only permission does not imply log permission'
);

select throws_ok(
  $$select count(*) from public.list_technical_module_log_events('mobility.taxi', 30)$$,
  'P0001', 'Technical module log permission required',
  'view-only user cannot call new log adapter'
);

reset role;
select ok(
  has_function_privilege(
    'authenticated', 'public.list_technical_module_log_events(text,integer)', 'EXECUTE'
  ),
  'function is executable only through the intended authenticated role'
);

select * from finish();
rollback;
