/**
 * E6R SQL-source role-helper callsite catalogue, non-mutating.
 * Lexical only: not a SQL parser and not an executable auth safety proof.
 * Includes old/superseded migrations, RLS and SQL function bodies.
 * Outputs no records, keys, secrets, or personal data.
 */
import {readdirSync,readFileSync} from 'node:fs';
import {join,relative} from 'node:path';
import assert from 'node:assert/strict';

const names=[
 'has_role','is_admin','is_technical_platform_admin','has_platform_permission',
 'has_technical_permission','effective_technical_access_level',
 'can_access_technical_console','can_manage_technical_module_access'
];
const namesSet=new Set(names);
const cwd=process.cwd();
const root=join(cwd,'supabase','migrations');
const migrationFiles=readdirSync(root).filter(x=>/^\d+_.+\.sql$/.test(x)).sort();
let all=[];
let declarations=[];
function callsIn(text) {
 const rx=/\b(?:public\.)?(has_role|is_admin|is_technical_platform_admin|has_platform_permission|has_technical_permission|effective_technical_access_level|can_access_technical_console|can_manage_technical_module_access)\s*\(/gi;
 const found=[];let m;
 while((m=rx.exec(text)))found.push({name:m[1].toLowerCase(),column:m.index});
 return found;
}
for (const file of migrationFiles) {
 const lines=readFileSync(join(root,file),'utf8').split(/\r?\n/);
 let section='unclassified SQL';
 let insideAclDdl=false;
 for(let i=0;i<lines.length;i++){
  const line=lines[i], trimmed=line.trim();
  // Skip both single-line and multi-line ACL/DDL references, as they do not invoke
  // the helper. Still lexical; other SQL text may contain ambiguous references.
  if(insideAclDdl) {if(trimmed.includes(';')) insideAclDdl=false;continue;}
  if(/^(?:--|GRANT |REVOKE |ALTER FUNCTION |DROP FUNCTION |COMMENT ON )/i.test(trimmed)){
   if(!trimmed.startsWith('--')&&!trimmed.includes(';'))insideAclDdl=true;
   continue;
  }
  if(/^CREATE\s+(?:OR\s+REPLACE\s+)?FUNCTION\s+/i.test(trimmed)){
   section=trimmed.slice(0,125).replace(/\s+/g,' ');
  } else if(/^CREATE\s+(?:OR\s+REPLACE\s+)?(?:POLICY|VIEW|TRIGGER)\s+/i.test(trimmed)){
   section=trimmed.slice(0,125).replace(/\s+/g,' ');
  }
  const matches=callsIn(line);
  for(const m of matches){
   const isDefinition=/^CREATE\s+(?:OR\s+REPLACE\s+)?FUNCTION\s+/i.test(trimmed);
   if(isDefinition){declarations.push({name:m.name,file,line:i+1});continue;}
   const following=lines.slice(i,Math.min(i+5,lines.length)).join(' ');
   const excerpt=following.slice(m.column).slice(0,170).replace(/\s+/g,' ').trim();
   const explicitPrincipal=/\bauth\.uid\s*\(\s*\)/i.test(excerpt);
   const variablePrincipal=/\b(?:p_user_id|v_user_id|p_actor_id|v_actor_id|p_staff_user_id|v_staff_user_id)\b/i.test(excerpt);
   const caller=explicitPrincipal?'explicit auth.uid() in local excerpt':
    variablePrincipal?'variable user ID in local excerpt':'argument unresolved / default';
   all.push({name:m.name,file,line:i+1,section,caller,excerpt});
  }
 }
}
assert.ok(migrationFiles.length>0,'No migrations');
for(const n of names)assert.ok(declarations.some(x=>x.name===n),'Missing helper declaration '+n);
const byHelper=Object.fromEntries(names.map(n=>[n,{
 declarations:declarations.filter(x=>x.name===n).length,
 source_call_references:all.filter(x=>x.name===n).length,
 subject_variable_mentions:all.filter(x=>x.name===n&&x.caller.startsWith('variable')).length,
 explicit_auth_uid_mentions:all.filter(x=>x.name===n&&x.caller.startsWith('explicit')).length,
 unresolved:all.filter(x=>x.name===n&&x.caller.startsWith('argument')).length
}]));
const variable=all.filter(x=>x.caller.startsWith('variable'));
const known=all.filter(x=>/taxi_delegated_booking\.sql$/.test(x.file)&&x.name==='is_admin');
const externalRoots=[join(cwd,'apps'),join(cwd,'packages')];
let appNamedStrings=[];
function walk(dir){
 for(const d of readdirSync(dir,{withFileTypes:true})){
  if(d.isDirectory()) {
   if(!['node_modules','.dart_tool','build','.git','.next'].includes(d.name))walk(join(dir,d.name));
  }else if(d.isFile()&&/\.(dart|ts|tsx|js|mjs)$/.test(d.name)){
   const src=readFileSync(join(dir,d.name),'utf8'), lines=src.split(/\r?\n/);
   lines.forEach((line,i)=>{
    for(const n of names)if(new RegExp('\\b'+n+'\\b').test(line))
      appNamedStrings.push({helper:n,file:relative(cwd,join(dir,d.name)).replace(/\\/g,'/'),line:i+1});
   });
  }
 }
}
for(const dir of externalRoots)walk(dir);
const report={
 scope:'Source-only SQL lexical map; all migrations INCLUDING superseded history. Cannot prove current call graph, SQL AST or RPC exposure.',
 checked_migration_files:migrationFiles.length,
 checked_helpers:names.length,
 helper_counts:byHelper,
 reference_total:all.length,
 source_variable_subject_references:variable,
 delegated_ride_subject_usage:known,
 app_named_references:appNamedStrings,
 unclassified_call_count:all.filter(x=>x.caller.startsWith('argument')).length,
 notes:[
  'auth.uid() and a variable ID in the same excerpt are classified auth.uid() even if actual argument differs',
  'Line-level regex cannot parse multiline argument trees, RLS/SQL ASTs, comments, dynamic SQL or current vs old functions',
  'Authorization decisions must bind the trusted caller where applicable; explicit subject helper queries can leak role metadata',
  'Cross-user helper grants observed separately in local pg_catalog; real PostgREST and GoTrue evidence requires independent G7/G8 stage'
 ],
 shared_database_access:false,
 shared_database_writes:false,
 human_G8_approved:false
};
console.log(JSON.stringify(report,null,2));
