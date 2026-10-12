/**
 * E6X metadata snapshot and fail-closed comparison for future G8 stage parity.
 *
 * --local                : single READ ONLY pg_catalog transaction on EAGLT02,
 *                          emits only catalogue metadata, SQL-body digests.
 * --compare ref.json candidate.json : compare two stored E6X metadata files.
 *
 * NEVER contacts production, grants privileges, deploys migrations, reads
 * application-table rows, exports SQL bodies, or marks G8 accepted.
 */
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {readFileSync} from 'node:fs';
import {spawnSync} from 'node:child_process';

export const schema='wantok-e6x-g8-metadata-v1';
const critical=['engine','extensions','functions','roles','role_memberships',
  'schemas','public_tables','public_policies','default_privileges'];
export function canonical(obj){
  if(Array.isArray(obj))return obj.map(canonical);
  if(obj!==null&&typeof obj==='object'){
    return Object.fromEntries(Object.keys(obj).sort().map(k=>[k,canonical(obj[k])]));
  }
  return obj;
}
export function digest(value){
  return createHash('sha256').update(JSON.stringify(canonical(value))).digest('hex');
}
export function assertShape(obj){
  assert.ok(obj&&typeof obj==='object'&&!Array.isArray(obj),'Snapshot must be object');
  assert.equal(obj.schema,schema,'Unsupported metadata snapshot schema');
  assert.equal(obj.provenance,'catalog-read-only','Only read-only catalog snapshot format accepted');
  assert.ok(obj.metadata&&typeof obj.metadata==='object','Missing catalog');
  for(const field of critical){
    assert.ok(Object.hasOwn(obj.metadata,field),'Missing required catalog field: '+field);
    assert.ok(obj.metadata[field]!==null,'Null required field: '+field);
    if(field!=='engine')assert.ok(Array.isArray(obj.metadata[field]),
      'Expected catalogue array: '+field);
  }
  assert.ok(obj.metadata.engine.version,'PostgreSQL version missing');
  assert.ok(obj.metadata.functions.length>=14,'Expected at least 14 exact function signatures');
  const fkeys=obj.metadata.functions.map(x=>x.signature);
  assert.equal(new Set(fkeys).size,fkeys.length,'Duplicate function identity');
  assert.ok(obj.metadata.public_tables.length>=90,'Expected public table catalog');
  assert.ok(obj.metadata.public_policies.length>=100,'Expected RLS policy catalog');
  assert.equal(obj.fingerprint,digest(obj.metadata),'Metadata fingerprint mismatch');
  return true;
}
function differences(a,b,path='',result=[],limit=50){
  if(result.length>=limit)return result;
  if(JSON.stringify(canonical(a))===JSON.stringify(canonical(b)))return result;
  if(Array.isArray(a)||Array.isArray(b)){
    if(!Array.isArray(a)||!Array.isArray(b)){
      result.push(path||'<root>');return result;
    }
    if(a.length!==b.length)result.push(path+'.length');
    for(let i=0;i<Math.min(a.length,b.length)&&result.length<limit;i++)
      differences(a[i],b[i],path+'['+i+']',result,limit);
    return result;
  }
  if(a&&b&&typeof a==='object'&&typeof b==='object'){
    for(const k of new Set([...Object.keys(a),...Object.keys(b)])){
      if(result.length>=limit)break;
      if(!Object.hasOwn(a,k)||!Object.hasOwn(b,k))result.push(path+'.'+k);
      else differences(a[k],b[k],path?path+'.'+k:k,result,limit);
    }
    return result;
  }
  result.push(path||'<root>');return result;
}
export function compare(reference,candidate){
  assertShape(reference);assertShape(candidate);
  const changed=differences(reference.metadata,candidate.metadata);
  const same=reference.fingerprint===candidate.fingerprint;
  assert.equal(same,changed.length===0,'Fingerprint/structural comparison disagreement');
  return {
    check:'E6X metadata-only comparison, not stage acceptance',
    metadata_identical:same,
    changed_catalog_paths:changed,
    changes_truncated:changed.length===50,
    reference_metadata_sha256:reference.fingerprint,
    candidate_metadata_sha256:candidate.fingerprint,
    stage_provenance_verified:false,
    reviewer_signature_verified:false,
    migration_or_api_behavior_tested:false,
    human_G8_accepted:false,
    productionApproved:false
  };
}
export function makeSnapshot(metadata,source='EAGLT02-local'){
  const snapshot={schema,provenance:'catalog-read-only',source,metadata:canonical(metadata)};
  return {...snapshot,fingerprint:digest(snapshot.metadata)};
}
function runLocal(){
  const selected=spawnSync(process.execPath,
    ['./scripts/qa/e6w-installed-caller-trust.mjs','--source-only'],
    {encoding:'utf8',timeout:12000,maxBuffer:500000});
  if(selected.status!==0)throw Error('E6W source signatures unavailable: '+selected.stderr);
  const parsed=JSON.parse(selected.stdout);
  const names=parsed.selected_names;
  assert.equal(names.length,14,'Unexpected selected function name count');
  assert.ok(names.every(n=>/^[a-z][a-z_0-9]*$/.test(n)),'Unsafe function identifier');
  const items=names.map(n=>"('"+n+"')").join(',');
  const q=[
    'BEGIN TRANSACTION READ ONLY;',
    'WITH wanted(name) AS (VALUES '+items+'),',
    ' fn AS (SELECT n.nspname::text||\'.\'||p.proname::text||\'(\'||pg_get_function_identity_arguments(p.oid)||\')\' AS signature,',
    '   p.proname::text AS name,p.prosecdef AS definer,p.prokind::text AS kind,',
    '   pg_get_userbyid(p.proowner) AS owner,',
    '   r.rolsuper AS owner_superuser,r.rolbypassrls AS owner_bypassrls,',
    '   p.proconfig AS search_settings,p.proacl::text AS explicit_acl,',
    '   md5(pg_get_functiondef(p.oid)) AS definition_md5_comparison_only,',
    '   p.pronargdefaults AS default_argument_count,',
    "   has_function_privilege('anon',p.oid,'EXECUTE') AS anon_execute,",
    "   has_function_privilege('authenticated',p.oid,'EXECUTE') AS authenticated_execute,",
    "   has_function_privilege('service_role',p.oid,'EXECUTE') AS service_execute,",
    '   has_function_privilege(\'public\',p.oid,\'EXECUTE\') AS public_execute',
    '   FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace',
    '   JOIN pg_roles r ON r.oid=p.proowner',
    "   WHERE n.nspname='public' AND p.proname IN (SELECT name FROM wanted)),",
    ' tables AS (SELECT n.nspname::text AS schema_name,c.relname::text AS table_name,',
    '   c.relkind::text AS relkind,c.relrowsecurity AS rls_enabled,',
    '   c.relforcerowsecurity AS force_rls,c.relacl::text AS table_acl,',
    '   md5(coalesce((SELECT string_agg(a.attname::text||\':\'||coalesce(a.attacl::text,\'<none>\'),\'|\' ORDER BY a.attnum)',
    '      FROM pg_attribute a WHERE a.attrelid=c.oid AND a.attnum>0 AND NOT a.attisdropped),\'\')) AS column_acl_md5',
    '   FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace',
    "   WHERE n.nspname='public' AND c.relkind IN ('r','p')),",
    ' policies AS (SELECT n.nspname::text AS schema_name,c.relname::text AS table_name,',
    '   p.polname::text AS policy_name,p.polcmd::text AS command,p.polpermissive AS permissive,',
    "   md5(coalesce(pg_get_expr(p.polqual,p.polrelid),'')) AS using_md5,",
    "   md5(coalesce(pg_get_expr(p.polwithcheck,p.polrelid),'')) AS check_md5,",
    '   (SELECT coalesce(jsonb_agg(coalesce(r.rolname::text,\'PUBLIC\') ORDER BY coalesce(r.rolname::text,\'PUBLIC\')),\'[]\'::jsonb)',
    '    FROM unnest(p.polroles) AS x(oid) LEFT JOIN pg_roles r ON r.oid=x.oid) AS policy_roles',
    '   FROM pg_policy p JOIN pg_class c ON c.oid=p.polrelid',
    '   JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname=\'public\'),',
    ' memberships AS (SELECT pg_get_userbyid(m.member) AS member_name,',
    '   pg_get_userbyid(m.roleid) AS member_of, m.admin_option, m.inherit_option,m.set_option',
    '   FROM pg_auth_members m',
    "   WHERE pg_get_userbyid(m.member) IN ('anon','authenticated','service_role','postgres','supabase_admin')),",
    ' defaults AS (SELECT pg_get_userbyid(d.defaclrole) AS role_name,',
    '   coalesce(n.nspname::text,\'<global>\') AS schema_name,',
    '   d.defaclobjtype::text AS object_kind,d.defaclacl::text AS acl',
    '   FROM pg_default_acl d LEFT JOIN pg_namespace n ON n.oid=d.defaclnamespace),',
    ' selected_roles AS (SELECT rolname::text AS name,rolsuper AS superuser,',
    '   rolbypassrls AS bypass_rls,rolinherit AS inherit,rolcanlogin AS can_login,',
    '   rolcreaterole AS can_create_role',
    "   FROM pg_roles WHERE rolname IN ('anon','authenticated','service_role','postgres','supabase_admin'))",
    ' SELECT jsonb_build_object(',
    " 'engine',jsonb_build_object('version',current_setting('server_version'),",
    "  'version_num',current_setting('server_version_num')),",
    " 'extensions',(SELECT coalesce(jsonb_agg(jsonb_build_object('name',extname,'version',extversion) ORDER BY extname),'[]'::jsonb)",
    '   FROM pg_extension),',
    " 'functions',(SELECT coalesce(jsonb_agg(to_jsonb(fn) ORDER BY signature),'[]'::jsonb) FROM fn),",
    " 'roles',(SELECT coalesce(jsonb_agg(to_jsonb(sr) ORDER BY name),'[]'::jsonb) FROM selected_roles sr),",
    " 'role_memberships',(SELECT coalesce(jsonb_agg(to_jsonb(m) ORDER BY member_name,member_of),'[]'::jsonb) FROM memberships m),",
    " 'schemas',(SELECT coalesce(jsonb_agg(jsonb_build_object('name',nspname,'acl',nspacl::text,",
    "  'anon_usage',has_schema_privilege('anon',oid,'USAGE'),",
    "  'authenticated_usage',has_schema_privilege('authenticated',oid,'USAGE'),",
    "  'service_usage',has_schema_privilege('service_role',oid,'USAGE')) ORDER BY nspname),'[]'::jsonb)",
    "  FROM pg_namespace WHERE nspname IN ('public','auth','storage')),",
    " 'public_tables',(SELECT coalesce(jsonb_agg(to_jsonb(t) ORDER BY schema_name,table_name),'[]'::jsonb) FROM tables t),",
    " 'public_policies',(SELECT coalesce(jsonb_agg(to_jsonb(p) ORDER BY schema_name,table_name,policy_name),'[]'::jsonb) FROM policies p),",
    " 'default_privileges',(SELECT coalesce(jsonb_agg(to_jsonb(d) ORDER BY role_name,schema_name,object_kind),'[]'::jsonb) FROM defaults d)",
    ' )::text;',
    'COMMIT;'
  ].join('\n');
  // This SQL is a SELECT on PostgreSQL system catalogues only. It does not
  // SELECT from public application tables or any identity provider table.
  const env={...process.env};
  if(process.platform==='win32')
    env.DOCKER_HOST='npipe:////./pipe/dockerDesktopLinuxEngine';
  const r=spawnSync('docker',['exec','-i','supabase_db_wantok-service',
    'psql','-X','-U','postgres','-d','postgres','-At','-v','ON_ERROR_STOP=1','-P','pager=off'],
    {input:q,encoding:'utf8',env,timeout:60000,maxBuffer:8000000});
  if(r.status!==0)throw Error('E6X READ ONLY PostgreSQL catalog unavailable: '+(r.stderr??'').slice(-650));
  const json=r.stdout.split(/\r?\n/).find(x=>x.startsWith('{'));
  assert.ok(json,'No JSON from catalog transaction');
  const metadata=JSON.parse(json);
  const snapshot=makeSnapshot(metadata);
  assertShape(snapshot);
  assert.equal(snapshot.metadata.functions.length,14,'Unexpected overloads/missing functions in local baseline');
  const two=snapshot.metadata.functions.filter(f=>['write_audit_event','enqueue_notification'].includes(f.name));
  assert.equal(two.length,2,'Missing internal writer signatures');
  console.log(JSON.stringify(snapshot,null,2));
}
function loadSnapshot(path){
  const b=readFileSync(path);
  const utf16le=b.length>=2&&b[0]===0xff&&b[1]===0xfe;
  const data=utf16le?b.subarray(2).toString('utf16le'):b.toString('utf8');
  return JSON.parse(data.replace(/^\uFEFF/,''));
}
function cli(){
  const args=process.argv.slice(2);
  if(args.length===1&&args[0]==='--local')return runLocal();
  if(args.length===3&&args[0]==='--compare'){
    const a=loadSnapshot(args[1]);
    const b=loadSnapshot(args[2]);
    const result=compare(a,b);
    console.log(JSON.stringify(result,null,2));
    if(!result.metadata_identical)process.exitCode=3; // Drift must not report CLI success.
    return;
  }
  console.error('Usage: node scripts/qa/e6x-g8-parity-snapshot.mjs --local | --compare reference.json candidate.json');
  process.exitCode=2;
}
if(process.argv[1]&&process.argv[1].replaceAll('\\','/').endsWith('/e6x-g8-parity-snapshot.mjs')){
  try{cli();}catch(e){console.error('E6X_BLOCKED: '+e.message);process.exitCode=1;}
}
