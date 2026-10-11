begin;
create extension if not exists pgtap with schema extensions;
select plan(19);

select has_table('public','technical_log_source_contracts',
 'Future central log source contract table is defined');
select has_function('public','get_technical_central_log_readiness',
 array['text'],'Scoped central log source readiness RPC exists');
select ok(not has_table_privilege('authenticated',
 'public.technical_log_source_contracts','SELECT'),
 'Contract provenance registry not browsable');
select ok(not has_table_privilege('authenticated',
 'public.technical_log_source_contracts','INSERT'),
 'Browser cannot assert its own source registry');
select ok(not has_table_privilege('anon',
 'public.technical_log_source_contracts','SELECT'),
 'Anonymous caller cannot enumerate contracts');
select ok(has_table_privilege('service_role',
 'public.technical_log_source_contracts','INSERT'),
 'Trusted role alone can register source metadata');
select ok(not has_function_privilege('anon',
 'public.get_technical_central_log_readiness(text)','EXECUTE'),
 'Anonymous role cannot call central log readiness');

insert into auth.users(id,aud,role,email,created_at,updated_at)
values
 ('b2430000-0000-0000-0000-000000000001','authenticated','authenticated',
  'log-contract-scope-a@wantok.invalid',now(),now()),
 ('b2430000-0000-0000-0000-000000000002','authenticated','authenticated',
  'log-contract-scope-b@wantok.invalid',now(),now());
insert into public.technical_user_module_access
 (user_id,module_key,access_level_code)
values
 ('b2430000-0000-0000-0000-000000000001','core.catalog','tech_auditor'),
 ('b2430000-0000-0000-0000-000000000002','core.messaging','tech_auditor');

insert into public.technical_log_source_contracts(
 source_key,module_key,source_kind,provenance_ticket,retention_days)
values
 ('catalog-app','core.catalog','application','SEC-TEST-CATALOG-2026',7),
 ('messaging-worker','core.messaging','worker','SEC-TEST-MSG-2026',14);

select throws_ok($$insert into public.technical_log_source_contracts(
 source_key,module_key,source_kind,provenance_ticket,retention_days)
 values('bad-config','core.catalog','application','password=do-not-store',7)$$,
 '23514','new row for relation "technical_log_source_contracts" violates check constraint "technical_log_source_contracts_provenance_ticket_check"',
 'Provenance is a safe ticket, not free-text secrets');
select throws_ok($$update public.technical_log_source_contracts
 set connection_state='connected' where source_key='catalog-app'$$,
 '23514','new row for relation "technical_log_source_contracts" violates check constraint "technical_log_source_contracts_connection_state_check"',
 'Trusted registration cannot assert collector connectivity');
-- All contract records must remain disconnected even when registered.
select is((select count(*)::integer from public.technical_log_source_contracts
 where connection_state='not_connected'),2,
 'Newly registered source metadata is never treated as connected');

set local role authenticated;
select set_config('request.jwt.claim.sub',
 'b2430000-0000-0000-0000-000000000001',true);
select is(
 (public.get_technical_central_log_readiness('core.catalog')
   ->>'registered_source_contracts')::integer,1,
 'Authorised module observer gets own module contract count only');
select is(
 public.get_technical_central_log_readiness('core.catalog')
   ->>'connection_state','not_connected',
 'Server truthfully reports collector is not connected');
select ok(public.get_technical_central_log_readiness('core.catalog')::text
 not like '%SEC-TEST%', 'Provenance ticket remains private');
select ok(
 (public.get_technical_central_log_readiness('core.catalog')
    ->>'central_logs_available')::boolean=false
 and (public.get_technical_central_log_readiness('core.catalog')
    ->>'collector_verified')::boolean=false,
 'No registry row can imply verified or queryable central logs');
select is(
 (select count(*)::integer from jsonb_object_keys(
  public.get_technical_central_log_readiness('core.catalog'))),7,
 'Only seven safe and fixed metadata keys returned');
select throws_ok($$select public.get_technical_central_log_readiness('core.messaging')$$,
 '42501','Technical module central log permission required',
 'Other module contract count remains inaccessible');
select throws_ok($$select * from public.technical_log_source_contracts$$,
 '42501','permission denied for table technical_log_source_contracts',
 'Even permitted viewer cannot read provenance or source keys');

select set_config('request.jwt.claim.sub',
 'b2430000-0000-0000-0000-000000000002',true);
select is((public.get_technical_central_log_readiness('core.messaging')
 ->>'registered_source_contracts')::integer,1,
 'Separate authorised module reader only sees own count');

reset role;
delete from public.technical_access_level_permissions
 where access_level_code='tech_auditor'
 and permission_code='module.logs';
set local role authenticated;
select set_config('request.jwt.claim.sub',
 'b2430000-0000-0000-0000-000000000001',true);
select throws_ok($$select public.get_technical_central_log_readiness('core.catalog')$$,
 '42501','Technical module central log permission required',
 'Removing module.logs immediately revokes readiness lookup');
reset role;
select * from finish();
rollback;
