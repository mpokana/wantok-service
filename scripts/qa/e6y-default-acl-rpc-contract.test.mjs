import test from 'node:test';
import assert from 'node:assert/strict';
import {readStaticApiConfig,evaluate} from './e6y-default-acl-rpc-contract.mjs';

const baseConfig=['project_id = "synthetic"','[api]','enabled = true',
  'schemas = ["public", "graphql_public"]','extra_search_path = ["public"]',
  '# auto_expose_new_tables = true','[db]','port=54322'].join('\n');
function synthetic(){
  const names=['write_audit_event','enqueue_notification','audit_status_change',
    ...Array.from({length:11},(_,i)=>'synthetic_function_'+i)];
  const functions=names.map(name=>({
    name,signature:'public.'+name+'()',return_type:name==='audit_status_change'?'trigger':'void',
    owner:'postgres',definer:true,owner_bypassrls:true,anon_execute:true,
    authenticated_execute:true,public_execute:name==='audit_status_change',
    service_execute:true,default_args:0
  }));
  const default_acl_grants=[
    ...['anon','authenticated'].flatMap(grantee=>[
      {owner:'postgres',schema_name:'public',object_type:'f',grantee,privilege_type:'EXECUTE'},
      {owner:'postgres',schema_name:'public',object_type:'r',grantee,privilege_type:'SELECT'},
      {owner:'postgres',schema_name:'public',object_type:'r',grantee,privilege_type:'TRUNCATE'},
      {owner:'postgres',schema_name:'public',object_type:'S',grantee,privilege_type:'USAGE'}
    ])];
  return {functions,default_acl_records:3,default_acl_grants,default_acl_summary:[]};
}
const conf=()=>readStaticApiConfig(baseConfig);
test('checked-in public API schema is classified but runtime verification remains false',()=>{
  const c=conf();
  assert.deepEqual(c.checked_in_schemas,['public','graphql_public']);
  assert.equal(c.auto_expose_new_tables,'unset_config_comment_says_default_true');
  assert.equal(c.runtime_postgrest_config_verified,false);
});
test('explicit auto exposure false is parsed and does not rewrite current grants',()=>{
 const c=readStaticApiConfig(baseConfig.replace('# auto_expose_new_tables = true',
   'auto_expose_new_tables = false'));
 assert.equal(c.auto_expose_new_tables,false);
 assert.deepEqual(c.checked_in_schemas,['public','graphql_public']);
});
test('missing api section fails closed',()=>{
 assert.throws(()=>readStaticApiConfig('[db]\nport=54322'),/missing/);
});
test('unknown api auto exposure value fails closed',()=>{
 assert.throws(()=>readStaticApiConfig(baseConfig.replace('# auto_expose_new_tables = true',
   'auto_expose_new_tables = arbitrary')),/Unexpected/);
});
test('trigger return is not counted as normal RPC review candidate',()=>{
 const result=evaluate(synthetic(),conf());
 assert.equal(result.totals.selected_functions,14);
 assert.equal(result.totals.trigger_return_functions,1);
 assert.equal(result.totals.potential_nontrigger_api_candidates,13);
 assert.equal(result.function_candidates.find(x=>x.name==='audit_status_change').candidate_for_rest_review,false);
 assert.equal(result.postgrest_route_tested,false);
 assert.equal(result.productionApproved,false);
});
test('future object default ACL is separate from existing EXECUTE and includes table TRUNCATE',()=>{
 const r=evaluate(synthetic(),conf());
 assert.equal(r.totals.function_future_default_grants_to_client_roles,2);
 assert.equal(r.totals.future_table_truncate_grants_to_client_roles,2);
 assert.equal(r.totals.table_future_default_privilege_entries_to_client_roles,4);
 assert.equal(r.totals.sequence_future_default_privilege_entries_to_client_roles,2);
 assert.equal(r.risk_flags.broad_future_public_table_grants_present,true);
});
test('no public in checked-in API means zero potential candidates without denying SQL EXECUTE',()=>{
 const c=readStaticApiConfig(baseConfig.replace('"public", ',''));
 const r=evaluate(synthetic(),c);
 assert.equal(r.totals.sql_anon_executable,14);
 assert.equal(r.totals.potential_nontrigger_api_candidates,0);
});
test('writer permission removal lowers open flag but never authorises deployment',()=>{
 const m=synthetic();
 const f=m.functions.find(x=>x.name==='write_audit_event');
 f.anon_execute=false;f.authenticated_execute=false;
 const r=evaluate(m,conf());
 assert.equal(r.totals.untrusted_sql_executable_internal_writers,1);
 assert.equal(r.risk_flags.e6o_01_local_writer_execute_exposure,false);
 assert.equal(r.independent_G7G8_acceptance,false);
});
test('overloaded or duplicate signatures fail closed',()=>{
 const m=synthetic();m.functions[1].signature=m.functions[0].signature;
 assert.throws(()=>evaluate(m,conf()),/Duplicate/);
});
test('missing expected trigger fails closed',()=>{
 const m=synthetic();m.functions.find(x=>x.name==='audit_status_change').return_type='void';
 assert.throws(()=>evaluate(m,conf()),/misclassified/);
});
test('wrong count fails closed instead of reporting incomplete scope',()=>{
 const m=synthetic();m.functions.pop();
 assert.throws(()=>evaluate(m,conf()),/Unexpected/);
});
test('static API disabled retains SQL permission findings without claiming REST candidates',()=>{
 const c=readStaticApiConfig(baseConfig.replace('enabled = true','enabled = false'));
 const r=evaluate(synthetic(),c);
 assert.equal(r.totals.potential_nontrigger_api_candidates,0);
 assert.equal(r.risk_flags.e6o_01_local_writer_execute_exposure,true);
});
