/**
 * E6Z fail-closed source-only decision-pack validator.
 * Never contacts a database, exposes tokens, runs migrations or signs a gate.
 * It checks known E6X/E6Y findings and the unapplied E6O migration source.
 */
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
export const expectedIds=['E6O-01','E6Z-F01','E6Z-T01','E6Z-S01','E6Z-R01','E6S-D1-D5'];
export const prerequisiteIds=['AUTH-STAGE','BACKUP-DR','OWNER-ACL','GOTRUE-REST',
 'TRUSTED-WORKER','PRIVACY-D1-D5','DUAL-WITNESS','G1-G10'];

export function validate(pack,source){
  assert.ok(pack&&typeof pack==='object'&&!Array.isArray(pack),'Invalid E6Z pack');
  assert.equal(pack.schema,'wantok-e6z-remediation-decisions-v1');
  assert.equal(pack.checkpoint,'E6Z');
  assert.equal(pack.decision_status,'NOT_AUTHORISED','Only not-authorised decision pack supported');
  assert.equal(pack.productionApproved,false);
  assert.equal(pack.stage_authorised,false);
  assert.equal(pack.independent_signoff,false);
  assert.equal(pack.human_gates_approved,0);
  assert.equal(pack.planned_g7_cases,31);
  assert.equal(pack.g7_executed,0);
  assert.equal(pack.privacy_decisions_supplied,0);
  assert.equal(pack.baseline_commit,'538acc3371d933b609eebcb5f4971c6e71910cd6');
  assert.deepEqual([...pack.security_findings.map(x=>x.id)].sort(),[...expectedIds].sort());
  assert.deepEqual([...pack.prerequisites.map(x=>x.id)].sort(),[...prerequisiteIds].sort());
  for(const entry of pack.security_findings){
    assert.ok(['OPEN','REVIEW_REQUIRED','NOT_TESTED','NOT_SUPPLIED'].includes(entry.state),
      'Cannot masquerade as reviewed: '+entry.id);
    assert.ok(['P0','P1'].includes(entry.priority),'Missing explicit priority '+entry.id);
    assert.ok(entry.evidence&&entry.scope&&entry.impact_risk&&entry.proposed_action);
    assert.ok(Array.isArray(entry.witness_ids)&&entry.witness_ids.length>0);
    assert.ok(Array.isArray(entry.independent_decisions)&&entry.independent_decisions.length>1);
  }
  assert.equal(pack.security_findings.find(x=>x.id==='E6O-01').state,'OPEN');
  assert.equal(pack.security_findings.find(x=>x.id==='E6S-D1-D5').state,'NOT_SUPPLIED');
  assert.ok(pack.prerequisites.every(x=>x.status!=='PASS'&&x.status!=='APPROVED'),
    'External prerequisite must remain blocked');
  assert.ok(pack.constraints.includes('No shared database migrations or ACL changes'));
  assert.ok(pack.references.includes('supabase/migrations/20261012152000_e6_shared_internal_rpc_execute_boundary.sql'));
  // This is only a source integrity indicator, not a review of live permissions.
  const migration=source;
  assert.match(migration,/REVOKE\s+ALL\s+ON\s+FUNCTION\s+public\.write_audit_event\s*\(/i);
  assert.match(migration,/REVOKE\s+ALL\s+ON\s+FUNCTION\s+public\.enqueue_notification\s*\(/i);
  const revokeStatements=[...migration.matchAll(/REVOKE\s+ALL\s+ON\s+FUNCTION\s+public\.\w+\s*\([\s\S]*?;/gi)];
  assert.equal(revokeStatements.length,2,'Unexpected count of E6O function REVOKE statements');
  for(const match of revokeStatements){
    assert.match(match[0],/\bFROM\s+PUBLIC\s*,\s*anon\s*,\s*authenticated\s*;/i,
      'E6O must explicitly revoke for untrusted roles');
  }
  const names=pack.security_findings.map(x=>x.id);
  return {
    checkpoint:'E6Z',
    status:'DECISION_PACK_VALIDATED_NOT_AUTHORISED',
    findings:names.length,
    p0_findings:pack.security_findings.filter(x=>x.priority==='P0').length,
    prerequisites:pack.prerequisites.length,
    blocked_prerequisites:pack.prerequisites.length,
    existing_writer_issue_open:true,
    future_default_acl_review_open:true,
    pending_G7_cases:31,
    G1_G10_approved:0,
    privacy_decisions_supplied:0,
    shared_database_changed:false,
    stage_granted:false,
    productionApproved:false,
    note:'Validating a proposed decision register is not independent security review or deployment authority.'
  };
}
const executed=process.argv[1]&&resolve(process.argv[1])===fileURLToPath(import.meta.url);
if(executed){
 try{
  if(process.argv.length!==2)throw Error('Usage: node scripts/qa/e6z-decision-pack-check.mjs');
  const p=JSON.parse(readFileSync('docs/E6Z_REMEDIATION_DECISION_REGISTER_20261012.json','utf8'));
  const s=readFileSync('supabase/migrations/20261012152000_e6_shared_internal_rpc_execute_boundary.sql','utf8');
  console.log(JSON.stringify(validate(p,s),null,2));
 }catch(e){console.error('E6Z_BLOCKED '+e.message);process.exitCode=1;}
}
