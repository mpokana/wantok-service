/**
 * E6L metadata-only least-privilege audit for the authorised EAGLT02 local DB.
 * Zero function bodies, customer rows, credentials, mutable operations.
 * The role matrix here is a technical baseline, NOT G7/G8 human acceptance.
 */
import {spawnSync} from 'node:child_process';
import assert from 'node:assert/strict';

if (process.argv.length !== 3 || process.argv[2] !== '--local') {
  console.error('Use --local on authorised EAGLT02 only.');
  process.exit(2);
}
const environment={...process.env};
if(process.platform==='win32')
  environment.DOCKER_HOST='npipe:////./pipe/dockerDesktopLinuxEngine';
const sql=String.raw`
BEGIN TRANSACTION READ ONLY;
WITH target_functions AS (
  SELECT p.oid,p.proname::text AS name,
    pg_get_function_identity_arguments(p.oid) AS signature,
    pg_get_userbyid(p.proowner) AS owner,
    owner_role.rolbypassrls AS owner_bypass_rls,
    owner_role.rolsuper AS owner_superuser,
    p.prosecdef AS security_definer,
    p.proconfig::text[] AS function_settings,
    has_function_privilege('anon',p.oid,'EXECUTE') AS anon_execute,
    has_function_privilege('authenticated',p.oid,'EXECUTE') AS signed_in_execute,
    has_function_privilege('service_role',p.oid,'EXECUTE') AS service_execute
  FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
  JOIN pg_roles owner_role ON owner_role.oid=p.proowner
  WHERE n.nspname='public' AND p.prosecdef
  AND p.proname ~ '^(has_operations_|configure_operations_|request_operations_|decide_operations_|register_operations_|map_operations_|record_operations_|triage_vendor_|submit_vendor_intake_|list_vendor_clearance_|revoke_vendor_activation_|emergency_revoke_vendor_|pause_expired_vendor_|admin_set_provider_service_status$|review_provider_application$)'
),
target_schemas AS (
  SELECT n.nspname::text AS name,
    has_schema_privilege('anon',n.oid,'CREATE') AS anon_create,
    has_schema_privilege('authenticated',n.oid,'CREATE') AS signed_in_create,
    has_schema_privilege('service_role',n.oid,'CREATE') AS service_create
  FROM pg_namespace n WHERE n.nspname IN ('public','auth','extensions')
),
target_roles AS (
  SELECT rolname::text AS name,rolsuper AS superuser,
    rolbypassrls AS bypass_rls
  FROM pg_roles
  WHERE rolname IN ('postgres','supabase_admin','anon','authenticated','service_role')
)
SELECT jsonb_build_object(
 'functions',(SELECT coalesce(jsonb_agg(to_jsonb(f)-'oid' ORDER BY f.name,f.signature),'[]'::jsonb) FROM target_functions f),
 'schemas',(SELECT coalesce(jsonb_agg(to_jsonb(s) ORDER BY s.name),'[]'::jsonb) FROM target_schemas s),
 'roles',(SELECT coalesce(jsonb_agg(to_jsonb(r) ORDER BY r.name),'[]'::jsonb) FROM target_roles r),
 'temp_database_permissions',jsonb_build_object(
   'anon',has_database_privilege('anon',current_database(),'TEMP'),
   'authenticated',has_database_privilege('authenticated',current_database(),'TEMP'),
   'service_role',has_database_privilege('service_role',current_database(),'TEMP'))
)::text;
COMMIT;
`;
assert.ok(sql.includes('BEGIN TRANSACTION READ ONLY'));
assert.ok(!/\b(INSERT|UPDATE|DELETE|ALTER|DROP|TRUNCATE|COPY)\s+(?:INTO|FROM|TABLE|SCHEMA|FUNCTION|DATABASE)/i.test(sql));
const result=spawnSync('docker',[
 'exec','-i','supabase_db_wantok-service','psql','-X','-U','postgres',
 '-d','postgres','-At','-v','ON_ERROR_STOP=1','-P','pager=off'
],{input:sql,encoding:'utf8',env:environment,timeout:30000,maxBuffer:1500000});
if(result.status!==0) {
  console.error('E6L local catalog inspection failed; no changes made:',
    (result.stderr??'').slice(-650));
  process.exit(1);
}
const jsonLine=(result.stdout??'').split(/\r?\n/).find(s=>s.startsWith('{'));
assert.ok(jsonLine,'Catalog JSON missing');
const data=JSON.parse(jsonLine);
assert.equal(data.functions.length,19,'Unexpected selection size: revise inventory coverage before acceptance');
assert.equal(data.schemas.length,3,'Required schemas missing');
const restricted=new Set([
 'configure_operations_provisioner','emergency_revoke_vendor_clearance_trusted',
 'map_operations_service_category','pause_expired_vendor_clearances',
 'record_operations_case_conflict_trusted','register_operations_case_jurisdiction',
 'register_operations_region'
]);
const unexpectedAnon=data.functions.filter(f=>f.anon_execute).map(f=>f.name);
const unexpectedTrustedAuth=data.functions.filter(f=>
 restricted.has(f.name)&&f.signed_in_execute).map(f=>f.name);
const missingExecPath=data.functions.filter(f=>
 !(f.function_settings??[]).some(s=>s.startsWith('search_path='))).map(f=>f.name);
const missingServiceGrant=data.functions.filter(f=>!f.service_execute).map(f=>f.name);
const tempPathReview=data.functions.filter(f=>
 !((f.function_settings??[]).find(s=>s.startsWith('search_path='))??'')
 .toLowerCase().split('=').slice(1).join('=').split(',')
 .some(x=>x.trim()==='pg_temp')).map(f=>f.name);
const ownerBypass=data.functions.filter(f=>f.owner_bypass_rls).map(f=>f.name);
const callerCreateSchemas=data.schemas.filter(s=>s.anon_create||s.signed_in_create)
  .map(s=>s.name);
const controlsPass=unexpectedAnon.length===0&&unexpectedTrustedAuth.length===0&&
 missingExecPath.length===0&&missingServiceGrant.length===0;
console.log(JSON.stringify({
 title:'E6L catalog-only privileged function safety inventory',
 source:'Authorised EAGLT02 local PostgreSQL; READ ONLY transaction; no function bodies or real data',
 functions_examined:data.functions.length,
 security_definer_owners:[...new Set(data.functions.map(f=>f.owner))],
 owner_bypass_rls_functions:ownerBypass,
 anonymous_executable_functions:unexpectedAnon,
 trusted_only_functions_executable_by_authenticated:unexpectedTrustedAuth,
 functions_missing_search_path:missingExecPath,
 functions_missing_service_execute:missingServiceGrant,
 search_path_pg_temp_explicitly_missing:tempPathReview,
 caller_creatable_searched_schemas:callerCreateSchemas,
 temp_creation_rights:data.temp_database_permissions,
 examined_schema_create_rights:data.schemas,
 role_bypass_rls:data.roles,
 full_signatures_and_function_bodies_printed:false,
 table_rows_examined:false,
 shared_database_writes:false,
 catalog_controls_pass:controlsPass,
 human_g7_g8_approved:false,
 conclusion:'Source-level unqualified references and effective privilege parity require independent review'
},null,2));
if(!controlsPass) process.exitCode=1;
