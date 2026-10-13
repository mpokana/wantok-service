/**
 * CX1C: fail-closed, source-only browser-witness *readiness* checker.
 *
 * This checker never navigates Chrome, accesses auth/session storage,
 * reads user records, calls Supabase, changes app state or approves CX1.
 * Synthetic fixtures can demonstrate the contract, never live evidence.
 */
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {fileURLToPath} from 'node:url';

export const BASELINE = '91bd63074cb5ea43fc69944836d8d026a4a50306';
export const SCHEMA = 'wantok-cx1c-browser-witness-v1';
const areas = ['Saved', 'Inbox', 'Track'];
const viewports = [
  {viewport:'mobile', viewport_width:320},
  {viewport:'desktop', viewport_width:1440}
];
export const expectedCases = areas.flatMap(area=>viewports.map(
  ({viewport})=>'CX1C-'+area.toUpperCase()+'-'+viewport.toUpperCase()
));
const hashRx=/^[a-f0-9]{64}$/i;
const stateSet=new Set(['NOT_EXECUTED','BLOCKED_ENV','OBSERVED']);
const permittedCapture='ACTUAL_SIGNED_IN_CHROME_WINDOW';
function nonempty(s){return typeof s==='string'&&s.trim().length>0;}
function sha(s){return typeof s==='string'&&hashRx.test(s);}

export function verifyMatrix(matrix) {
  assert.ok(matrix&&typeof matrix==='object'&&!Array.isArray(matrix),'Expected CX1C matrix object');
  assert.equal(matrix.schema,SCHEMA,'Unsupported CX1C schema');
  assert.equal(matrix.source_commit,BASELINE,'Unexpected source baseline; independently rebase on approved commit');
  assert.equal(matrix.formal_acceptance,false,'Script cannot confer human signoff');
  assert.equal(matrix.productionApproved,false,'Production remains blocked');
  assert.equal(matrix.scope,'CX1 signed-in Client Web non-mutating Saved Inbox Track Refresh acceptance');
  assert.equal(matrix.environment,'EAGLT02 localhost Client 3000 only; staging 3300 parity separately reviewed');
  assert.ok(Array.isArray(matrix.cases)&&matrix.cases.length===expectedCases.length,'Exactly six cases required');
  assert.deepEqual([...matrix.cases.map(c=>c.id)].sort(),[...expectedCases].sort(),
    'Missing, duplicate or unknown case identity');
  assert.ok(matrix.route_anomaly&&typeof matrix.route_anomaly==='object','Missing route anomaly history');
  assert.ok(['UNRESOLVED','REVIEWED_NO_REPEAT','REPRODUCED'].includes(matrix.route_anomaly.state),
    'Unknown route-anomaly state');
  assert.equal(matrix.route_anomaly.source_date,'2026-10-11');
  if(matrix.route_anomaly.state==='UNRESOLVED') {
    assert.equal(matrix.route_anomaly.cause_confirmed,false,'Cannot invent a resolved root cause');
  }
  let witnessed=0,blocked=0,pending=0,misroutes=0;
  const status=[];
  for(const c of matrix.cases){
    assert.ok(areas.includes(c.area),'Unknown area: '+c.id);
    const v=viewports.find(v=>v.viewport===c.viewport);
    assert.ok(v&&v.viewport_width===c.viewport_width,'Unsupported viewport: '+c.id);
    assert.equal(c.id,'CX1C-'+c.area.toUpperCase()+'-'+c.viewport.toUpperCase());
    assert.ok(stateSet.has(c.state),'Unknown state: '+c.id);
    if(c.state==='OBSERVED'){
      witnessed++;
      assert.equal(matrix.provenance,'HUMAN_ENTERED_BROWSER_WITNESS',
        'An observed case requires real browser witness provenance');
      assert.equal(c.capture_source,permittedCapture,'Widget/static/mocked test cannot witness browser');
      assert.equal(c.signed_in_session_observed,true,'Real session must be witnessed');
      assert.equal(c.client_window_verified,true,'Actual Client window identity required');
      assert.equal(c.refresh_label_visible,true,'Rendered labelled control must be verified');
      assert.equal(c.centre_click_performed,true,'Real centre-click required');
      assert.ok(nonempty(c.before_route)&&nonempty(c.after_route),'Before/after route required');
      assert.ok(Number.isSafeInteger(c.before_count)&&c.before_count>=0,'Before count required');
      assert.ok(Number.isSafeInteger(c.after_count)&&c.after_count>=0,'After count required');
      assert.ok(sha(c.release_js_sha256),'Read-only served Client JS digest required');
      assert.ok(sha(c.private_evidence_sha256),'Private evidence hash required');
      assert.ok(nonempty(c.observer_attestation)&&c.observer_attestation!=='NOT_ASSIGNED',
        'Human observer review identifier required; not automatically verified');
      assert.equal(typeof c.unexpected_vendor_onboarding,'boolean','Explicit anomaly observation required');
      if(c.unexpected_vendor_onboarding||c.before_route!==c.after_route||c.before_count!==c.after_count){
        misroutes++;
      }
    }else{
      if(c.state==='BLOCKED_ENV')blocked++;else pending++;
      assert.equal(c.capture_source,null,'No claimed browser capture without observed action');
      assert.equal(c.signed_in_session_observed,false);
      assert.equal(c.centre_click_performed,false);
      assert.equal(c.private_evidence_sha256,null);
    }
    status.push({id:c.id,status:c.state});
  }
  const anomaly=matrix.route_anomaly;
  if(anomaly.state==='REVIEWED_NO_REPEAT'){
    assert.equal(anomaly.current_live_recheck,true,'No repeat requires live recheck');
    assert.ok(sha(anomaly.private_evidence_digest_sha256),'Evidence digest required for anomaly recheck');
  }
  if(anomaly.state==='REPRODUCED'){
    assert.equal(anomaly.current_live_recheck,true,'Reproduction requires live recheck');
    assert.ok(sha(anomaly.private_evidence_digest_sha256),'Evidence digest required for reproduction');
  }
  const ready=witnessed===6&&misroutes===0&&anomaly.state==='REVIEWED_NO_REPEAT';
  return {
    checkpoint:'CX1C',
    mode:'SOURCE_ONLY_GATE_READINESS',
    cases_expected:6,
    cases_observed:witnessed,
    cases_blocked:blocked,
    cases_not_executed:pending,
    cases_with_route_or_count_mismatch:misroutes,
    previous_vendor_onboarding_issue:anomaly.state,
    ready_for_independent_human_CX1_review:ready,
    human_observer_identity_verified:false,
    browser_evidence_authenticity_verified:false,
    formal_CX1_accepted:false,
    E6_G1_G10_approved:0,
    T24_resumed:false,
    productionApproved:false,
    cases:status
  };
}
const invoked=process.argv[1]&&resolve(process.argv[1])===fileURLToPath(import.meta.url);
if(invoked){
  try{
    const args=process.argv.slice(2);
    if(args.length!==2||args[0]!=='--review')throw Error('usage: node scripts/qa/cx1-browser-witness-preflight.mjs --review <private-or-baseline-matrix.json>');
    const matrix=JSON.parse(readFileSync(args[1],'utf8'));
    const summary=verifyMatrix(matrix);
    console.log(JSON.stringify(summary,null,2));
    if(!summary.ready_for_independent_human_CX1_review)process.exitCode=2;
  }catch(e){console.error('CX1C_WITNESS_BLOCKED: '+e.message);process.exitCode=1;}
}
