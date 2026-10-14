import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {inventory, preflight, validateDecision, decisionFile, sourcePaths} from './cx1n-track-stage-readiness.mjs';

const read = (name) => readFileSync(resolve(import.meta.dirname, '../..', name), 'utf8');
const sealed = JSON.parse(read(decisionFile));
const withEdit = (file, before, after) => (path) => {
  const content = read(path);
  if (path !== file) return content;
  assert.ok(content.includes(before), 'Test needs current source marker: '+before);
  return content.replaceAll(before, after);
};

test('1 source identifies current private Track query and broad legacy policy classes', () => {
  const out = inventory(read);
  assert.equal(out.source_only, true);
  assert.equal(out.observed_policy_classes.length, 4);
});
test('2 sealed decision register has exactly ten unapproved human gates', () => {
  const out = validateDecision(sealed);
  assert.equal(out.open_gates, 10);
  assert.equal(out.endpoint_exposed, false);
});
test('3 preflight always reports blocked, never security acceptance', () => {
  const out=preflight(read);
  assert.equal(out.disposition,'SOURCE_PREPARED_STAGE_BLOCKED');
  assert.equal(out.private_data_read_tested,false);
  assert.equal(out.productionApproved,false);
});
for(const field of ['stageApproved', 'privateTrackApiPublished', 'productionApproved',
  'broadRestAllowed', 'serviceRoleProxyAllowed', 'sharedDatabaseMutationAllowed',
  'tailnetAclMutationAllowed']) {
  test('hard stop when '+field+' changes',()=>{
    assert.throws(()=>validateDecision({...sealed,[field]:true}),/CX1N hard stop/);
  });
}
test('hard stop for human gate claimed approved', ()=>{
  const gates=structuredClone(sealed.gates);
  gates.owner_stage_authority.approved=true;
  assert.throws(()=>validateDecision({...sealed,gates}),/gate unexpectedly approved/);
});
test('hard stop for fabricated human gate witness', ()=>{
  const gates=structuredClone(sealed.gates);
  gates.authentic_gotrue_test_principals.status='PASS';
  assert.throws(()=>validateDecision({...sealed,gates}),/human gate not witnessed/);
});
test('hard stop if any required gate is missing', ()=>{
  const gates=structuredClone(sealed.gates);
  delete gates.direct_54321_host_port_denial;
  assert.throws(()=>validateDecision({...sealed,gates}),/gate list changed/);
});
test('hard stop if source customer filter removed', ()=>{
  assert.throws(()=>inventory(withEdit(sourcePaths.repository,
    ".eq('customer_id', _userId)",".eq('provider_id', _userId)")),/customer filter/);
});
test('hard stop if bounded query limit removed', ()=>{
  assert.throws(()=>inventory(withEdit(sourcePaths.repository,'.limit(100);','.limit(100000);')),/bounded client read/);
});
test('hard stop if sensitive embedded quotes disappear without review', ()=>{
  assert.throws(()=>inventory(withEdit(sourcePaths.repository,'service_quotes(id','other_relation(id')),/embedded service quotes/);
});
test('hard stop if Track loader is replaced', ()=>{
  assert.throws(()=>inventory(withEdit(sourcePaths.track,'_repository.loadMyReservations','_repository.loadMyPublicReservations')),/Track repository binding/);
});
test('hard stop if booking RLS enabling statement absent', ()=>{
  assert.throws(()=>inventory(withEdit(sourcePaths.schema,
    'ALTER TABLE public.service_bookings ENABLE ROW LEVEL SECURITY;',
    '-- RLS missing')),/source RLS/);
});
test('hard stop if provider open-read policy removed', ()=>{
  assert.throws(()=>inventory(withEdit(sourcePaths.schema,
    'CREATE POLICY service_bookings_read_open_for_qualified_providers',
    'CREATE POLICY removed_policy')),/source provider open-request policy/);
});
test('hard stop if authenticated review privacy policy removed', ()=>{
  assert.throws(()=>inventory(withEdit(sourcePaths.reviews,
    'CREATE POLICY service_reviews_authenticated_read',
    'CREATE POLICY removed_review_policy')),/review visibility/);
});
test('hard stop on missing approval state flag', ()=>{
  const copy={...sealed};delete copy.productionApproved;
  assert.throws(()=>validateDecision(copy),/productionApproved/);
});
