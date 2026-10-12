import test from 'node:test';
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {mkdtempSync,writeFileSync,rmSync} from 'node:fs';
import {join} from 'node:path';
import {tmpdir} from 'node:os';
import {makeSnapshot,compare,assertShape,digest} from './e6x-g8-parity-snapshot.mjs';

function fixture(){
 return {
  engine:{version:'17.11',version_num:'170011'},
  extensions:[{name:'pgcrypto',version:'1.3'}],
  functions:Array.from({length:14},(_,i)=>({
   signature:'public.synthetic_'+i+'()',owner:'postgres',definer:true,
   explicit_acl:'{postgres=X/postgres,anon=X/postgres}',
   owner_bypassrls:true,definition_md5_comparison_only:'abc'+i,
   search_settings:['search_path=public,auth'],anon_execute:true
  })),
  roles:[{name:'anon',bypass_rls:false},{name:'postgres',bypass_rls:true}],
  role_memberships:[],schemas:[{name:'public',acl:'{=U/postgres}'}],
  public_tables:Array.from({length:93},(_,i)=>({table_name:'synthetic_'+i,rls_enabled:true,force_rls:false,column_acl_md5:'abc'})),
  public_policies:Array.from({length:117},(_,i)=>({policy_name:'policy_'+i,using_md5:'abc',check_md5:'def'})),
  default_privileges:[{role_name:'postgres',object_kind:'f',acl:'{anon=X/postgres}'}]
 };
}
function copy(x){return JSON.parse(JSON.stringify(x));}
test('identical metadata compares equal but does not approve G8',()=>{
 const a=makeSnapshot(fixture(),'synthetic-reference');
 const b=makeSnapshot(copy(fixture()),'synthetic-candidate');
 const r=compare(a,b);
 assert.equal(r.metadata_identical,true);
 assert.equal(r.human_G8_accepted,false);
 assert.equal(r.productionApproved,false);
 assert.deepEqual(r.changed_catalog_paths,[]);
});
for(const [name,mutate,location] of [
 ['function owner',m=>m.functions[0].owner='different_owner','functions[0].owner'],
 ['function EXECUTE grant',m=>m.functions[0].explicit_acl='{}','functions[0].explicit_acl'],
 ['RLS policy expression digest',m=>m.public_policies[0].using_md5='different','public_policies[0].using_md5'],
 ['column grant hash',m=>m.public_tables[0].column_acl_md5='different','public_tables[0].column_acl_md5'],
 ['database engine',m=>m.engine.version='17.12','engine.version'],
 ['role trust',m=>m.roles[0].bypass_rls=true,'roles[0].bypass_rls'],
 ['default privileges',m=>m.default_privileges[0].acl='{}','default_privileges[0].acl']
]){
 test('fails closed on '+name,()=>{
  const a=makeSnapshot(fixture(),'synthetic-reference');
  const m=copy(fixture());mutate(m);
  const b=makeSnapshot(m,'synthetic-candidate');
  const r=compare(a,b);
  assert.equal(r.metadata_identical,false);
  assert.ok(r.changed_catalog_paths.includes(location),JSON.stringify(r.changed_catalog_paths));
  assert.equal(r.productionApproved,false);
 });
}
test('tampered stored JSON fingerprint is rejected',()=>{
 const a=makeSnapshot(fixture());
 const b=copy(a);b.metadata.functions[0].owner='forged';
 assert.throws(()=>compare(a,b),/fingerprint mismatch/);
});
test('missing array cannot pass by omission',()=>{
 const a=makeSnapshot(fixture());
 const b=copy(a);delete b.metadata.public_policies;b.fingerprint=digest(b.metadata);
 assert.throws(()=>compare(a,b),/Missing required catalog field/);
});
test('duplicate function signatures cannot pass',()=>{
 const a=makeSnapshot(fixture());
 a.metadata.functions[1].signature=a.metadata.functions[0].signature;
 a.fingerprint=digest(a.metadata);
 assert.throws(()=>assertShape(a),/Duplicate function identity/);
});
test('reference and candidate labels do not substitute stage attestation',()=>{
 const a=makeSnapshot(fixture(),'production-pretend');
 const b=makeSnapshot(fixture(),'stage-pretend');
 assert.equal(compare(a,b).stage_provenance_verified,false);
});

test('CLI returns nonzero when snapshots differ and zero on equality',()=>{
 const dir=mkdtempSync(join(tmpdir(),'wantok-e6x-synthetic-'));
 try{
  const a=makeSnapshot(fixture(),'synthetic-reference');
  const b=makeSnapshot(copy(fixture()),'synthetic-candidate');
  const ref=join(dir,'reference.json'),candidate=join(dir,'candidate.json');
  writeFileSync(ref,JSON.stringify(a));writeFileSync(candidate,JSON.stringify(b));
  const script=new URL('./e6x-g8-parity-snapshot.mjs',import.meta.url).pathname;
  const nodeFile=process.platform==='win32'?decodeURIComponent(script.slice(1)).replaceAll('/','\\'):script;
  const equal=spawnSync(process.execPath,[nodeFile,'--compare',ref,candidate],{encoding:'utf8'});
  assert.equal(equal.status,0,equal.stderr);
  const m=copy(fixture());m.functions[0].owner='wrong';
  writeFileSync(candidate,JSON.stringify(makeSnapshot(m,'synthetic-candidate')));
  const drift=spawnSync(process.execPath,[nodeFile,'--compare',ref,candidate],{encoding:'utf8'});
  assert.equal(drift.status,3,'Comparison drift must cause non-zero CLI exit');
  assert.equal(JSON.parse(drift.stdout).metadata_identical,false);
 }finally{rmSync(dir,{recursive:true,force:true});}
});
