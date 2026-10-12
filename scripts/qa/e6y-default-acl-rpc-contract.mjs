/**
 * E6Y: read-only local SQL grant/default-privilege and *candidate* RPC exposure.
 * No web requests, users, application data, credentials or persistent writes.
 * Do not interpret SQL permissions as actual PostgREST routing or exploitable RPCs.
 */
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import {resolve} from 'node:path';

const names=['write_audit_event','enqueue_notification','audit_status_change',
  'grant_user_role','revoke_user_role','set_technical_module_state',
  'grant_technical_module_access','revoke_technical_module_access',
  'update_technical_module_configuration','admin_set_public_services_enabled',
  'save_wantok_branding_draft','publish_wantok_branding_draft',
  'restore_wantok_branding_version','manage_service_category'];

export function readStaticApiConfig(source) {
  const lines=source.split(/\r?\n/);
  const start=lines.findIndex(line=>line.trim()==='[api]');
  assert.ok(start>=0,'[api] section is missing from checked-in Supabase config');
  const rest=lines.slice(start+1);
  const next=rest.findIndex(line=>/^\[[^\]]+\]$/.test(line.trim()));
  const apiSection=(next>=0?rest.slice(0,next):rest).join('\n');
  const active=apiSection.split(/\r?\n/).map(s=>s.trim()).filter(s=>s&&!s.startsWith('#'));
  const entries=Object.fromEntries(active.map(line=>{
    const idx=line.indexOf('=');
    if(idx<0)return [line,null];
    return [line.slice(0,idx).trim(),line.slice(idx+1).trim()];
  }));
  const match=/^\[(.*?)\]$/.exec(entries.schemas||'');
  assert.ok(match,'Unexpected API schemas syntax');
  const schemas=[...match[1].matchAll(/"([^"]+)"/g)].map(m=>m[1]);
  assert.ok(schemas.length,'No exposed schemas parsed');
  const exposure=entries.auto_expose_new_tables;
  assert.ok(exposure===undefined||exposure==='true'||exposure==='false',
    'Unexpected auto-exposure setting');
  return {checked_in_schemas:schemas,
    checked_in_api_enabled:entries.enabled==='true',
    auto_expose_new_tables:exposure===undefined?'unset_config_comment_says_default_true':
      exposure==='true',
    source_only:true,
    runtime_postgrest_config_verified:false};
}
export function evaluate(metadata,config) {
  assert.ok(metadata&&Array.isArray(metadata.functions)&&Array.isArray(metadata.default_acl_grants),
    'Invalid read-only SQL catalog response');
  const f=metadata.functions;
  assert.equal(f.length,14,'Unexpected selected local function count');
  const unique=new Set(f.map(x=>x.signature));
  assert.equal(unique.size,f.length,'Duplicate signatures or overload mismatch');
  const configured=config.checked_in_api_enabled&&config.checked_in_schemas.includes('public');
  const candidates=f.map(x=>{
    const trigger=x.return_type==='trigger';
    return {
      name:x.name,signature:x.signature,return_type:x.return_type,
      postgres_owner:x.owner==='postgres',definer:x.definer,
      owner_bypassrls:x.owner_bypassrls,
      anon_sql_execute:x.anon_execute,
      authenticated_sql_execute:x.authenticated_execute,
      public_sql_execute:x.public_execute,
      service_sql_execute:x.service_execute,
      default_args:x.default_args,
      candidate_for_rest_review:configured&&!trigger&&(x.anon_execute||x.authenticated_execute),
      direct_rest_reachability_tested:false,
      caller_authorisation_tested:false
    };
  });
  const byName=new Map(candidates.map(f=>[f.name,f]));
  for(const w of ['write_audit_event','enqueue_notification']){
    assert.ok(byName.has(w),'Missing shared writer '+w);
  }
  assert.ok(byName.get('audit_status_change').return_type==='trigger',
    'Status trigger misclassified');
  const privilegedWriters=['write_audit_event','enqueue_notification'].filter(w=>
    byName.get(w).anon_sql_execute||byName.get(w).authenticated_sql_execute);
  const publicFutureDefaultGrants=metadata.default_acl_grants.filter(x=>
    x.schema_name==='public'&&x.owner==='postgres'&&
    x.object_type==='f'&&x.privilege_type==='EXECUTE'&&
    ['anon','authenticated','PUBLIC'].includes(x.grantee));
  const futureUntrustedGrants=metadata.default_acl_grants.filter(x=>
    x.schema_name==='public'&&x.owner==='postgres'&&
    ['anon','authenticated','PUBLIC'].includes(x.grantee));
  const futureTableGrants=futureUntrustedGrants.filter(x=>x.object_type==='r');
  const futureSequenceGrants=futureUntrustedGrants.filter(x=>x.object_type==='S');
  const totals={
    selected_functions:candidates.length,
    sql_anon_executable:candidates.filter(x=>x.anon_sql_execute).length,
    sql_authenticated_executable:candidates.filter(x=>x.authenticated_sql_execute).length,
    trigger_return_functions:candidates.filter(x=>x.return_type==='trigger').length,
    potential_nontrigger_api_candidates:candidates.filter(x=>x.candidate_for_rest_review).length,
    untrusted_sql_executable_internal_writers:privilegedWriters.length,
    default_acl_records:metadata.default_acl_records,
    function_future_default_grants_to_client_roles:publicFutureDefaultGrants.length,
    table_future_default_privilege_entries_to_client_roles:futureTableGrants.length,
    sequence_future_default_privilege_entries_to_client_roles:futureSequenceGrants.length,
    future_table_truncate_grants_to_client_roles:futureTableGrants.filter(x=>x.privilege_type==='TRUNCATE').length
  };
  return {
    checkpoint:'E6Y',
    scope:'checked-in API config and local SQL catalog; not runtime PostgREST/GoTrue',
    configured_api:config,
    totals,
    function_candidates:candidates,
    future_default_function_grants:publicFutureDefaultGrants,
    default_acl_client_role_grants:futureUntrustedGrants,
    default_acl_summary:metadata.default_acl_summary,
    risk_flags:{
      e6o_01_local_writer_execute_exposure:privilegedWriters.length===2,
      privileged_default_function_grants_present:publicFutureDefaultGrants.length>0,
      broad_future_public_table_grants_present:futureTableGrants.length>0,
      future_table_truncate_grant_present:futureTableGrants.some(x=>x.privilege_type==='TRUNCATE')
    },
    important_distinctions:[
      'Default ACL rows apply to FUTURE objects created by their specified owner/schema; they do not establish grants on already-existing objects',
      'Static config is checked-in intent, not actual running PostgREST configuration or production configuration',
      'SQL EXECUTE is necessary but not sufficient for callable REST RPC; trigger-return functions are not normal RPCs',
      'An internally authorised SECURITY DEFINER function may have SQL EXECUTE yet still deny an unauthorised caller'
    ],
    database_modified:false,external_api_called:false,postgrest_route_tested:false,
    gotrue_principal_tested:false,stage_parity_certified:false,
    independent_G7G8_acceptance:false,productionApproved:false
  };
}

const values=names.map(n=>"('"+n+"')").join(',');
const sql=[
  'BEGIN TRANSACTION READ ONLY;',
  'WITH wanted(name) AS (VALUES '+values+'),',
  'functions AS (',
  'SELECT p.proname::text AS name,',
  " (n.nspname::text||'.'||p.proname::text||'('||pg_get_function_identity_arguments(p.oid)||')') AS signature,",
  ' pg_get_function_result(p.oid) AS return_type,p.prosecdef AS definer,',
  ' pg_get_userbyid(p.proowner) AS owner,r.rolbypassrls AS owner_bypassrls,',
  ' p.pronargdefaults AS default_args,',
  " has_function_privilege('anon',p.oid,'EXECUTE') AS anon_execute,",
  " has_function_privilege('authenticated',p.oid,'EXECUTE') AS authenticated_execute,",
  " has_function_privilege('public',p.oid,'EXECUTE') AS public_execute,",
  " has_function_privilege('service_role',p.oid,'EXECUTE') AS service_execute",
  ' FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace',
  ' JOIN pg_roles r ON r.oid=p.proowner',
  " WHERE n.nspname='public' AND p.proname IN (SELECT name FROM wanted)",
  '), default_grants AS (',
  " SELECT pg_get_userbyid(d.defaclrole) AS owner,coalesce(n.nspname::text,'<global>') AS schema_name,",
  ' d.defaclobjtype::text AS object_type,',
  " CASE WHEN a.grantee=0 THEN 'PUBLIC' ELSE pg_get_userbyid(a.grantee) END AS grantee,",
  ' a.privilege_type::text AS privilege_type,a.is_grantable',
  ' FROM pg_default_acl d',
  ' LEFT JOIN pg_namespace n ON n.oid=d.defaclnamespace',
  ' CROSS JOIN LATERAL aclexplode(d.defaclacl) a',
  '), acl_summary AS (',
  ' SELECT owner,schema_name,object_type,grantee,privilege_type,',
  ' count(*)::integer AS matched_entries',
  ' FROM default_grants',
  ' GROUP BY owner,schema_name,object_type,grantee,privilege_type',
  ')',
  ' SELECT jsonb_build_object(',
  " 'functions',(SELECT coalesce(jsonb_agg(to_jsonb(f) ORDER BY signature),'[]'::jsonb) FROM functions f),",
  " 'default_acl_records',(SELECT count(*) FROM pg_default_acl),",
  " 'default_acl_grants',(SELECT coalesce(jsonb_agg(to_jsonb(g) ORDER BY owner,schema_name,object_type,grantee,privilege_type),'[]'::jsonb) FROM default_grants g),",
  " 'default_acl_summary',(SELECT coalesce(jsonb_agg(to_jsonb(s) ORDER BY owner,schema_name,object_type,grantee,privilege_type),'[]'::jsonb) FROM acl_summary s)",
  ' )::text;',
  'COMMIT;'
].join('\n');

function run(mode){
  const config=readStaticApiConfig(readFileSync('supabase/config.toml','utf8'));
  if(mode==='--source-only'){
    console.log(JSON.stringify({checkpoint:'E6Y',config,expected_function_names:names,
      local_catalog_not_checked:true,stage_certified:false,productionApproved:false},null,2));
    return;
  }
  if(mode!=='--local')throw Error('usage: --source-only | --local');
  const env={...process.env};
  if(process.platform==='win32')env.DOCKER_HOST='npipe:////./pipe/dockerDesktopLinuxEngine';
  const p=spawnSync('docker',['exec','-i','supabase_db_wantok-service',
    'psql','-X','-U','postgres','-d','postgres','-At','-v','ON_ERROR_STOP=1','-P','pager=off'],
    {input:sql,encoding:'utf8',env,maxBuffer:500000,timeout:45000});
  if(p.status!==0)throw Error('READ ONLY catalog failed: '+(p.stderr||'').slice(-500));
  const line=(p.stdout||'').split(/\r?\n/).find(s=>s.startsWith('{'));
  assert.ok(line,'No SQL catalog JSON returned');
  const result=evaluate(JSON.parse(line),config);
  console.log(JSON.stringify(result,null,2));
}
const invoked=process.argv[1]&&resolve(process.argv[1])===fileURLToPath(import.meta.url);
if(invoked){try{run(process.argv[2]);}catch(e){console.error('E6Y_BLOCKED: '+e.message);process.exitCode=1;}}
