/**
 * E6M: source-only inventory of selected E6 SECURITY DEFINER routines.
 * Static advisory: does NOT prove semantic safety, SQL parsing, production ACLs,
 * or row-level isolation. Does not access a database or credentials.
 */
import assert from 'node:assert/strict';
import {readFileSync,readdirSync} from 'node:fs';
import {join} from 'node:path';

const expected=[
 'admin_set_provider_service_status',
 'configure_operations_provisioner',
 'decide_operations_duty_change',
 'emergency_revoke_vendor_clearance_trusted',
 'has_operations_case_scope',
 'has_operations_clearance_scope',
 'has_operations_scope',
 'has_operations_staged_scope',
 'list_vendor_clearance_status',
 'map_operations_service_category',
 'pause_expired_vendor_clearances',
 'record_operations_case_conflict_trusted',
 'register_operations_case_jurisdiction',
 'register_operations_region',
 'request_operations_duty_change',
 'review_provider_application',
 'revoke_vendor_activation_clearance',
 'submit_vendor_intake_case',
 'triage_vendor_intake_case'
];
const base=join(process.cwd(),'supabase','migrations');
const migrations=readdirSync(base).filter(f=>/^\d+_.+\.sql$/.test(f)).sort();
const current=new Map();
const errors=[];
for(const file of migrations) {
 const source=readFileSync(join(base,file),'utf8');
 const rx=/\bCREATE\s+(?:OR\s+REPLACE\s+)?FUNCTION\s+public\.([a-z_][a-z_\d]*)\s*\(/ig;
 let match;
 while((match=rx.exec(source))) {
  const name=match[1].toLowerCase();
  if(!expected.includes(name)) continue;
  const start=match.index;
  const nextCreate=source.indexOf('CREATE ',rx.lastIndex);
  const closeHeader=source.indexOf('AS $$',rx.lastIndex);
  if(closeHeader<0 || (nextCreate>=0 && nextCreate<closeHeader)) {
   errors.push(`${file}: ${name}: unsupported AS $$ header`);
   continue;
  }
  const bodyBegin=closeHeader+'AS $$'.length;
  const bodyEnd=source.indexOf('$$;',bodyBegin);
  if(bodyEnd<0) {
   errors.push(`${file}: ${name}: unterminated body`);
   continue;
  }
  const header=source.slice(start,bodyBegin);
  const body=source.slice(bodyBegin,bodyEnd);
  const line=source.slice(0,start).split('\n').length;
  const statements=[...body.matchAll(/\b(?:FROM|JOIN|UPDATE|INSERT\s+INTO|DELETE\s+FROM|REFERENCES)\s+(?!ONLY\b)([a-z_][\w$]*(?:\.[a-z_][\w$]*)?)/ig)]
   // Exclude SQL expressions: IS [NOT] DISTINCT FROM value, and
   // INSERT ON CONFLICT DO UPDATE SET (SET is not a table).
   .filter(hit=>!(/\bIS\s+(?:NOT\s+)?DISTINCT\s*$/i.test(body.slice(Math.max(0,hit.index-35),hit.index)) ||
     /^UPDATE\s+SET$/i.test(hit[0])))
   .map(hit=>({clause:hit[0].replace(/\s+/g,' '),target:hit[1],qualified:hit[1].includes('.')}));
  const unqualified=statements.filter(s=>!s.qualified);
  const hasDynamicExecute=/\bEXECUTE\b/i.test(body);
  const usesJwt=/\bauth\.(?:uid|jwt)\s*\(|\brequest\.jwt\.claim|\bcurrent_setting\s*\(/i.test(body);
  const searchPath=(header.match(/\bSET\s+search_path\s*=\s*([^\r\n]+?)\s+AS\s+\$\$/i)??[])[1]?.trim()??null;
  current.set(name,{name,file,line,sql_language:/\bLANGUAGE\s+sql\b/i.test(header),
   security_definer:/\bSECURITY\s+DEFINER\b/i.test(header),
   search_path:searchPath,unqualified_relations:unqualified,
   dynamic_execute:hasDynamicExecute,jwt_identity_or_setting_reference:usesJwt,
   qualified_relations:statements.filter(s=>s.qualified).length,
   source_migration_pending:file.startsWith('20261011233000'),
   body_review_required:true});
  rx.lastIndex=bodyEnd+3;
 }
}
const missing=expected.filter(name=>!current.has(name));
assert.equal(errors.length,0,'Unsupported SQL function definition: '+errors.join(', '));
assert.deepEqual(missing,[],'Selected E6 functions missing from source: '+missing.join(', '));
const rows=expected.map(name=>current.get(name));
const unsafe=rows.filter(r=>!r.security_definer||!r.search_path);
const flagged=rows.filter(r=>r.unqualified_relations.length||r.dynamic_execute);
const report={
 marker:'E6M SOURCE-ONLY STATIC ADVISORY — not signed security approval',
 git_commit_source:'use git rev-parse HEAD at runtime',
 functions_examined:rows.length,
 latest_definition_migration_pending:rows.filter(r=>r.source_migration_pending).map(r=>r.name),
 missing_required_header_controls:unsafe.map(r=>r.name),
 flagged_for_manual_sql_review:flagged.map(r=>({
  name:r.name,location:`${r.file}:${r.line}`,
  unqualified: r.unqualified_relations, dynamic_execute:r.dynamic_execute
 })),
 functions:rows.map(({name,file,line,sql_language,security_definer,search_path,
   qualified_relations,dynamic_execute,unqualified_relations,source_migration_pending})=>({
   name,definition:`${file}:${line}`,language_sql:sql_language,
   security_definer,search_path,qualified_relations,
   unqualified_relation_matches:unqualified_relations,
   dynamic_execute,source_migration_pending
 })),
 warnings:[
  'Static regex source flags are NOT a SQL AST or exhaustiveness guarantee',
  'Qualified tables can still have privileged SQL and caller-identity bugs',
  'Unqualified relation-like tokens can be aliases, CTEs or SQL set functions',
  'The local persistent DB may not include latest source migrations',
  'Function overloads and nonselected definer functions not covered'
 ],
 database_access:false,database_writes:false,
 source_baseline_pass:unsafe.length===0 && flagged.length===0
};
console.log(JSON.stringify(report,null,2));
if(unsafe.length || flagged.length)process.exitCode=1;
