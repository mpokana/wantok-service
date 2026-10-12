/**
 * E6K: catalogue-only public marketplace disclosure inventory.
 * No real provider/customer rows, metadata values, token or secrets are read.
 * This inspection is safe only on the dedicated, authorised EAGLT02 local
 * Supabase Docker database; all work in a READ ONLY transaction.
 */
import {spawnSync} from 'node:child_process';
import assert from 'node:assert/strict';

if (process.argv.length !== 3 || process.argv[2] !== '--local') {
  console.error('Use --local for the authorised EAGLT02 database only.');
  process.exit(2);
}
const env={...process.env};
if (process.platform==='win32')
  env.DOCKER_HOST='npipe:////./pipe/dockerDesktopLinuxEngine';
const sql=`
BEGIN TRANSACTION READ ONLY;
WITH targets AS (
 SELECT c.oid,c.relname::text AS table_name,
   pg_get_userbyid(c.relowner) AS owner,
   c.relrowsecurity AS rls_enabled,
   c.relforcerowsecurity AS force_rls,
   has_table_privilege('anon',c.oid,'INSERT') AS anon_insert,
   has_table_privilege('anon',c.oid,'UPDATE') AS anon_update,
   has_table_privilege('anon',c.oid,'DELETE') AS anon_delete
 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
 WHERE n.nspname='public'
 AND c.relname IN ('provider_profiles','provider_services')
 AND c.relkind IN ('r','p')
),
columns AS (
 SELECT t.table_name,a.attname::text AS name,
   format_type(a.atttypid,a.atttypmod) AS data_type,
   has_column_privilege('anon',t.oid,a.attnum,'SELECT') AS anon_select,
   has_column_privilege('authenticated',t.oid,a.attnum,'SELECT')
     AS signed_in_select
 FROM targets t JOIN pg_attribute a ON a.attrelid=t.oid
 WHERE a.attnum>0 AND NOT a.attisdropped
),
policies AS (
 SELECT tablename AS table_name,policyname AS policy_name,
   roles::text AS role_set,cmd AS command,
   COALESCE(qual,'') AS using_expression
 FROM pg_policies
 WHERE schemaname='public'
 AND tablename IN ('provider_profiles','provider_services')
)
SELECT jsonb_build_object(
  'tables',(SELECT coalesce(jsonb_agg(to_jsonb(t) ORDER BY table_name),'[]'::jsonb) FROM targets t),
  'columns',(SELECT coalesce(jsonb_agg(to_jsonb(c) ORDER BY table_name,name),'[]'::jsonb) FROM columns c),
  'policies',(SELECT coalesce(jsonb_agg(to_jsonb(p) ORDER BY table_name,policy_name),'[]'::jsonb) FROM policies p)
)::text;
COMMIT;`;
assert.ok(!/\b(INSERT|UPDATE|DELETE|DROP|TRUNCATE|ALTER|COPY)\s+(?:INTO|FROM|TABLE|FUNCTION|SCHEMA|DATABASE)/i.test(sql),
  'This inventory must not mutate the source database');
const result=spawnSync('docker',[
  'exec','-i','supabase_db_wantok-service','psql','-X','-U','postgres',
  '-d','postgres','-At','-v','ON_ERROR_STOP=1','-P','pager=off'
],{input:sql,encoding:'utf8',env,timeout:30000,maxBuffer:1000000});
if(result.status!==0) {
  console.error('Read-only database inspection failed:',(result.stderr??'').slice(-800));
  process.exit(1);
}
const payload=result.stdout.split(/\r?\n/).find(line=>line.startsWith('{'));
assert.ok(payload,'Missing pg_catalog output');
const data=JSON.parse(payload);
assert.equal(data.tables.length,2,'Both marketplace tables must be examined');
const mustPresent=[
  'provider_profiles_public_read','provider_profiles_authenticated_read',
  'provider_services_public_read','provider_services_authenticated_read'];
const absent=mustPresent.filter(name=>!data.policies.some(p=>p.policy_name===name));
const missingRls=data.tables.filter(t=>!t.rls_enabled).map(t=>t.table_name);
const anonWrites=data.tables.filter(t=>t.anon_insert||t.anon_update||t.anon_delete)
  .map(t=>t.table_name);
const reviewNames=new Set([
  'metadata','base_address','base_lat','base_lng','service_address','lat','lng'
]);
const candidates=data.columns.filter(c=>c.anon_select&&reviewNames.has(c.name))
  .map(c=>`${c.table_name}.${c.name}`);
const exposureCounts=Object.fromEntries(data.tables.map(t=>[t.table_name,{
  exposed_columns:data.columns.filter(c=>c.table_name===t.table_name&&c.anon_select).length,
  all_columns:data.columns.filter(c=>c.table_name===t.table_name).length,
}]));
const guardsOk=absent.length===0&&missingRls.length===0&&anonWrites.length===0;
const output={
  gate:'E6K marketplace RLS baseline / not external privacy approval',
  source:'EAGLT02 local pg_catalog in READ ONLY transaction',
  policies_checked:data.policies.length,
  table_owners:data.tables.map(t=>({table:t.table_name,owner:t.owner,force_rls:t.force_rls})),
  anonymous_column_access:exposureCounts,
  candidate_fields_for_privacy_review:candidates,
  missing_named_policies:absent,
  tables_missing_rls:missingRls,
  tables_with_anon_write:anonWrites,
  real_record_values_accessed:false,
  database_writes:false,
  baseline_controls_pass:guardsOk,
  public_projection_signoff:'PENDING'
};
console.log(JSON.stringify(output,null,2));
if(!guardsOk) process.exitCode=1;
