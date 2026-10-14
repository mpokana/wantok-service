/**
 * CX1O: offline safeguard for the toy PostgreSQL security experiment.
 * No network, DB, privileged tokens or Docker calls.
 * These are source-shape regression tests, not auth/role parity.
 */
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {dirname,resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import test from 'node:test';
const dir=dirname(fileURLToPath(import.meta.url));
const fixture=readFileSync(resolve(dir,'cx1o-disposable-track-fixture.sql'),'utf8');
const tests=readFileSync(resolve(dir,'cx1o-disposable-track-assertions.sql'),'utf8');
const runner=readFileSync(resolve(dir,'cx1o-disposable-track-stage.ps1'),'utf8');
const candidate=()=>{
  const match=fixture.match(/CREATE OR REPLACE FUNCTION public\.list_my_track_bookings_candidate\(\)([\s\S]*?)\$func\$;/);
  assert.ok(match, 'candidate SQL absent');
  return match[0];
};
export function guardFixture(src){
  const match=src.match(/CREATE OR REPLACE FUNCTION public\.list_my_track_bookings_candidate\(\)([\s\S]*?)\$func\$;/);
  assert.ok(match, 'candidate function absent');
  const sql=match[0];
  assert.match(sql,/STABLE SECURITY INVOKER/, 'SQL must not gain definer rights');
  assert.match(sql,/WHERE auth\.uid\(\) IS NOT NULL AND b\.customer_id = auth\.uid\(\)/,'mandatory server-derived actor');
  assert.match(sql,/LIMIT 100\b/, 'bounded output');
  assert.match(sql,/RETURNS TABLE \(booking_id uuid, booking_status text, scheduled_start timestamptz, created_at timestamptz\)/,
    'four-column output only');
  assert.doesNotMatch(sql,/SECURITY DEFINER|SELECT \*|beneficiary_email|service_address|b\.notes|p_user_id|p_customer_id/i,
    'unexpected sensitive or broad contract');
  return true;
}
export function guardRunner(src){
  assert.match(src,/--network none/, 'network must stay disconnected');
  assert.match(src,/--tmpfs '\/var\/lib\/postgresql\/data:rw,size=256m'/,'volatile storage required');
  assert.match(src,/\$net -ne 'none'/, 'fail-closed network inspect required');
  assert.match(src,/\$ports -notin/, 'published port inspect required');
  assert.match(src,/\$mounts -ne '\[\]'/, 'mount inspect required');
  assert.match(src,/finally\s*\{[\s\S]*?docker stop/, 'cleanup required');
  assert.doesNotMatch(src,/docker (?:cp|exec)\s+(?:\$source|supabase_db_wantok-service)/,
    'shared DB connection forbidden');
  const launch=src.split('\n').find(line=>line.includes('& docker run '));
  assert.ok(launch, 'Docker launch line must exist');
  assert.doesNotMatch(launch,/\s(?:-p|--publish|-v|--volume)\s/, 'external ports or volumes forbidden');
  return true;
}
test('01 candidate narrow secure invoker contract',()=>assert.equal(guardFixture(fixture),true));
test('02 runner no network, ports, source, mounts',()=>assert.equal(guardRunner(runner),true));
test('03 synthetic claim stub is explicitly not verified GoTrue',()=>{
  assert.match(fixture,/request\.jwt\.claim\.sub/);
  assert.match(fixture,/NOT a verified GoTrue JWT/);
});
test('04 source explicitly models provider + admin bypass of raw table',()=>{
  assert.match(fixture,/customer_id = auth\.uid\(\) OR provider_id = auth\.uid\(\) OR public\.is_admin\(auth\.uid\(\)\)/);
  assert.match(fixture,/stage_booking_qualified_provider/);
});
test('05 assertion suite covers separate clients',()=>{
  for(const x of ['A sees bounded 100','B sees only its two','A cannot see B','provider raw-RLS','qualified-provider open-request','admin legacy raw-read','valid no-booking actor'])
    assert.ok(tests.includes(x),x);
});
test('06 assertion suite checks anonymous and private fields',()=>{
  assert.match(tests,/anonymous execute denied/);
  assert.match(tests,/omits synthetic private fields/);
  assert.match(tests,/missing actor identity/);
});
test('07 source drift: eliminate actor predicate',()=>{
  assert.throws(()=>guardFixture(fixture.replace('b.customer_id = auth.uid()', 'b.provider_id IS NOT NULL')),/mandatory server-derived actor/);
});
test('08 source drift: remove invoker',()=>{
  assert.throws(()=>guardFixture(fixture.replace('STABLE SECURITY INVOKER','STABLE SECURITY DEFINER')),/definer rights/);
});
test('09 source drift: widen page',()=>{
  assert.throws(()=>guardFixture(fixture.replace('LIMIT 100','LIMIT 100000')),/bounded output/);
});
test('10 source drift: inject private column',()=>{
  assert.throws(()=>guardFixture(fixture.replace('booking_status text, scheduled_start','beneficiary_email text, booking_status text, scheduled_start')),/four-column/);
});
test('11 source drift: network-enabled Docker',()=>{
  assert.throws(()=>guardRunner(runner.replace('--network none','--network bridge')),/network must stay disconnected/);
});
test('12 source drift: allow host-mounted volume',()=>{
  assert.throws(()=>guardRunner(runner.replace('--network none --memory','--network none -v C:/tmp:/tmp --memory')),/external ports or volumes forbidden/);
});
test('13 source drift: omit cleanup',()=>{
  assert.throws(()=>guardRunner(runner.replace('docker stop --time 3','docker nonsense --time 3')),/cleanup required/);
});
test('14 source drift: drop mount inspection',()=>{
  assert.throws(()=>guardRunner(runner.replace("$mounts -ne '[]'","$mounts -ne 'anything'")),/mount inspect required/);
});
