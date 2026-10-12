import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {validate} from './e6z-decision-pack-check.mjs';
const p=JSON.parse(readFileSync('docs/E6Z_REMEDIATION_DECISION_REGISTER_20261012.json','utf8'));
const sql=readFileSync('supabase/migrations/20261012152000_e6_shared_internal_rpc_execute_boundary.sql','utf8');
const copy=()=>structuredClone(p);
test('blocked decision pack validates without sign-off',()=>{
 const result=validate(copy(),sql);
 assert.equal(result.status,'DECISION_PACK_VALIDATED_NOT_AUTHORISED');
 assert.equal(result.productionApproved,false);
 assert.equal(result.pending_G7_cases,31);
 assert.equal(result.findings,6);
 assert.equal(result.prerequisites,8);
});
for(const [name,change,rx] of [
 ['invented stage authority',p=>p.stage_authorised=true,/true/],
 ['invented production approval',p=>p.productionApproved=true,/false/],
 ['invented G7 execution',p=>p.g7_executed=31,/31/],
 ['invented privacy decisions',p=>p.privacy_decisions_supplied=5,/0/],
 ['writer issue marked closed',p=>p.security_findings.find(f=>f.id==='E6O-01').state='CLOSED',/Cannot masquerade/],
 ['missing blocker',p=>p.prerequisites.pop(),/deep-equal/],
 ['fake external approval',p=>p.prerequisites[0].status='APPROVED',/blocked/],
 ['unreviewed new finding',p=>p.security_findings.push({id:'EXTRA'}),/deep-equal/]
]){
 test('fail closed: '+name,()=>{
  const mutated=copy();
  change(mutated);
  assert.throws(()=>validate(mutated,sql),rx);
 });
}
test('reject source migration missing audit REVOKE',()=>{
 assert.throws(()=>validate(copy(),sql.replace('REVOKE ALL ON FUNCTION public.write_audit_event','SELECT ALL ON FUNCTION public.write_audit_event')));
});
test('reject source migration omitting anonymous role',()=>{
 assert.throws(()=>validate(copy(),sql.replace('FROM PUBLIC, anon, authenticated;','FROM PUBLIC, authenticated;')));
});
test('reject a purported complete human signoff',()=>{
 const c=copy();c.human_gates_approved=10;assert.throws(()=>validate(c,sql));
});
