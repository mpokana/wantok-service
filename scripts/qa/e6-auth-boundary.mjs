/**
 * E6G: real HTTP / PostgREST negative-boundary acceptance on LOCAL Supabase only.
 * No user creation, DB writes, secrets printed, real identity, or production URL.
 * Synthetic signed JWT ≠ a witnessed GoTrue browser sign-in/authorised staff.
 */
import assert from 'node:assert/strict';
import { createHmac, randomUUID } from 'node:crypto';
import { spawnSync } from 'node:child_process';

const root = process.cwd();
const requested = process.argv.includes('--local');
if (!requested || process.env.E6_ALLOW_NONLOCAL) {
  console.error('Use --local from Wantok repo only; nonlocal unsupported.');
  process.exit(2);
}
const windows = process.platform === 'win32';
const command = windows ? (process.env.ComSpec || 'cmd.exe') : './node_modules/.bin/supabase';
const args = windows
  ? ['/d','/c', '.\\node_modules\\.bin\\supabase.cmd', 'status', '-o', 'json']
  : ['status','-o','json'];
const result = spawnSync(command, args, {
  cwd: root, encoding:'utf8',
  env: {...process.env, ...(process.platform === 'win32' ?
    {DOCKER_HOST: process.env.DOCKER_HOST || 'npipe:////./pipe/dockerDesktopLinuxEngine'} : {})},
  shell: false, timeout: 30000,
});
if (result.error || !result.stdout) {
  console.error('Local Supabase status unavailable; no tests executed.');
  process.exit(2);
}
let settings;
try { settings = JSON.parse(result.stdout); }
catch { console.error('Unable to parse local Supabase status.'); process.exit(2); }
const {API_URL: base, ANON_KEY: anonKey, JWT_SECRET: secret} = settings;
assert.ok(base && anonKey && secret, 'Local status missing auth configuration');
const parsed = new URL(base);
assert.ok(['127.0.0.1','localhost','::1'].includes(parsed.hostname),
  'Only loopback Supabase is allowed');
assert.equal(parsed.protocol, 'http:', 'No remote HTTPS authority allowed');
assert.equal(parsed.port, '54321', 'Expected local Supabase port');

const b64 = (o) => Buffer.from(JSON.stringify(o)).toString('base64url');
function jwt(payload, key = secret) {
  const header = b64({alg:'HS256',typ:'JWT'});
  const content = b64(payload);
  const signature = createHmac('sha256',key)
    .update(header+'.'+content).digest('base64url');
  return header+'.'+content+'.'+signature;
}
const now = Math.floor(Date.now()/1000);
function syntheticToken(userId, claimedRole='authenticated') {
  return jwt({
    aud:'authenticated', exp:now+300, iat:now, iss:'supabase',
    sub:userId, role:claimedRole, email:'e6-offline-test@invalid.example',
    app_metadata:{provider:'email',providers:['email']},
  });
}
const outsider = syntheticToken(randomUUID());
const other = syntheticToken(randomUUID());
const forged = jwt({aud:'authenticated',exp:now+300,iat:now,sub:randomUUID(),role:'service_role'},'definitely-not-local-signing-key');
const tests = [];
async function api(token, method, endpoint, body) {
  const response = await fetch(base+'/rest/v1/'+endpoint, {
    method,
    headers: {
      apikey:anonKey,
      authorization:'Bearer '+token,
      ...(body !== undefined ? {'content-type':'application/json'} : {}),
    },
    body:body === undefined ? undefined : JSON.stringify(body),
    signal:AbortSignal.timeout(7000),
  });
  const raw = await response.text();
  let data = raw;
  try { data = JSON.parse(raw); } catch { /* protect against HTML errors */ }
  return {code:response.status, data};
}
async function test(label, fn) {
  try {
    await fn();
    tests.push({label, pass:true});
    console.log('PASS '+label);
  } catch (err) {
    tests.push({label, pass:false});
    console.error('FAIL '+label+': '+err.message.replace(/[\\r\\n]/g,' '));
  }
}
const noRows = (response) => {
  assert.equal(response.code,200);
  assert.ok(Array.isArray(response.data),'Expected PostgREST JSON array');
  assert.equal(response.data.length,0);
};
for (const [label,token] of [['no-grant officer',outsider],['different officer',other]]) {
  for (const [name,table,field] of [
    ['own duty grants','operations_duty_grants','id'],
    ['provisioner authorities','operations_provisioning_authorities','staff_user_id'],
    ['duty approval queue','operations_duty_change_requests','id'],
    ['enterprise applications','vendor_intake_cases','id'],
    ['staged applications','staged_provider_applications','id'],
    ['case recusals','operations_case_recusals','id'],
  ]) {
    await test(label+' cannot read '+name,async () =>
      noRows(await api(token,'GET',table+'?select='+field+'&limit=3')));
  }
  await test(label+' has no PG reviewer authority', async () => {
    const r = await api(token,'POST','rpc/has_operations_scope',{
      p_duty:'case_reviewer',p_country_code:'PG',
      p_region_code:'PG-MPL',p_category_scope:'trades',
    });
    assert.equal(r.code,200);assert.equal(r.data,false);
  });
  await test(label+' cannot propose staff grant', async () => {
    const r = await api(token,'POST','rpc/request_operations_duty_change',{
      p_action:'grant',p_staff:randomUUID(),p_duty:'case_reviewer',
      p_country:'PG',p_region:'PG-MPL',p_category:'trades',
      p_expires:new Date(Date.now()+86400000).toISOString(),
      p_target:null,
      p_reason:'Synthetic negative test without delegated requester authority',
    });
    assert.equal(r.code,403);
    assert.equal(r.data?.code,'42501');
  });
  await test(label+' cannot directly bootstrap trusted authorities', async () => {
    const r=await api(token,'POST','rpc/configure_operations_provisioner',{
      p_staff:randomUUID(),p_country:'PG',p_authority:'requester',
      p_verified_by:randomUUID(),
      p_provenance:'Synthetic test never allowed to bootstrap staff',p_enabled:true,
    });
    assert.ok([401,403,404].includes(r.code));
  });
  await test(label+' cannot enumerate immutable duty events', async () => {
    const r = await api(token,'GET','operations_duty_change_events?select=id&limit=1');
    assert.ok([401,403].includes(r.code));
  });
}
await test('anon has no access to staff duty reads', async () => {
  const r=await api(anonKey,'GET','operations_provisioning_authorities?select=authority&limit=1');
  assert.ok([401,403].includes(r.code));
});
await test('forged service-role JWT cannot read duties', async () => {
  const r=await api(forged,'GET','operations_duty_change_requests?select=id&limit=1');
  assert.ok([401,403].includes(r.code));
});
await test('legacy resource activation RPC stays sealed', async () => {
  const r=await api(outsider,'POST','rpc/admin_set_provider_resource_status',{
    p_resource_id:randomUUID(),p_status:'active',
  });
  assert.equal(r.code,403);assert.equal(r.data?.code,'42501');
});
const pass=tests.filter(t=>t.pass).length;
console.log(`E6 local signed-JWT HTTP negative boundaries: ${pass}/${tests.length} PASS. Read-only; zero fixtures or users created.`);
if (pass!==tests.length) process.exitCode=1;
