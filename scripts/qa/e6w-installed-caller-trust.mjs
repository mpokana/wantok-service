/**
 * E6W: latest source declaration candidates plus local READ ONLY caller ACL.
 * Does not export installed SQL bodies or read app data.
 * A regex/source inventory is not a formal G7/G8 security acceptance.
 */
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {readFileSync,readdirSync} from 'node:fs';
import {join} from 'node:path';

const dir=join(process.cwd(),'supabase','migrations');
const files=readdirSync(dir).filter(f=>/^\d+_.+\.sql$/.test(f)).sort();
const writers=['write_audit_event','enqueue_notification'];
const latest=new Map(),historic=[],unsupported=[];
for(const file of files){
 const sql=readFileSync(join(dir,file),'utf8');
 const rx=/\bCREATE\s+(?:OR\s+REPLACE\s+)?FUNCTION\s+(?:public\.)?([a-z_]\w*)\s*\(/gi;
 const found=[...sql.matchAll(rx)];
 for(let i=0;i<found.length;i++){
  const m=found[i],name=m[1].toLowerCase();
  const section=sql.slice(m.index,i+1<found.length?found[i+1].index:sql.length);
  const open=/\bAS\s+(\$[a-z_0-9]*\$)/i.exec(section);
  if(!open){unsupported.push({file,name,reason:'dollar body absent'});continue;}
  const start=open.index+open[0].length,end=section.indexOf(open[1],start);
  if(end<0){unsupported.push({file,name,reason:'body terminator absent'});continue;}
  const body=section.slice(start,end);
  const calls=Object.fromEntries(writers.map(w=>[w,
    [...body.matchAll(new RegExp('\\b(?:public\\.)?'+w+'\\s*\\(','gi'))].length]));
  const item={name,file,line:sql.slice(0,m.index).split('\n').length,calls};
  historic.push(item); latest.set(name,item);
 }
}
assert.ok(files.length>0);
for(const name of writers)assert.ok(latest.has(name),'Missing writer declaration '+name);
const sourceCallers=[...latest.values()].filter(f=>Object.values(f.calls).some(Boolean));
assert.ok(sourceCallers.length>0,'Missing known writer call candidates');
const names=[...new Set([...sourceCallers.map(f=>f.name),...writers])].sort();
const base={
 checkpoint:'E6W',scanned_migrations:files.length,parsed_declarations:historic.length,
 declarations_with_unsupported_body:unsupported.length,
 historical_definitions_calling_writers:historic.filter(f=>Object.values(f.calls).some(Boolean)).length,
 latest_source_callers_by_name:sourceCallers,selected_names:names,
 limitations:'Name-keyed last checked-in declaration, including pending SQL; no overload resolution, dynamic SQL or AST.',
 shared_database_modified:false
};
const mode=process.argv[2];
if(process.argv.length!==3||!['--source-only','--local'].includes(mode)){
 console.error('Usage: node scripts/qa/e6w-installed-caller-trust.mjs --source-only|--local');
 process.exit(2);
}
if(mode==='--source-only'){
 console.log(JSON.stringify({...base,mode},null,2));
}else{
 const values=names.map(n=>"('"+n+"')").join(',');
 const q=[
 'BEGIN TRANSACTION READ ONLY;',
 'WITH selected_names(proname) AS (VALUES '+values+'),',
 "w AS (SELECT to_regprocedure('public.write_audit_event(text,text,uuid,jsonb,uuid)') AS audit_oid,",
 " to_regprocedure('public.enqueue_notification(uuid,text,text,text,jsonb,text,text,text)') AS notice_oid),",
 'f AS (SELECT p.oid,p.proname::text AS name,p.prosecdef AS definer,p.prokind AS kind,',
 ' p.proconfig AS settings,p.proacl::text AS explicit_acl,',
 ' pg_get_userbyid(p.proowner) AS owner,r.rolbypassrls AS owner_bypassrls,',
 ' r.rolsuper AS owner_superuser,p.oid::regprocedure::text AS signature,',
 " has_function_privilege('anon',p.oid,'EXECUTE') AS anon_execute,",
 " has_function_privilege('authenticated',p.oid,'EXECUTE') AS authenticated_execute,",
 " has_function_privilege('service_role',p.oid,'EXECUTE') AS trusted_execute,",
 " (CASE WHEN p.proname::text='write_audit_event' THEN false ELSE pg_get_functiondef(p.oid) ~* '(^|[^a-z_0-9])(?:public[.])?write_audit_event[[:space:]]*[(]' END) AS body_mentions_audit,",
 " (CASE WHEN p.proname::text='enqueue_notification' THEN false ELSE pg_get_functiondef(p.oid) ~* '(^|[^a-z_0-9])(?:public[.])?enqueue_notification[[:space:]]*[(]' END) AS body_mentions_notice",
 ' FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace',
 " JOIN pg_roles r ON r.oid=p.proowner WHERE n.nspname='public'",
 ' AND p.proname IN (SELECT proname FROM selected_names)),',
 ' expanded AS (SELECT f.*,',
 " CASE WHEN w.audit_oid IS NULL THEN NULL ELSE has_function_privilege(f.owner,w.audit_oid,'EXECUTE') END AS owner_execute_audit,",
 " CASE WHEN w.notice_oid IS NULL THEN NULL ELSE has_function_privilege(f.owner,w.notice_oid,'EXECUTE') END AS owner_execute_notice",
 ' FROM f CROSS JOIN w)',
 "SELECT jsonb_build_object('functions',coalesce((SELECT jsonb_agg(to_jsonb(e)-'oid' ORDER BY name,signature) FROM expanded e),'[]'::jsonb),",
 " 'selected_count',(SELECT count(*) FROM selected_names),",
 " 'matched_count',(SELECT count(DISTINCT name) FROM expanded),",
 " 'missing',(SELECT coalesce(jsonb_agg(proname),'[]'::jsonb) FROM selected_names",
 " WHERE proname NOT IN (SELECT name FROM expanded)))::text;",
 'COMMIT;'
 ].join('\n');
 const env={...process.env};
 if(process.platform==='win32')env.DOCKER_HOST='npipe:////./pipe/dockerDesktopLinuxEngine';
 const r=spawnSync('docker',['exec','-i','supabase_db_wantok-service',
  'psql','-X','-U','postgres','-d','postgres','-At','-v','ON_ERROR_STOP=1','-P','pager=off'],
  {input:q,encoding:'utf8',env,timeout:45000,maxBuffer:1500000});
 if(r.status!==0)throw Error('Read-only local catalog failed: '+(r.stderr??'').slice(-600));
 const line=(r.stdout??'').split(/\r?\n/).find(s=>s.startsWith('{'));
 assert.ok(line,'Expected catalog JSON');
 const catalog=JSON.parse(line);
 assert.equal(catalog.selected_count,names.length);
 assert.deepEqual(catalog.missing,[],'Source name missing in installed catalog');
 assert.equal(catalog.functions.filter(f=>writers.includes(f.name)).length,2);
 const installedCallers=catalog.functions.filter(f=>sourceCallers.some(c=>c.name===f.name));
 assert.equal(installedCallers.length,sourceCallers.length,'Overload or installed caller mismatch: independent review required');
 assert.ok(installedCallers.every(f=>f.body_mentions_audit||f.body_mentions_notice),
   'Installed caller text does not match selected latest-source writer calls');
 console.log(JSON.stringify({...base,mode,
  installed_local_catalog:catalog,
  body_exported:false,app_rows_read:false,
  direct_rest_or_gotrue_tested:false,stage_owner_acl_parity_verified:false,
  human_g7_g8_signoffs:0,production_approved:false,
  interpretation:'Only Boolean regexp tests on pg_get_functiondef and pg_catalog owner/ACL metadata; no installed SQL body exported; not verified executable call graph.'
 },null,2));
}
