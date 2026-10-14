import test from 'node:test';
import assert from 'node:assert/strict';
import {generateKeyPairSync,sign} from 'node:crypto';
import {simulateTrackRead,verifySyntheticJwt,publicFields,route} from './cx1q-offline-track-jwt-contract.mjs';

const pair=generateKeyPairSync('ed25519');
const ISS='https://cx1q.invalid';
const AUD='cx1q-offline-stage';
const ORIGIN='https://cx1q.invalid';
const A='11111111-1111-4111-8111-111111111111';
const B='22222222-2222-4222-8222-222222222222';
const PROVIDER='33333333-3333-4333-8333-333333333333';
const ADMIN='44444444-4444-4444-8444-444444444444';
const QUALIFIED='55555555-5555-4555-8555-555555555555';
const NONE='66666666-6666-4666-8666-666666666666';
const SESSION='77777777-7777-4777-8777-777777777777';
const NOW=1781700000;
const enc=x=>Buffer.from(JSON.stringify(x)).toString('base64url');
const base={iss:ISS,aud:AUD,sub:A,role:'authenticated',iat:NOW-30,nbf:NOW-20,
  exp:NOW+60,session_id:SESSION};
const header={alg:'EdDSA',typ:'JWT',kid:'cx1q-offline-only'};
function issue(overrides={},headerOverrides={}) {
  const input=enc({...header,...headerOverrides})+'.'+enc({...base,...overrides});
  return input+'.'+sign(null,Buffer.from(input),pair.privateKey).toString('base64url');
}
const row=(booking_id,customer_id,created_at)=>({
  booking_id,customer_id,created_at,scheduled_start:null,booking_status:'requested',
  notes:'INTERNAL_ONLY',beneficiary_email:'fixture@example.invalid',provider_id:PROVIDER
});
const rows=[
  row('a0000000-0000-4000-8000-000000000001',A,'2026-10-15T01:00:00Z'),
  row('b0000000-0000-4000-8000-000000000002',B,'2026-10-15T02:00:00Z'),
  row('c0000000-0000-4000-8000-000000000003',B,'2026-10-15T03:00:00Z'),
];
for(let i=1;i<=105;i++) rows.push(row('d0000000-0000-4000-8000-'+i.toString(16).padStart(12,'0'),
 A,'2026-10-14T12:'+String(Math.floor(i/60)).padStart(2,'0')+':'+String(i%60).padStart(2,'0')+'Z'));
const config=(other={})=>({
  publicKey:pair.publicKey,issuer:ISS,audience:AUD,now:NOW,allowedOrigin:ORIGIN,
  rows,revokedSessions:new Set(),...other
});
const request=(token=issue(),other={})=>({
  method:'GET',path:route,origin:ORIGIN,
  headers:{authorization:'Bearer '+token,accept:'application/json'},...other
});
const read=(token=issue(),req={},cfg={})=>simulateTrackRead(request(token,req),config(cfg));
const deny=(code,token,req,cfg)=>assert.equal(read(token,req,cfg).status,code);

test('01 customer A sees at most 100 of own bookings',()=>{
  const r=read();assert.equal(r.status,200);assert.equal(r.body.length,100);
  assert.ok(!r.body.some(x=>x.booking_id.startsWith('b')||x.booking_id.startsWith('c')));
});
test('02 customer B sees two records in newest-first order',()=>{
  const r=read(issue({sub:B}));
  assert.deepEqual(r.body.map(x=>x.booking_id),[
    'c0000000-0000-4000-8000-000000000003','b0000000-0000-4000-8000-000000000002']);
});
test('03 provider has no customer-owned records',()=>{
  assert.deepEqual(read(issue({sub:PROVIDER})).body,[]);
});
test('04 admin has no customer-owned records',()=>{
  assert.deepEqual(read(issue({sub:ADMIN})).body,[]);
});
test('05 qualified provider has no customer-owned records',()=>{
  assert.deepEqual(read(issue({sub:QUALIFIED})).body,[]);
});
test('06 empty customer returns success and empty array',()=>{
  const r=read(issue({sub:NONE}));assert.equal(r.status,200);assert.deepEqual(r.body,[]);
});
test('07 projection has only four approved synthetic fields',()=>{
  const r=read();assert.deepEqual(Object.keys(r.body[0]),publicFields);
  assert.ok(!JSON.stringify(r.body).includes('INTERNAL_ONLY'));
});
test('08 cache and origin restricted',()=>{
  const r=read();assert.equal(r.headers['cache-control'],'no-store');
  assert.equal(r.headers['access-control-allow-origin'],ORIGIN);
});
test('09 test-only signed token returns exact actor',()=>{
  assert.equal(verifySyntheticJwt(issue(),config()),A);
});

test('10 missing Authorization denied',()=>deny(401,issue(),{headers:{}}));
test('11 malformed bearer denied',()=>deny(401,'not.a.valid.token'));
test('12 modified signature denied',()=>{
  const token=issue();const parts=token.split('.');
  parts[2]=parts[2].replace(/^./,x=>x==='A'?'B':'A');
  deny(401,parts.join('.'));
});
test('13 unexpected JWT algorithm denied',()=>deny(401,issue({}, {alg:'none'})));
test('14 unexpected JWT key ID denied',()=>deny(401,issue({}, {kid:'unknown'})));
test('15 unexpected JWT header extension denied',()=>deny(401,issue({}, {jku:'not-trusted'})));
test('16 unexpected issuer denied',()=>deny(401,issue({iss:'different-issuer'})));
test('17 unexpected audience denied',()=>deny(401,issue({aud:'wrong-audience'})));
test('18 privileged service role denied',()=>deny(401,issue({role:'service_role'})));
test('19 anonymous role denied',()=>deny(401,issue({role:'anon'})));
test('20 expired token denied',()=>deny(401,issue({iat:NOW-100,nbf:NOW-99,exp:NOW-1})));
test('21 not-before in future denied',()=>deny(401,issue({nbf:NOW+5})));
test('22 issued-at in future denied',()=>deny(401,issue({iat:NOW+50,nbf:NOW+50,exp:NOW+300})));
test('23 overlong lifetime denied',()=>deny(401,issue({exp:NOW+4000})));
test('24 synthetic revoked session denied',()=>{
  deny(401,issue(),{}, {revokedSessions:new Set([SESSION])});
});
test('25 missing session denied',()=>deny(401,issue({session_id:null})));
test('26 unsupported extra claim denied',()=>deny(401,issue({custom_admin:true})));
test('27 non-UUID identity denied',()=>deny(401,issue({sub:'customer-a'})));
test('28 rejected token with a mismatched test verification key',()=>{
  const second=generateKeyPairSync('ed25519');
  deny(401,issue(),{}, {publicKey:second.publicKey});
});

test('29 caller-selected customer filter is rejected',()=>{
  deny(404,issue({sub:B}),{query:{customer_id:A}});
});
test('30 unrestricted projection is rejected',()=>{
  deny(404,issue(),{query:{select:'*'}});
});
test('31 unrelated REST table request is rejected',()=>{
  deny(404,issue(),{path:'/rest/v1/service_bookings'});
});
test('32 writes are not supported',()=>{
  deny(405,issue(),{method:'POST'});
});
test('33 modifications are not supported',()=>{
  deny(405,issue(),{method:'PATCH'});
});
test('34 delete method is not supported',()=>{
  deny(405,issue(),{method:'DELETE'});
});
test('35 unapproved origin rejected',()=>{
  deny(403,issue(),{origin:'https://other.invalid'});
});
test('36 missing origin rejected',()=>{
  deny(403,issue(),{origin:null});
});

test('37 extra request parameters are rejected',()=>{
  deny(404,issue(),{query:{limit:100000}});
});
test('38 unexpected caller header is rejected',()=>{
  deny(401,issue(),{headers:{authorization:'Bearer '+issue(),extra:'yes'}});
});
test('39 multiple authorization values are rejected',()=>{
  deny(401,issue(),{headers:{authorization:['one','two']}});
});
test('40 incorrect Accept header is rejected',()=>{
  deny(401,issue(),{headers:{authorization:'Bearer '+issue(),accept:'text/html'}});
});
test('41 missing request returns safe rejection',()=>{
  assert.equal(simulateTrackRead(null,config()).status,403);
});
test('42 missing stage configuration returns safe rejection',()=>{
  assert.equal(simulateTrackRead(request(),null).status,403);
});
test('43 rejected requests do not include synthetic sensitive fields',()=>{
  const responses=[
    read(issue({aud:'invalid'})),read(issue(),{method:'DELETE'}),
    read(issue(),{origin:'https://unapproved.invalid'})
  ];
  assert.ok(responses.every(r=>r.status!==200));
  assert.ok(responses.every(r=>!JSON.stringify(r).includes('INTERNAL_ONLY')));
});
test('44 no live Supabase credential or endpoint required',()=>{
  assert.ok(!Object.hasOwn(config(),'jwtSecret'));
  assert.ok(!Object.hasOwn(config(),'supabaseUrl'));
});
