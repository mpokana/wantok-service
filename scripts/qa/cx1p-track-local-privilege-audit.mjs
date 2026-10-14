/**
 * CX1P installed-local Track permissions INVENTORY ONLY.
 * Fixed EAGLT02 database; PostgreSQL catalog in one READ ONLY transaction.
 * No rows from application tables, secrets, user IDs, SQL bodies or snapshot exports.
 */
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';

const tables=['service_bookings','service_quotes','service_reviews',
  'service_categories','provider_profiles','provider_services','provider_resources'];
const sensitive=['notes','beneficiary_email','beneficiary_phone','service_address',
  'origin_address','destination_address','metadata','message','base_address',
  'base_lat','base_lng','lat','lng'];
export const sql=[
 'BEGIN TRANSACTION READ ONLY;',
 'WITH t AS (SELECT c.oid,c.relname::text AS name,pg_get_userbyid(c.relowner) AS owner,',
 '   c.relrowsecurity AS rls,c.relforcerowsecurity AS forced,',
 "   has_table_privilege('anon',c.oid,'SELECT') AS anon_read,",
 "   has_table_privilege('authenticated',c.oid,'SELECT') AS auth_read,",
 "   has_table_privilege('service_role',c.oid,'SELECT') AS service_read,",
 "   has_table_privilege('anon',c.oid,'INSERT') AS anon_insert,",
 "   has_table_privilege('authenticated',c.oid,'INSERT') AS auth_insert,",
 "   has_table_privilege('authenticated',c.oid,'UPDATE') AS auth_update,",
 "   has_table_privilege('authenticated',c.oid,'DELETE') AS auth_delete",
 ' FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace',
 " WHERE n.nspname='public' AND c.relkind IN ('r','p')",
 " AND c.relname IN ('service_bookings','service_quotes','service_reviews','service_categories',",
 " 'provider_profiles','provider_services','provider_resources')),",
 ' col AS (SELECT t.name AS table_name,a.attname::text AS name,',
 " has_column_privilege('anon',t.oid,a.attnum,'SELECT') AS anon_read,",
 " has_column_privilege('authenticated',t.oid,a.attnum,'SELECT') AS auth_read",
 ' FROM t JOIN pg_attribute a ON a.attrelid=t.oid WHERE a.attnum>0 AND NOT a.attisdropped),',
 ' pol AS (SELECT p.tablename AS table_name,p.policyname AS name,p.cmd,',
 '   p.permissive,p.roles::text AS role_set,',
 "   COALESCE(p.qual,'') ~* 'customer_id[[:space:]]*=[[:space:]]*auth[.]uid[(][)]' AS has_customer_uid,",
 "   COALESCE(p.qual,'') ~* 'provider_id[[:space:]]*=[[:space:]]*auth[.]uid[(][)]' AS has_provider_uid,",
 "   COALESCE(p.qual,'') ~* 'is_admin[(]auth[.]uid[(][)][)]' AS has_admin_branch,",
 "   COALESCE(p.qual,'') ~* 'provider_id IS NULL' AS has_unassigned_branch,",
 "   COALESCE(p.qual,'') ~* 'visibility' AS has_visibility_branch",
 ' FROM pg_policies p WHERE p.schemaname=\'public\'',
 " AND p.tablename IN ('service_bookings','service_quotes','service_reviews',",
 " 'service_categories','provider_profiles','provider_services','provider_resources')),",
 ' funcs AS (SELECT p.proname::text AS name, p.prosecdef AS definer,',
 '  pg_get_userbyid(p.proowner) AS owner, r.rolbypassrls AS owner_bypass_rls,',
 '  p.proconfig AS settings,',
 "  has_function_privilege('anon',p.oid,'EXECUTE') AS anon_execute,",
 "  has_function_privilege('authenticated',p.oid,'EXECUTE') AS auth_execute",
 ' FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace',
 ' JOIN pg_roles r ON r.oid=p.proowner',
 " WHERE n.nspname='public' AND p.proname IN ('is_admin','list_my_track_bookings_candidate')),",
 " rflags AS (SELECT rolname::text AS name,rolbypassrls,rolsuper FROM pg_roles",
 " WHERE rolname IN ('anon','authenticated','service_role','postgres','supabase_admin'))",
 ' SELECT jsonb_build_object(',
 " 'tables',(SELECT COALESCE(jsonb_agg(to_jsonb(t) ORDER BY name),'[]'::jsonb) FROM t),",
 " 'columns',(SELECT COALESCE(jsonb_agg(to_jsonb(c) ORDER BY table_name,name),'[]'::jsonb) FROM col c),",
 " 'policies',(SELECT COALESCE(jsonb_agg(to_jsonb(p) ORDER BY table_name,name),'[]'::jsonb) FROM pol p),",
 " 'functions',(SELECT COALESCE(jsonb_agg(to_jsonb(f) ORDER BY name),'[]'::jsonb) FROM funcs f),",
 " 'roles',(SELECT COALESCE(jsonb_agg(to_jsonb(r) ORDER BY name),'[]'::jsonb) FROM rflags r),",
 " 'engine',(SELECT current_setting('server_version_num'))",
 ')::text;',
 'COMMIT;'
].join('\n');
export function summarise(data){
  assert.ok(data&&typeof data==='object','Missing catalogue evidence');
  assert.ok(Array.isArray(data.tables)&&Array.isArray(data.columns)&&Array.isArray(data.policies),
    'Catalogue arrays missing');
  const found = new Set(data.tables.map(x=>x.name));
  assert.ok(tables.every(x=>found.has(x)), 'Mandatory installed marketplace table missing');
  const booked=data.tables.find(x=>x.name==='service_bookings');
  const bookingPolicies=data.policies.filter(p=>p.table_name==='service_bookings'&&p.cmd==='SELECT');
  const policyNames=bookingPolicies.map(p=>p.name);
  const bookingColumns=data.columns.filter(x=>x.table_name==='service_bookings');
  const privateColumns=bookingColumns.filter(x=>sensitive.includes(x.name));
  const sensitiveAuth = privateColumns.filter(x=>x.auth_read).map(x=>x.name).sort();
  const candidate=data.functions.filter(x=>x.name==='list_my_track_bookings_candidate');
  return {
    checkpoint:'CX1P',
    audit:'EAGLT02 installed catalog only; NOT stage parity or JWT acceptance',
    source:'fixed local container, READ ONLY pg_catalog transaction',
    postgres_version_num:data.engine,
    tables_checked:data.tables.length,
    booking_table_owner:booked.owner,
    booking_rls_enabled:booked.rls,
    booking_rls_forced:booked.forced,
    booking_anonymous_select:booked.anon_read,
    booking_authenticated_select:booked.auth_read,
    booking_authenticated_insert:booked.auth_insert,
    booking_authenticated_update:booked.auth_update,
    booking_authenticated_delete:booked.auth_delete,
    booking_policy_names:policyNames.sort(),
    booking_policy_classes:{
      customer:bookingPolicies.some(p=>p.has_customer_uid),
      provider:bookingPolicies.some(p=>p.has_provider_uid),
      admin:bookingPolicies.some(p=>p.has_admin_branch),
      qualified_unassigned:bookingPolicies.some(p=>p.has_unassigned_branch),
    },
    booking_private_column_names:sensitiveAuth,
    customer_column_projection_approved:false,
    candidate_function_installed:candidate.length>0,
    role_flags:data.roles,
    admin_helper:data.functions.filter(x=>x.name==='is_admin'),
    evidence_columns_count:bookingColumns.length,
    policy_count:data.policies.length,
    app_table_rows_read:false,
    credentials_or_tokens_read:false,
    schema_acl_snapshot_exported:false,
    local_database_writes:false,
    parity_restored:false,
    real_gotrue_sessions_tested:false,
    real_actor_http_tested:false,
    human_stage_signoffs:0,
    private_track_route_approved:false,
    productionApproved:false
  };
}
export function readOnlyShape(query){
  assert.match(query,/^BEGIN TRANSACTION READ ONLY;/,'Must start READ ONLY');
  assert.match(query,/COMMIT;$/,'Must close read-only transaction');
  assert.doesNotMatch(query,/\b(?:INSERT|UPDATE|DELETE|TRUNCATE|DROP|ALTER|CREATE|GRANT|REVOKE|COPY)\s+(?:INTO|FROM|TABLE|FUNCTION|ROLE|SCHEMA|DATABASE|PUBLIC|\()/i,
    'Mutation or export command prohibited');
  assert.doesNotMatch(query,/\bCOPY\b/i,'COPY export prohibited');
  assert.doesNotMatch(query,/\bFROM\s+(?:public|auth|storage)\./i,'Application schema row reads prohibited');
  assert.match(query,/FROM pg_class c/,'Catalog must be inspected');
  return true;
}
if(process.argv[1]&&process.argv[1].endsWith('cx1p-track-local-privilege-audit.mjs')){
  assert.deepEqual(process.argv.slice(2),['--local-read-only'],
    'Explicit --local-read-only required; never use production');
  readOnlyShape(sql);
  const env={...process.env};
  if(process.platform==='win32')env.DOCKER_HOST='npipe:////./pipe/dockerDesktopLinuxEngine';
  const p=spawnSync('docker',['exec','-i','supabase_db_wantok-service','psql',
    '-X','-U','postgres','-d','postgres','-At','-v','ON_ERROR_STOP=1','-P','pager=off'],
    {input:sql,encoding:'utf8',env,timeout:30000,maxBuffer:450000});
  if(p.status!==0)throw Error('Read-only catalog audit failed: '+(p.stderr||'').slice(-500));
  const json=(p.stdout||'').split(/\r?\n/).find(x=>x.startsWith('{'));
  assert.ok(json,'Missing catalog JSON');
  console.log(JSON.stringify(summarise(JSON.parse(json)),null,2));
}
