/**
 * E6V: source-only dependency inventory for E6O shared internal writers.
 * This is a lexical map across historical SQL and app source, NOT a live call graph.
 * Never contacts a database, REST API, or private user data.
 */
import assert from 'node:assert/strict';
import {existsSync, readdirSync, readFileSync} from 'node:fs';
import {join, relative} from 'node:path';

const root=process.cwd();
const migrations=join(root,'supabase','migrations');
const writers=['write_audit_event','enqueue_notification'];
const migrationFiles=readdirSync(migrations)
  .filter(name=>/^\d+_.+\.sql$/.test(name)).sort();
const sourceHits=[];
const declarations=[];
const aclStatements=[];
let matchedMigrationFiles=0;
for(const file of migrationFiles){
  const lines=readFileSync(join(migrations,file),'utf8').split(/\r?\n/);
  let activeFunction=null;
  let inAcl=false;
  let fileHasMatch=false;
  for(let index=0;index<lines.length;index++){
    const line=lines[index],trimmed=line.trim();
    const start=/^CREATE\s+(?:OR\s+REPLACE\s+)?FUNCTION\s+(?:public\.)?([a-z_][\w]*)\s*\(/i.exec(trimmed);
    if(start)activeFunction=start[1].toLowerCase();
    if(/^\s*--/.test(line))continue;
    if(/^(?:GRANT|REVOKE|ALTER FUNCTION|COMMENT ON FUNCTION)\b/i.test(trimmed))inAcl=true;
    const calls=[...line.matchAll(/\b(?:public\.)?(write_audit_event|enqueue_notification)\s*\(/gi)];
    for(const m of calls){
      const name=m[1].toLowerCase();
      fileHasMatch=true;
      const hit={writer:name,file,line:index+1};
      if(start&&start[1].toLowerCase()===name){
        declarations.push(hit);
      }else if(inAcl){
        aclStatements.push({...hit,action:trimmed.split(/\s+/)[0].toUpperCase()});
      }else{
        sourceHits.push({...hit,nearest_function_heading:activeFunction,
          // Best-effort only; SQL may include dynamic text, nested literals or old migrations.
          classification:activeFunction?'candidate nested SQL call':'unclassified SQL mention'});
      }
    }
    if(inAcl&&trimmed.includes(';'))inAcl=false;
    if(/^\$[A-Za-z_0-9]*\$;\s*$/.test(trimmed))activeFunction=null;
  }
  if(fileHasMatch)matchedMigrationFiles++;
}
assert.ok(migrationFiles.length>0,'Expected migrations');
for(const name of writers)assert.ok(declarations.some(d=>d.writer===name),
  'Writer declaration missing: '+name);
const correction='20261012152000_e6_shared_internal_rpc_execute_boundary.sql';
assert.ok(migrationFiles.includes(correction),'Expected source-only E6O correction is missing');
const correctionText=readFileSync(join(migrations,correction),'utf8');
for(const name of writers){
  assert.ok(new RegExp('REVOKE\\s+ALL\\s+ON\\s+FUNCTION\\s+public\\.'+name+'\\s*\\(','i').test(correctionText),
    'Expected E6O restriction missing for '+name);
}
const appHits=[];
const scanDirs=['apps','packages'];
function scan(dir){
  for(const item of readdirSync(dir,{withFileTypes:true})){
    if(item.isDirectory()){
      if(!['node_modules','.git','.dart_tool','.next','build','dist','coverage'].includes(item.name))
        scan(join(dir,item.name));
      continue;
    }
    if(!item.isFile()||!/\.(?:dart|ts|tsx|js|jsx|mjs|cjs)$/.test(item.name))continue;
    const path=join(dir,item.name);
    const lines=readFileSync(path,'utf8').split(/\r?\n/);
    for(let i=0;i<lines.length;i++){
      for(const writer of writers)
        if(new RegExp('\\b'+writer+'\\b').test(lines[i]))
          appHits.push({writer,file:relative(root,path).replace(/\\/g,'/'),line:i+1});
    }
  }
}
for(const folder of scanDirs){
  const dir=join(root,folder);
  if(existsSync(dir))scan(dir);
}
const perWriter=Object.fromEntries(writers.map(name=>[name,{
  declaration_references:declarations.filter(h=>h.writer===name).length,
  historical_sql_call_candidates:sourceHits.filter(h=>h.writer===name).length,
  sql_acl_references:aclStatements.filter(h=>h.writer===name).length,
  app_source_named_references:appHits.filter(h=>h.writer===name).length
}]));
const result={
  audit:'E6V privileged internal writer historical dependency/compatibility inventory',
  scope:'All checked-in SQL migrations and app source; lexical, not current SQL AST or live call graph',
  checked_migration_files:migrationFiles.length,
  matched_migration_files:matchedMigrationFiles,
  writer_counts:perWriter,
  candidate_sql_call_sites:sourceHits,
  app_named_references:appHits,
  correction_source_present:true,
  migration_applied_to_shared_database:false,
  direct_http_or_gotrue_tested:false,
  trusted_worker_notification_delivery_tested:false,
  g7_g8_human_approval:false,
  known_limitations:[
    'Historical migrations include superseded function versions and trigger bodies',
    'Nearest CREATE FUNCTION heading is an approximation, not verified ownership/privilege context',
    'Lexical matches may include comments and strings, miss dynamic SQL and indirect process calls',
    'A SECURITY DEFINER nested caller may retain owner privileges after a direct-call REVOKE; test with real roles in approved parity stage',
    'Enqueue notification delivery and outbox processing require separate worker and REST witnesses',
    'Current local writer EXECUTE grants remain open pending separately authorised mitigation'
  ]
};
console.log(JSON.stringify(result,null,2));
