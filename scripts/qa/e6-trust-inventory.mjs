/**
 * E6J read-only catalog preflight, restricted to local EAGLT02 Docker Desktop.
 * Inspects PostgreSQL pg_catalog metadata, never function bodies, credentials,
 * user/customer rows or restricted table data. Does not seed, migrate or reset.
 */
import {spawnSync} from 'node:child_process';
import assert from 'node:assert/strict';

if (!process.argv.includes('--local')) {
  console.error('Specify --local; no remote database mode is supported.');
  process.exit(2);
}
const env = {...process.env};
if (process.platform === 'win32') {
  env.DOCKER_HOST = 'npipe:////./pipe/dockerDesktopLinuxEngine';
}
const container = 'supabase_db_wantok-service';
const sql = `
BEGIN TRANSACTION READ ONLY;
WITH f AS (
  SELECT p.oid, p.proname AS name,
    pg_get_function_identity_arguments(p.oid) AS arguments,
    pg_get_userbyid(p.proowner) AS owner,
    p.prosecdef AS security_definer,
    COALESCE(array_to_string(p.proconfig,';'),'') AS settings,
    has_function_privilege('anon',p.oid,'EXECUTE') AS anon_execute,
    has_function_privilege('authenticated',p.oid,'EXECUTE') AS authenticated_execute,
    has_function_privilege('service_role',p.oid,'EXECUTE') AS service_execute
  FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname='public'
    AND p.proname ~ '^(has_operations_|configure_operations_|request_operations_|decide_operations_|register_operations_|map_operations_|record_operations_|triage_vendor_|submit_vendor_intake_|list_vendor_clearance_|revoke_vendor_activation_|emergency_revoke_vendor_|pause_expired_vendor_|admin_set_provider_service_status$|review_provider_application$)'
),
 rls AS (
   SELECT c.relname AS name, pg_get_userbyid(c.relowner) AS owner,
      c.relrowsecurity AS enabled,c.relforcerowsecurity AS forced,
      has_table_privilege('anon',c.oid,'SELECT') AS anon_select,
      has_table_privilege('authenticated',c.oid,'SELECT') AS authenticated_select,
      (SELECT count(*)::integer FROM pg_policy pol WHERE pol.polrelid=c.oid) AS policy_count
   FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
   WHERE n.nspname='public' AND c.relkind IN ('r','p')
     AND (c.relname LIKE 'operations_%'
       OR c.relname IN ('vendor_intake_cases','vendor_activation_clearances',
          'vendor_evidence_requests','vendor_verification_checks',
          'staged_provider_applications','provider_profiles','provider_services'))
),
 missing AS (
   SELECT ver FROM (VALUES
     ('20261011233000'),('20261011240000'),('20261011241000'),
     ('20261011242000'),('20261011243000')) AS v(ver)
   WHERE NOT EXISTS (SELECT 1 FROM supabase_migrations.schema_migrations m
     WHERE m.version=v.ver)
)
SELECT jsonb_build_object(
  'functions',(SELECT COALESCE(jsonb_agg(to_jsonb(f)-'oid' ORDER BY name,arguments),'[]'::jsonb) FROM f),
  'tables',(SELECT COALESCE(jsonb_agg(to_jsonb(rls) ORDER BY name),'[]'::jsonb) FROM rls),
  'pending_migrations',(SELECT COALESCE(jsonb_agg(ver ORDER BY ver),'[]'::jsonb) FROM missing)
)::text;
COMMIT;`;
assert.ok(!/\b(INSERT|UPDATE|DELETE|DROP|ALTER|TRUNCATE|COPY)\s/i.test(sql),
 'Metadata query must be read-only');
const result=spawnSync('docker',[
  'exec','-i',container,'psql','-X','-U','postgres','-d','postgres',
  '-v','ON_ERROR_STOP=1','-P','pager=off','-At'
],{input:sql,encoding:'utf8',env,timeout:25_000,maxBuffer:3_000_000});
if(result.status!==0){
  console.error('Local metadata query failed (no DB changes):',
    (result.stderr??'').slice(-900));
  process.exit(1);
}
const dataLine=(result.stdout??'').split(/\r?\n/).find(line=>line.startsWith('{'));
assert.ok(dataLine, 'No PostgreSQL metadata result');
const data=JSON.parse(dataLine);
const functions=data.functions, tables=data.tables, pending=data.pending_migrations;
const missingSearchPath=functions.filter(f=>
 f.security_definer&&!f.settings.toLowerCase().includes('search_path='));
const untrusted=functions.filter(f=>
 /^(configure_operations_|record_operations_.*trusted|emergency_revoke_vendor_)/.test(f.name)
 &&(f.anon_execute||f.authenticated_execute));
const missingRls=tables.filter(t=>!t.enabled);
const broadAnon=tables.filter(t=>t.anon_select);
const tempPathReview=functions.filter(f=>f.security_definer
 && f.settings.toLowerCase().includes('search_path=')
 && !f.settings.toLowerCase().includes('pg_temp'));
console.log(JSON.stringify({
  mode:'E6J-local-read-only',
  functions_examined:functions.length,
  security_definers:functions.filter(f=>f.security_definer).length,
  operational_tables_examined:tables.length,
  pending_migrations:pending,
  high_risk_trusted_rpc_grants:untrusted.map(f=>f.name),
  missing_security_definer_search_path:missingSearchPath.map(f=>f.name),
  operations_tables_without_rls:missingRls.map(t=>t.name),
  operations_tables_with_anon_select:broadAnon.map(t=>t.name),
  search_path_temp_schema_review:tempPathReview.map(f=>f.name),
  all_results_are_catalog_metadata:true,
  database_writes:false
},null,2));
if(untrusted.length||missingSearchPath.length||missingRls.length||broadAnon.length)
 console.log('E6J_REVIEW_REQUIRED=Catalog findings need independent security review.');
else console.log('E6J_BASELINE_METADATA_CHECK_PASS=true');
