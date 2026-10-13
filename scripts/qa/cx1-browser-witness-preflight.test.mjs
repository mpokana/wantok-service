import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync,writeFileSync,mkdtempSync,rmSync} from 'node:fs';
import {join} from 'node:path';
import {tmpdir} from 'node:os';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import {verifyMatrix} from './cx1-browser-witness-preflight.mjs';

const file='docs/CX1C_BROWSER_REFRESH_WITNESS_MATRIX_20261013.json';
const baseline=JSON.parse(readFileSync(file,'utf8'));
function copy(x=baseline){return structuredClone(x);}
function observeAll(m){
 m.provenance='HUMAN_ENTERED_BROWSER_WITNESS';
 m.route_anomaly.state='REVIEWED_NO_REPEAT';
 m.route_anomaly.current_live_recheck=true;
 m.route_anomaly.private_evidence_digest_sha256='a'.repeat(64);
 m.cases.forEach(c=>{
  c.state='OBSERVED';
  c.capture_source='ACTUAL_SIGNED_IN_CHROME_WINDOW';
  c.signed_in_session_observed=true;
  c.client_window_verified=true;
  c.refresh_label_visible=true;
  c.centre_click_performed=true;
  c.before_route='Client>'+c.area;
  c.after_route='Client>'+c.area;
  c.before_count=1;c.after_count=1;
  c.unexpected_vendor_onboarding=false;
  c.release_js_sha256='a'.repeat(64);
  c.private_evidence_sha256='b'.repeat(64);
  c.observer_attestation='SYNTHETIC_EXAMPLE_NEVER_A_REAL_WITNESS';
 });
 return m;
}
test('source baseline refuses automatic acceptance for all six pending cases',()=>{
 const r=verifyMatrix(copy());
 assert.equal(r.cases_expected,6);
 assert.equal(r.cases_not_executed,6);
 assert.equal(r.ready_for_independent_human_CX1_review,false);
 assert.equal(r.formal_CX1_accepted,false);
 assert.equal(r.productionApproved,false);
});
test('blocked runtime remains blocked even with other historical source success',()=>{
 const m=copy();m.cases[0].state='BLOCKED_ENV';
 const r=verifyMatrix(m);
 assert.equal(r.cases_blocked,1);
 assert.equal(r.ready_for_independent_human_CX1_review,false);
});
test('all six synthetic-shaped witnesses never grant a human signoff',()=>{
 const r=verifyMatrix(observeAll(copy()));
 assert.equal(r.ready_for_independent_human_CX1_review,true);
 assert.equal(r.browser_evidence_authenticity_verified,false);
 assert.equal(r.human_observer_identity_verified,false);
 assert.equal(r.formal_CX1_accepted,false);
 assert.equal(r.productionApproved,false);
});
test('wrong Vendor Onboarding after a tap blocks readiness and tracks anomaly',()=>{
 const m=observeAll(copy());
 m.cases[0].unexpected_vendor_onboarding=true;
 const r=verifyMatrix(m);
 assert.equal(r.cases_with_route_or_count_mismatch,1);
 assert.equal(r.ready_for_independent_human_CX1_review,false);
});
test('route change or record count mismatch blocks readiness',()=>{
 const m=observeAll(copy());
 m.cases[2].after_route='Vendor Onboarding';
 m.cases[4].after_count=2;
 const r=verifyMatrix(m);
 assert.equal(r.cases_with_route_or_count_mismatch,2);
 assert.equal(r.ready_for_independent_human_CX1_review,false);
});
test('old unresolved route anomaly cannot be silently marked ready',()=>{
 const m=observeAll(copy());
 m.route_anomaly.state='UNRESOLVED';
 m.route_anomaly.cause_confirmed=false;
 const r=verifyMatrix(m);
 assert.equal(r.ready_for_independent_human_CX1_review,false);
});
test('historical or widget capture cannot masquerade as live browser evidence',()=>{
 const m=observeAll(copy());
 m.cases[0].capture_source='FLUTTER_WIDGET_TEST';
 assert.throws(()=>verifyMatrix(m),/Widget\/static\/mocked/);
});
test('missing private evidence hash fails closed',()=>{
 const m=observeAll(copy());
 m.cases[1].private_evidence_sha256=null;
 assert.throws(()=>verifyMatrix(m),/Private evidence hash/);
});
test('fake approval is rejected even if all other fields look complete',()=>{
 const m=observeAll(copy());
 m.formal_acceptance=true;
 assert.throws(()=>verifyMatrix(m),/Script cannot confer human signoff/);
});
test('unverified signed-in session fails closed',()=>{
 const m=observeAll(copy());
 m.cases[0].signed_in_session_observed=false;
 assert.throws(()=>verifyMatrix(m),/Real session/);
});
test('missing or duplicated viewport area is rejected',()=>{
 const m=copy();
 m.cases[1].id=m.cases[0].id;
 assert.throws(()=>verifyMatrix(m),/Missing, duplicate/);
});
test('current baseline CLI returns 2 with nonapproval summary (not zero)',()=>{
 const script=fileURLToPath(new URL('./cx1-browser-witness-preflight.mjs',import.meta.url));
 const r=spawnSync(process.execPath,[script,'--review',file],{encoding:'utf8',timeout:10000});
 assert.equal(r.status,2,r.stderr);
 const result=JSON.parse(r.stdout);
 assert.equal(result.cases_not_executed,6);
 assert.equal(result.productionApproved,false);
});
test('invalid external input returns failure instead of approval',()=>{
 const folder=mkdtempSync(join(tmpdir(),'wantok-cx1c-fixture-'));
 try{
  const path=join(folder,'bad.json');
  writeFileSync(path,'{"schema":"wrong"}');
  const script=fileURLToPath(new URL('./cx1-browser-witness-preflight.mjs',import.meta.url));
  const r=spawnSync(process.execPath,[script,'--review',path],{encoding:'utf8',timeout:10000});
  assert.equal(r.status,1,r.stderr);
  assert.match(r.stderr,/CX1C_WITNESS_BLOCKED/);
 }finally{rmSync(folder,{force:true,recursive:true});}
});
