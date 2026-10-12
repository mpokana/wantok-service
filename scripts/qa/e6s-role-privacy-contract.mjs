/**
 * E6S role-helper contract validation. Source-only, or optionally an EAGLT02
 * read-only local pg_catalog comparison. No HTTP auth, user data, or SQL writes.
 * A validated PROPOSED contract must never be represented as G7/G8 approval.
 */
import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {spawnSync} from 'node:child_process';
import assert from 'node:assert/strict';

const arg=process.argv[2]??'--source-only';
if(!['--source-only','--local'].includes(arg)||process.argv.length>3){
 console.error('Usage: node scripts/qa/e6s-role-privacy-contract.mjs [--source-only|--local]');
 process.exit(2);
}
const file=resolve('docs/E6S_ROLE_PRIVACY_CONTRACT_PROPOSAL_20261012.json');
const data=JSON.parse(readFileSync(file,'utf8'));
assert.equal(data.status,'PROPOSED_FOR_INDEPENDENT_G8_REVIEW');
assert.equal(data.human_gates_approved,0);
assert.equal(data.human_gate_status,'ALL_BLOCKED');
assert.equal(data.production_approved,false);
assert.equal(data.persistent_db_changes_authorised,false);
assert.equal(data.public_web_api_exposure_verified,false);
assert.equal(data.real_gotrue_tests_witnessed,0);
assert.equal(data.functions.length,8);
assert.equal(data.review_decisions.length,5);
assert.equal(new Set(data.functions.map(x=>x.name)).size,8);
assert.equal(new Set(data.review_decisions.map(x=>x.id)).size,5);
assert.ok(data.review_decisions.every(x=>x.status==='NOT_SUPPLIED'));
assert.ok(data.functions.every(x=>x.schema==='public' &&
 x.change_status==='NO_SQL_CHANGE_UNTIL_INDEPENDENT_G8' &&
 x.real_postgrest_test_status==='NOT_EXECUTED' &&
 x.suggested_external_anonymous==='DENY_CROSS_SUBJECT_QUERY' &&
 x.suggested_external_authenticated==='SELF_ONLY_UNLESS_DELEGATED_AND_APPROVED'));
const expected=new Map(data.functions.map(f=>[f.name,f]));
const report={
 title:'E6S proposed role-helper privacy contract — NO human approval',
 mode:arg,selected_helpers:8,independent_decisions_pending:data.review_decisions.length,
 formal_gates_approved:0,source_contract_shape_valid:true,
 shared_database_writes:false,real_postgrest_tested:false,
 browser_or_gotrue_tested:false,production_approved:false
};
if(arg==='--local'){
 const env={...process.env};
 if(process.platform==='win32')env.DOCKER_HOST='npipe:////./pipe/dockerDesktopLinuxEngine';
 const sql=String.raw`
BEGIN TRANSACTION READ ONLY;
SELECT coalesce(jsonb_agg(to_jsonb(z) ORDER BY z.name),'[]'::jsonb)::text
FROM (
 SELECT p.proname::text AS name,
  oidvectortypes(p.proargtypes) AS args,
  pg_get_function_result(p.oid) AS result,
  pg_get_userbyid(p.proowner) AS owner,
  p.prosecdef AS security_definer,
  coalesce(array_to_string(p.proconfig,';'),'') AS function_settings,
  has_function_privilege('anon',p.oid,'EXECUTE') AS anon_execute,
  has_function_privilege('authenticated',p.oid,'EXECUTE') AS authenticated_execute,
  has_function_privilege('service_role',p.oid,'EXECUTE') AS service_execute
 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
 WHERE n.nspname='public'
 AND p.proname IN(
 'has_role','is_admin','is_technical_platform_admin',
 'has_platform_permission','has_technical_permission',
 'effective_technical_access_level','can_access_technical_console',
 'can_manage_technical_module_access')
) z;
COMMIT;
`;
 assert.ok(sql.includes('BEGIN TRANSACTION READ ONLY;'));
 const result=spawnSync('docker',[
  'exec','-i','supabase_db_wantok-service','psql','-X','-U','postgres',
  '-d','postgres','-At','-v','ON_ERROR_STOP=1','-P','pager=off'
 ],{env,input:sql,encoding:'utf8',timeout:30000,maxBuffer:1000000});
 if(result.status!==0){
  console.error('Read-only local metadata check failed:',(result.stderr??'').slice(-500));
  process.exit(1);
 }
 const line=(result.stdout??'').split(/\r?\n/).find(x=>x.startsWith('['));
 assert.ok(line,'No PostgreSQL metadata JSON');
 const rows=JSON.parse(line);
 assert.equal(rows.length,8,'Local selected-function count differs');
 for(const r of rows){
  const item=expected.get(r.name);
  assert.ok(item,'Unexpected function '+r.name);
  assert.equal(r.args.replace(/\s+/g,''),item.identity_arg_types.replace(/\s+/g,''),'Signature drift: '+r.name);
  assert.equal(r.result,item.expected_return,'Return drift: '+r.name);
  assert.equal(r.security_definer,true,'Owner-mode drift: '+r.name);
 }
 report.local_catalog={
  functions_checked:rows.length,
  observed_owner_names:[...new Set(rows.map(x=>x.owner))],
  anon_execute:rows.filter(x=>x.anon_execute).length,
  authenticated_execute:rows.filter(x=>x.authenticated_execute).length,
  service_execute:rows.filter(x=>x.service_execute).length,
  no_trailing_pg_temp:rows.filter(x=>!x.function_settings.toLowerCase().split('=')[1]?.split(',').at(-1)?.trim().includes('pg_temp')).length,
  observed_grants_differ_from_source_contract:rows.filter(x=>{
   const intended=expected.get(x.name).observed_local_effective_exec;
   return x.anon_execute!==intended.anon || x.authenticated_execute!==intended.authenticated ||
    x.service_execute!==intended.service_role;
  }).map(x=>x.name),
  note:'Current authorised local SQL metadata, NOT a verified public PostgREST route or production permissions.'
 };
}
console.log(JSON.stringify(report,null,2));
