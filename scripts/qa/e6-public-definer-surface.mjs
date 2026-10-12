/** E6O whole-public-schema SECURITY DEFINER metadata inventory.
 * Authorised EAGLT02 local Docker only. READ ONLY; no SQL bodies, rows, secrets.
 * Observations are baseline facts, not penetration proof or production approval.
 */
import {spawnSync} from 'node:child_process';
import assert from 'node:assert/strict';
if(process.argv.length!==3||process.argv[2]!=='--local'){
 console.error('Usage: node scripts/qa/e6-public-definer-surface.mjs --local');process.exit(2);
}
const env={...process.env};
if(process.platform==='win32')env.DOCKER_HOST='npipe:////./pipe/dockerDesktopLinuxEngine';
const sql=String.raw`
BEGIN TRANSACTION READ ONLY;
WITH defs AS (
 SELECT p.proname::text AS name,
   pg_get_function_identity_arguments(p.oid) AS signature,
   pg_get_userbyid(p.proowner) AS owner,
   r.rolbypassrls AS owner_bypass_rls,
   p.prokind::text AS kind,
   p.proconfig AS settings,
   has_function_privilege('anon',p.oid,'EXECUTE') AS anon_execute,
   has_function_privilege('authenticated',p.oid,'EXECUTE') AS authenticated_execute,
   has_function_privilege('service_role',p.oid,'EXECUTE') AS service_execute
 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
 JOIN pg_roles r ON r.oid=p.proowner
 WHERE n.nspname='public' AND p.prosecdef
)
SELECT jsonb_build_object(
 'functions',(SELECT coalesce(jsonb_agg(to_jsonb(d) ORDER BY name,signature),'[]'::jsonb) FROM defs d)
)::text;
COMMIT;
`;
assert.ok(sql.includes('BEGIN TRANSACTION READ ONLY;'));
const run=spawnSync('docker',[
 'exec','-i','supabase_db_wantok-service','psql','-X','-U','postgres',
 '-d','postgres','-At','-v','ON_ERROR_STOP=1','-P','pager=off'
],{input:sql,env,encoding:'utf8',maxBuffer:4_000_000,timeout:30_000});
if(run.status!==0){console.error('Read-only source catalog unavailable:',(run.stderr??'').slice(-500));process.exit(1);}
const payload=(run.stdout??'').split(/\r?\n/).find(s=>s.startsWith('{'));
assert.ok(payload,'No catalog JSON returned');
const f=JSON.parse(payload).functions;
assert.ok(f.length>=19,'Unexpectedly incomplete function catalog');
const internal=['write_audit_event','enqueue_notification',
 'record_technical_module_health_report_internal'];
const exact=f.filter(x=>internal.includes(x.name));
assert.equal(exact.length,3,'Unexpected internal helper lookup count');
const exposed=exact.filter(x=>x.anon_execute||x.authenticated_execute)
 .map(x=>({function:x.name,anon_execute:x.anon_execute,
 signed_in_execute:x.authenticated_execute,owner_bypass_rls:x.owner_bypass_rls}));
const suspicious=f.filter(x=>x.anon_execute&&
 /^(?:grant_|revoke_|set_|update_|record_|enqueue_|publish_|restore_|admin_|configure_|write_)/.test(x.name))
 .map(x=>x.name);
const noExplicitPath=f.filter(x=>!(x.settings??[]).some(s=>s.startsWith('search_path=')))
 .map(x=>x.name);
const trailingTemp=f.filter(x=>(x.settings??[]).some(s=>
  /^search_path=/i.test(s)&&s.split('=')[1].split(',').at(-1).trim()==='pg_temp')).length;
const counts={
 total_security_definers:f.length,
 owner_bypass_rls:f.filter(x=>x.owner_bypass_rls).length,
 anonymous_callable:f.filter(x=>x.anon_execute).length,
 signed_in_callable:f.filter(x=>x.authenticated_execute).length,
 service_role_callable:f.filter(x=>x.service_execute).length,
 explicit_pg_temp_last:trailingTemp,
 functions_missing_explicit_search_path:noExplicitPath.length
};
console.log(JSON.stringify({
 audit:'E6O ALL public SECURITY DEFINER functions / LOCAL metadata-only',
 scope:'Only public schema; no private data or function bodies accessed',
 counts, missing_search_path_names:noExplicitPath,
 selected_unsafe_internal_helper_grants:exposed,
 other_anonymous_verb_like_names_for_manual_review:suspicious,
 direct_routine_exploitation_tested:false,
 actual_http_authorisation_tested:false,
 source_database_writes:false,
 G7_G8_human_signoff:false,
 disposition:exposed.length?'SECURITY REVIEW REQUIRED: privileged internal function grants':'Review broader callable surface'
},null,2));
