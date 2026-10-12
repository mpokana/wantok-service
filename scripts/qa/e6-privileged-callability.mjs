/** E6T: metadata-only direct-callability triage for all public definers.
 * Local EAGLT02 PostgreSQL READ ONLY transaction, no user records or function bodies.
 * SQL EXECUTE != published PostgREST route. Trigger return != direct SQL RPC.
 */
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
if(process.argv.length!==3||process.argv[2]!=='--local'){
 console.error('Usage: node scripts/qa/e6-privileged-callability.mjs --local');
 process.exit(2);
}
const env={...process.env};
if(process.platform==='win32')env.DOCKER_HOST='npipe:////./pipe/dockerDesktopLinuxEngine';
const sql=String.raw`
BEGIN TRANSACTION READ ONLY;
WITH def AS (
 SELECT p.proname::text AS name,
  (p.prorettype='pg_catalog.trigger'::regtype) AS is_trigger,
  p.prokind::text AS kind,
  has_function_privilege('anon',p.oid,'EXECUTE') AS anon_execute,
  has_function_privilege('authenticated',p.oid,'EXECUTE') AS authenticated_execute,
  has_function_privilege('service_role',p.oid,'EXECUTE') AS trusted_execute
 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
 WHERE n.nspname='public' AND p.prosecdef
)
SELECT jsonb_build_object(
 'total',count(*),
 'anon_execute',count(*) FILTER(WHERE anon_execute),
 'anon_trigger',count(*) FILTER(WHERE anon_execute AND is_trigger),
 'anon_nontrigger',count(*) FILTER(WHERE anon_execute AND NOT is_trigger),
 'auth_nontrigger',count(*) FILTER(WHERE authenticated_execute AND NOT is_trigger),
 'anon_nontrigger_internal_names',coalesce(jsonb_agg(name ORDER BY name)
  FILTER(WHERE anon_execute AND NOT is_trigger
   AND (name LIKE '%internal%' OR name LIKE 'sync_%'
    OR name LIKE 'refresh_%' OR name LIKE '%audit%')),'[]'::jsonb),
 'anon_nontrigger_privileged_verbs',coalesce(jsonb_agg(name ORDER BY name)
  FILTER(WHERE anon_execute AND NOT is_trigger
   AND name ~ '^(grant_|revoke_|admin_|publish_|restore_|configure_|record_|set_|update_|enqueue_|write_)'),'[]'::jsonb)
)::text FROM def;
COMMIT;`;
const r=spawnSync('docker',['exec','-i','supabase_db_wantok-service',
 'psql','-X','-U','postgres','-d','postgres','-At',
 '-v','ON_ERROR_STOP=1','-P','pager=off'],{
  input:sql,encoding:'utf8',timeout:30000,maxBuffer:200000,env
 });
if(r.status!==0)throw new Error('Unable to inspect read-only local catalog: '+(r.stderr??'').slice(-400));
const line=(r.stdout??'').split(/\r?\n/).find(x=>x.startsWith('{'));
assert.ok(line,'Expected single read-only catalog JSON');
const result=JSON.parse(line);
assert.ok(result.total>=19,'Definer catalog unexpectedly incomplete');
assert.equal(result.anon_execute,result.anon_trigger+result.anon_nontrigger,
 'Callability partition must cover all anonymous definer grants');
console.log(JSON.stringify({
 audit:'E6T public definer effective EXECUTE and SQL-callable return classification',
 source:'local PostgreSQL catalog, READ ONLY, schema public only',
 ...result,
 interpretation:'trigger-return routines are not directly SQL-invokable as ordinary RPCs; other SQL function EXECUTE does not establish REST reachability',
 user_rows_read:0,
 function_bodies_read:0,
 write_operations:false,
 postgrest_routes_tested:false,
 independent_G8_approved:false
},null,2));
