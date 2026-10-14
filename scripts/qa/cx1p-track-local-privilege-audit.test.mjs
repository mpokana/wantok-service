import test from 'node:test';
import assert from 'node:assert/strict';
import {sql,readOnlyShape,summarise} from './cx1p-track-local-privilege-audit.mjs';

const names=['service_bookings','service_quotes','service_reviews','service_categories',
  'provider_profiles','provider_services','provider_resources'];
const fake=()=>({
  engine:'170011',
  tables:names.map(name=>({name,owner:'postgres',rls:true,forced:false,
    anon_read:name==='service_categories',auth_read:true,
    auth_insert:false,auth_update:false,auth_delete:false})),
  columns:[
    {table_name:'service_bookings',name:'notes',auth_read:true,anon_read:false},
    {table_name:'service_bookings',name:'beneficiary_email',auth_read:true,anon_read:false},
    {table_name:'service_bookings',name:'id',auth_read:true,anon_read:false}
  ],
  policies:[
    {table_name:'service_bookings',name:'service_bookings_read_participants',cmd:'SELECT',
      has_customer_uid:true,has_provider_uid:true,has_admin_branch:true,has_unassigned_branch:false},
    {table_name:'service_bookings',name:'service_bookings_read_open_for_qualified_providers',
      cmd:'SELECT',has_customer_uid:false,has_provider_uid:false,
      has_admin_branch:false,has_unassigned_branch:true},
  ],
  functions:[{name:'is_admin',definer:true,owner:'postgres',owner_bypass_rls:true,
    anon_execute:true,auth_execute:true,settings:['search_path=public, auth']}],
  roles:[{name:'authenticated',rolsuper:false,rolbypassrls:false}],
});
test('1 fixed source SQL is catalog-only and READ ONLY',()=>assert.equal(readOnlyShape(sql),true));
test('2 all seven expected source tables are audited',()=>{
  const result=summarise(fake());
  assert.equal(result.tables_checked,7);
});
test('3 installed-style booking RLS and grant are not stage acceptance',()=>{
  const result=summarise(fake());
  assert.equal(result.booking_rls_enabled,true);
  assert.equal(result.booking_authenticated_select,true);
  assert.equal(result.parity_restored,false);
  assert.equal(result.real_gotrue_sessions_tested,false);
});
test('4 open-source policy OR branches independently represented',()=>{
  const result=summarise(fake());
  assert.deepEqual(result.booking_policy_classes,
    {customer:true,provider:true,admin:true,qualified_unassigned:true});
});
test('5 sensitive authenticated booking columns reported by name but never by value',()=>{
  const result=summarise(fake());
  assert.deepEqual(result.booking_private_column_names,['beneficiary_email','notes']);
  assert.equal(result.app_table_rows_read,false);
  assert.equal(result.credentials_or_tokens_read,false);
});
test('6 no fabricated candidate function installation',()=>{
  assert.equal(summarise(fake()).candidate_function_installed,false);
});
test('7 candidate installation in metadata is only inventoried',()=>{
  const x=fake();x.functions.push({name:'list_my_track_bookings_candidate'});
  const result=summarise(x);
  assert.equal(result.candidate_function_installed,true);
  assert.equal(result.private_track_route_approved,false);
});
test('8 disallowed app-table read fails before Docker launch',()=>{
  assert.throws(()=>readOnlyShape(sql.replace('FROM pg_class c','FROM public.service_bookings c')),
    /Application schema row reads prohibited/);
});
test('9 missing READ ONLY transaction is rejected',()=>{
  assert.throws(()=>readOnlyShape(sql.replace('BEGIN TRANSACTION READ ONLY;','BEGIN;')),
    /Must start READ ONLY/);
});
test('10 mutation in query is rejected',()=>{
  assert.throws(()=>readOnlyShape(sql.replace('COMMIT;', 'DELETE FROM public.service_bookings;\\nCOMMIT;')),
    /Mutation or export command prohibited/);
});
test('11 schema export is rejected',()=>{
  assert.throws(()=>readOnlyShape(sql.replace('COMMIT;', 'COPY public.service_bookings TO STDOUT;\\nCOMMIT;')),
    /Mutation or export command prohibited/);
});
test('12 insufficient catalog evidence fails closed',()=>{
  const x=fake();x.tables=x.tables.filter(y=>y.name!=='service_bookings');
  assert.throws(()=>summarise(x),/Mandatory installed marketplace table missing/);
});
test('13 policy changes are reported rather than falsely accepted',()=>{
  const x=fake();x.policies=[];
  const r=summarise(x);
  assert.equal(r.booking_policy_classes.customer,false);
  assert.equal(r.human_stage_signoffs,0);
});
test('14 no human/privacy approval can arise from analysis',()=>{
  const r=summarise(fake());
  for(const key of ['customer_column_projection_approved','private_track_route_approved',
    'productionApproved','real_actor_http_tested','schema_acl_snapshot_exported',
    'local_database_writes'])assert.equal(r[key],false,key);
});
test('15 anon booking access is surfaced, not silently hidden',()=>{
  const x=fake();x.tables[0].anon_read=true;
  assert.equal(summarise(x).booking_anonymous_select,true);
});
test('16 return does not reveal private record data even in test shape',()=>{
  const r=summarise(fake());
  assert.ok(!JSON.stringify(r).includes('synthetic-a@example.invalid'));
  assert.ok(!Object.hasOwn(r,'records'));
});
