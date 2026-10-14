import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
const s=readFileSync(new URL('./cx1s-real-local-gotrue-booking-witness.mjs',import.meta.url),'utf8');
test('01 opt-in local-only invocation and full-backup prerequisite',()=>{
  assert.match(s,/--create-and-test-local-only/);
  assert.match(s,/process\.platform!=='win32'/);
  assert.match(s,/statSync\(backup\)\.size<100000/);
});
test('02 never overwrite existing ownership manifest',()=>{
  assert.match(s,/if\(existsSync\(manifest\)\)issue/);
  assert.match(s,/state\.accounts\.push/);
  assert.match(s,/state\.bookings\.push/);
});
test('03 fixture users are uniquely labelled and invalid-domain only',()=>{
  assert.match(s,/cx1s-.*@example\.invalid/);
  assert.match(s,/cx1s_fixture:marker/);
  assert.doesNotMatch(s,/mansfield\.pokana@gmail\.com/);
});
test('04 booking insert uses authenticated user JWT and permitted columns',()=>{
  assert.match(s,/customer_id:actor\.id,category_id:cat,/);
  assert.doesNotMatch(s,/category_id:cat,status:/);
  assert.match(s,/method:'POST',jwt:actor\.jwt/);
});
test('05 true cross-user negative has independent booking IDs',()=>{
  assert.match(s,/\[\[a,bBooking\],\[b,aBooking\]\]/);
  assert.match(s,/res\.data\.length!==0/);
});
test('06 original Flutter nested source query required to pass for both',()=>{
  assert.match(s,/loadMyReservations/);
  assert.match(s,/if\(responded!==2\)issue/);
});
test('07 cleanup is restricted by created fixture IDs',()=>{
  assert.match(s,/customer_id=eq\.'\+booking\.customer_id/);
  assert.match(s,/account\.email\.startsWith\('cx1s-'\)/);
  assert.match(s,/account\.email\.endsWith\('@example\.invalid'\)/);
  assert.match(s,/await cleanup\(\)/);
});
test('08 no client secrets committed in source',()=>{
  assert.doesNotMatch(s,/eyJ[A-Za-z0-9_-]{40,}|service_role.*:\s*['"][A-Za-z0-9]{20,}/);
  assert.match(s,/console\.log\(JSON\.stringify\(summary/);
});
