/** E6U G8: proposed role/ACL and RLS PARITY PREFLIGHT, not parity certification.
 * Local pg_catalog READ ONLY; no personal records, credentials or function bodies.
 */
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
if(process.argv.length!==3||process.argv[2]!=='--local'){
 console.error('Usage: node scripts/qa/e6u-privilege-parity-preflight.mjs --local');
 process.exit(2);
}
const env={...process.env};
if(process.platform==='win32')env.DOCKER_HOST='npipe:////./pipe/dockerDesktopLinuxEngine';
const sql=String.raw`
BEGIN TRANSACTION READ ONLY;
WITH selected(signature) AS (VALUES
 ('public.write_audit_event(text,text,uuid,jsonb,uuid)'),
 ('public.enqueue_notification(uuid,text,text,text,jsonb,text,text,text)'),
 ('public.has_role(text,uuid)'),
 ('public.is_admin(uuid)'),
 ('public.is_technical_platform_admin(uuid)'),
 ('public.has_platform_permission(text,uuid)'),
 ('public.has_technical_permission(text,text,uuid)'),
 ('public.effective_technical_access_level(text,uuid)'),
 ('public.can_access_technical_console(uuid)'),
 ('public.can_manage_technical_module_access(text,uuid)')
), function_meta AS (
 SELECT s.signature, p.oid IS NOT NULL AS present,
   CASE WHEN p.oid IS NULL THEN null ELSE pg_get_userbyid(p.proowner) END AS owner,
   p.prosecdef AS definer, coalesce(owner_role.rolbypassrls,false) AS owner_bypass_rls,
   CASE WHEN p.oid IS NULL THEN null ELSE has_function_privilege('anon',p.oid,'EXECUTE') END AS anon_execute,
   CASE WHEN p.oid IS NULL THEN null ELSE has_function_privilege('authenticated',p.oid,'EXECUTE') END AS authenticated_execute,
   CASE WHEN p.oid IS NULL THEN null ELSE has_function_privilege('service_role',p.oid,'EXECUTE') END AS service_execute,
   p.proconfig AS function_settings,
   p.proacl::text AS explicit_acl
 FROM selected s
 LEFT JOIN pg_proc p ON p.oid=to_regprocedure(s.signature)
 LEFT JOIN pg_roles owner_role ON owner_role.oid=p.proowner
), table_meta AS (
 SELECT count(*) AS public_base_tables,
 count(*) FILTER (WHERE c.relrowsecurity) AS tables_rls_enabled,
 count(*) FILTER (WHERE c.relforcerowsecurity) AS tables_rls_forced
 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
 WHERE n.nspname='public' AND c.relkind IN ('r','p')
), role_meta AS (
 SELECT rolname,rolbypassrls,rolsuper,rolcreaterole,rolcreatedb,rolcanlogin
 FROM pg_roles WHERE rolname IN ('anon','authenticated','service_role','supabase_admin','postgres')
)
SELECT jsonb_build_object(
 'selected_functions',(SELECT jsonb_agg(to_jsonb(f) ORDER BY signature) FROM function_meta f),
 'table_rls_summary',(SELECT to_jsonb(t) FROM table_meta t),
 'public_rls_policy_count',(SELECT count(*) FROM pg_policy pp JOIN pg_class c ON c.oid=pp.polrelid
   JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='public'),
 'role_flags',(SELECT jsonb_agg(to_jsonb(r) ORDER BY rolname) FROM role_meta r)
)::text;
COMMIT;
`;
const r=spawnSync('docker',[
 'exec','-i','supabase_db_wantok-service','psql','-X','-U','postgres','-d','postgres','-At',
 '-v','ON_ERROR_STOP=1','-P','pager=off'
],{input:sql,encoding:'utf8',env,timeout:30000,maxBuffer:200000});
if(r.status!==0)throw Error('Catalog-only preflight failed: '+(r.stderr??'').slice(-500));
const raw=(r.stdout??'').split(/\r?\n/).find(s=>s.startsWith('{'));
assert.ok(raw,'Expected one catalog JSON object');
const data=JSON.parse(raw);
assert.equal(data.selected_functions.length,10,'Exact ten-function trust sample required');
assert.ok(data.selected_functions.every(f=>f.present),'Missing expected function signature');
const internal=data.selected_functions.filter(f=>f.signature.includes('write_audit_event(')||
 f.signature.includes('enqueue_notification('));
const open=internal.filter(f=>f.anon_execute||f.authenticated_execute);
assert.equal(internal.length,2);
const bypass=data.selected_functions.filter(f=>f.owner_bypass_rls).length;
console.log(JSON.stringify({
 audit:'E6U LOCAL READ-ONLY G8 owner/ACL/RLS snapshot, not an independent stage parity proof',
 selected_function_count:data.selected_functions.length,
 selected_bypass_rls_owners:bypass,
 internal_writer_untrusted_exec_count:open.length,
 internal_writer_untrusted_exec:open.map(f=>f.signature),
 functions:data.selected_functions,
 table_rls_summary:data.table_rls_summary,
 public_rls_policy_count:data.public_rls_policy_count,
 role_flags:data.role_flags,
 stage_parity_tested:false,
 production_or_rest_tested:false,
 user_table_rows_read:false,
 data_modified:false,
 independent_human_G8_approval:false
},null,2));
