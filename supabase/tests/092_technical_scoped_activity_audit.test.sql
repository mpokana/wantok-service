begin;
create extension if not exists pgtap with schema extensions;
select plan(14);

insert into auth.users (
 id, aud, role, email, raw_user_meta_data, created_at, updated_at
) values
 ('b2420000-0000-0000-0000-000000000001','authenticated','authenticated',
  't24-activity-reader@wantok.local','{"full_name":"Activity Reader"}'::jsonb,now(),now()),
 ('b2420000-0000-0000-0000-000000000002','authenticated','authenticated',
  't24-other-module@wantok.local','{"full_name":"Other Module"}'::jsonb,now(),now());

insert into public.technical_user_module_access (user_id,module_key,access_level_code)
values
 ('b2420000-0000-0000-0000-000000000001','core.catalog','tech_auditor'),
 ('b2420000-0000-0000-0000-000000000002','core.messaging','tech_auditor');

insert into public.audit_events (
 actor_user_id,action,entity_type,metadata
)
select null::uuid,'technical_module_state_changed','technical_module',
  jsonb_build_object('module_key','core.catalog',
    'private_email','do-not-disclose@example.invalid','private_secret','SECRET_AUDIT_STRING')
from generate_series(1,39);

insert into public.audit_events (actor_user_id,action,entity_type,metadata)
values
 (null,'technical_module_configuration_changed','technical_module_configuration',
  '{"module_key":"core.catalog","private_secret":"SECRET_B"}'::jsonb),
 (null,'technical_module_access_granted','technical_module_access',
  '{"module_key":"core.messaging","private_target":"NOT_FOR_CATALOG"}'::jsonb),
 (null,'status_changed','provider',
  '{"module_key":"core.catalog","private_customer":"DO_NOT_DISCLOSE"}'::jsonb),
 (null,'technical_module_state_changed','provider',
  '{"module_key":"core.catalog"}'::jsonb),
 (null,'unapproved_technical_action','technical_module',
  '{"module_key":"core.catalog"}'::jsonb);

select has_function(
 'public','list_technical_module_activity',array['text','integer'],
 'scoped technical activity RPC exists'
);

select throws_ok(
 $$select count(*) from public.list_technical_module_activity('core.catalog',30)$$,
 'P0001','Authentication required',
 'anonymous direct RPC rejects'
);

select ok(
 not has_function_privilege('anon',
   'public.list_technical_module_activity(text,integer)','EXECUTE'),
 'anonymous role has no execution'
);

set local role authenticated;
select set_config(
 'request.jwt.claim.sub','b2420000-0000-0000-0000-000000000001',true
);

select ok(
 public.has_technical_permission('core.catalog','module.view')
 and public.has_technical_permission('core.catalog','module.logs'),
 'authorised scoped auditor has both required capabilities'
);

select is(
 (select count(*)::int from public.list_technical_module_activity('core.catalog',200)),
 30,'server caps latest activity at 30 even when requesting 200'
);

select ok(
 (select bool_and(action_code IN (
   'technical_module_state_changed',
   'technical_module_configuration_changed',
   'technical_module_access_granted',
   'technical_module_access_revoked'
 )) from public.list_technical_module_activity('core.catalog',30)),
 'all emitted event codes are approved technical types'
);

select ok(
 (select bool_and((select count(*) from jsonb_object_keys(to_jsonb(a)))=3)
  from public.list_technical_module_activity('core.catalog',30) a),
 'exactly three fields, no actor, target, module metadata or message text'
);

select ok(
 (select count(*)=0 from public.list_technical_module_activity('core.catalog',30)
  where action_code='status_changed' or action_code='unapproved_technical_action'),
 'operational records and arbitrary technical action names are excluded'
);

select is(
 (select count(*)::int from public.list_technical_module_activity('core.catalog',1)),
 1,'server supports a smaller bounded result'
);

select throws_ok(
 $$select count(*) from public.list_technical_module_activity('core.messaging',30)$$,
 'P0001','Technical module activity permission required',
 'module reader cannot inspect another module'
);

reset role;
delete from public.technical_access_level_permissions
 where access_level_code='tech_auditor' and permission_code='module.logs';

set local role authenticated;
select set_config(
 'request.jwt.claim.sub','b2420000-0000-0000-0000-000000000001',true
);

select ok(
 public.has_technical_permission('core.catalog','module.view')
 and not public.has_technical_permission('core.catalog','module.logs'),
 'removing logs capability leaves only module view'
);

select throws_ok(
 $$select count(*) from public.list_technical_module_activity('core.catalog',30)$$,
 'P0001','Technical module activity permission required',
 'view alone cannot read activity'
);

select set_config(
 'request.jwt.claim.sub','b2420000-0000-0000-0000-000000000002',true
);
select throws_ok(
 $$select count(*) from public.list_technical_module_activity('core.catalog',30)$$,
 'P0001','Technical module activity permission required',
 'unrelated module-assigned user denied'
);

reset role;
select ok(
 has_function_privilege('authenticated',
   'public.list_technical_module_activity(text,integer)','EXECUTE'),
 'only intended authenticated role can execute function'
);

select * from finish();
rollback;
