import test,{before,after} from 'node:test';
import assert from 'node:assert/strict';
import {generateKeyPairSync,sign} from 'node:crypto';
import {request as nodeRequest} from 'node:http';
import {makeTestOnlyLoopbackServer} from './cx1r-loopback-http-fixture.mjs';
import {publicFields,route} from './cx1q-offline-track-jwt-contract.mjs';

const keys=generateKeyPairSync('ed25519');
const ORIGIN='https://cx1r.invalid';
const ISS='https://cx1r.invalid/test-go-true-placeholder';
const AUD='cx1r-synthetic-only';
const NOW=1781700000;
const A='11111111-1111-4111-8111-111111111111';
const B='22222222-2222-4222-8222-222222222222';
const PROVIDER='33333333-3333-4333-8333-333333333333';
const ADMIN='44444444-4444-4444-8444-444444444444';
const NONE='66666666-6666-4666-8666-666666666666';
const SESSION='77777777-7777-4777-8777-777777777777';
const b64=x=>Buffer.from(JSON.stringify(x)).toString('base64url');
function token(claims={}) {
  const head=b64({alg:'EdDSA',typ:'JWT',kid:'cx1q-offline-only'});
  const body=b64({iss:ISS,aud:AUD,sub:A,role:'authenticated',
    iat:NOW-50,nbf:NOW-40,exp:NOW+60,session_id:SESSION,...claims});
  const data=head+'.'+body;
  return data+'.'+sign(null,Buffer.from(data),keys.privateKey).toString('base64url');
}
const row=(id,owner,created)=>({
  booking_id:id,customer_id:owner,created_at:created,
  booking_status:'requested',scheduled_start:null,
  notes:'HIDDEN_NOTE',beneficiary_phone:'HIDDEN_PHONE',
  metadata:{internal_only:true}
});
const rows=[
 row('a0000000-0000-4000-8000-000000000001',A,'2026-10-15T01:00:00Z'),
 row('b0000000-0000-4000-8000-000000000002',B,'2026-10-15T02:00:00Z'),
 row('c0000000-0000-4000-8000-000000000003',B,'2026-10-15T03:00:00Z')
];
for(let i=1;i<=105;i++) rows.push(row(
 'd0000000-0000-4000-8000-'+i.toString(16).padStart(12,'0'),A,
 '2026-10-14T12:'+String(Math.floor(i/60)).padStart(2,'0')+':'+String(i%60).padStart(2,'0')+'Z'));
const conf={publicKey:keys.publicKey,issuer:ISS,audience:AUD,
  now:NOW,allowedOrigin:ORIGIN,rows,revokedSessions:new Set()};
let server,base;
before(async()=>{
  server=makeTestOnlyLoopbackServer(conf);
  await new Promise((resolve,reject)=>{
    server.once('error',reject);
    server.listen(0,'127.0.0.1',resolve);
  });
  const address=server.address();
  assert.equal(address.address,'127.0.0.1');
  assert.ok(address.port>1024&&address.port!==54321);
  base='http://127.0.0.1:'+address.port;
});
after(async()=>{
  if(server?.listening)await new Promise((resolve,reject)=>
    server.close(err=>err?reject(err):resolve()));
});
async function http(method='GET',path=route,extras={}) {
  const {headers={},...options}=extras;
  const response=await fetch(base+path,{
    method,redirect:'manual',signal:AbortSignal.timeout(3500),
    headers:{origin:ORIGIN,accept:'application/json',
      authorization:'Bearer '+token(),...headers},
    ...options
  });
  const text=await response.text();
  let body;
  if(text)body=JSON.parse(text);
  return {status:response.status,headers:response.headers,body,text};
}
function rawGet(headers={},body) {
  return new Promise((resolve,reject)=>{
    const req=nodeRequest(base+route,{method:'GET',headers:{
      origin:ORIGIN,accept:'application/json',
      authorization:'Bearer '+token(),...headers
    }},res=>{
      const data=[];
      res.on('data',chunk=>data.push(chunk));
      res.on('end',()=>resolve({status:res.statusCode,text:Buffer.concat(data).toString('utf8')}));
    });
    req.once('error',reject);
    if(body)req.write(body);
    req.end();
  });
}
const expectDeny=async(status,method='GET',path=route,other={})=>{
  const r=await http(method,path,other);
  assert.equal(r.status,status);
  assert.equal(r.headers.get('cache-control'),'no-store');
  assert.ok(!r.text.includes('HIDDEN_'));
  return r;
};

test('01 only ephemeral loopback host and port',()=>{
  assert.equal(new URL(base).hostname,'127.0.0.1');
  assert.notEqual(Number(new URL(base).port),54321);
});
test('02 customer A sees only A latest 100',async()=>{
  const r=await http();assert.equal(r.status,200);assert.equal(r.body.length,100);
  assert.ok(!r.body.some(x=>x.booking_id.startsWith('b')||x.booking_id.startsWith('c')));
});
test('03 customer B sees B two records ordered newest first',async()=>{
  const r=await http('GET',route,{headers:{authorization:'Bearer '+token({sub:B})}});
  assert.equal(r.status,200);
  assert.deepEqual(r.body.map(x=>x.booking_id),[
    'c0000000-0000-4000-8000-000000000003',
    'b0000000-0000-4000-8000-000000000002']);
});
test('04 provider subject does not get any customer history',async()=>{
  const r=await http('GET',route,{headers:{authorization:'Bearer '+token({sub:PROVIDER})}});
  assert.equal(r.status,200);assert.deepEqual(r.body,[]);
});
test('05 admin subject does not get other customers history',async()=>{
  const r=await http('GET',route,{headers:{authorization:'Bearer '+token({sub:ADMIN})}});
  assert.equal(r.status,200);assert.deepEqual(r.body,[]);
});
test('06 customer with no booking gets truthful empty array',async()=>{
  const r=await http('GET',route,{headers:{authorization:'Bearer '+token({sub:NONE})}});
  assert.equal(r.status,200);assert.deepEqual(r.body,[]);
});
test('07 only four synthetic public fields via actual HTTP',async()=>{
  const r=await http();
  assert.deepEqual(Object.keys(r.body[0]),publicFields);
  assert.ok(!r.text.includes('HIDDEN_NOTE')&&!r.text.includes('HIDDEN_PHONE'));
});
test('08 successful HTTP never caches account data',async()=>{
  const r=await http();
  assert.equal(r.headers.get('cache-control'),'no-store');
  assert.equal(r.headers.get('access-control-allow-origin'),ORIGIN);
  assert.equal(r.headers.get('x-content-type-options'),'nosniff');
});
test('09 deny request without authorization',async()=>{
  await expectDeny(401,'GET',route,{headers:{authorization:''}});
});
test('10 deny tampered signature over wire',async()=>{
  let t=token(); t=t.slice(0,-1)+(t.endsWith('A')?'B':'A');
  await expectDeny(401,'GET',route,{headers:{authorization:'Bearer '+t}});
});
test('11 deny wrong issuer over wire',async()=>{
  await expectDeny(401,'GET',route,{headers:{authorization:'Bearer '+token({iss:'untrusted'})}});
});
test('12 deny wrong JWT audience over wire',async()=>{
  await expectDeny(401,'GET',route,{headers:{authorization:'Bearer '+token({aud:'other'})}});
});
test('13 deny unprivileged/non-customer JWT role',async()=>{
  await expectDeny(401,'GET',route,{headers:{authorization:'Bearer '+token({role:'anon'})}});
});
test('14 deny privileged service role',async()=>{
  await expectDeny(401,'GET',route,{headers:{authorization:'Bearer '+token({role:'service_role'})}});
});
test('15 deny expired signed token',async()=>{
  await expectDeny(401,'GET',route,{headers:{authorization:'Bearer '+token({iat:NOW-200,nbf:NOW-190,exp:NOW-5})}});
});
test('16 deny future not-before signed token',async()=>{
  await expectDeny(401,'GET',route,{headers:{authorization:'Bearer '+token({nbf:NOW+25})}});
});
test('17 deny revoked test session',async()=>{
  conf.revokedSessions.add(SESSION);
  try {await expectDeny(401);}
  finally {conf.revokedSessions.delete(SESSION);}
});

test('18 deny caller-selected customer ID',async()=>{
  await expectDeny(404,'GET',route+'?customer_id='+B);
});
test('19 deny wildcard response expansion',async()=>{
  await expectDeny(404,'GET',route+'?select=*');
});
test('20 deny trailing query delimiter',async()=>{
  // URL parser normalises bare ? into empty search; do not claim this is rejected
  const r=await http('GET',route+'?select=id');
  assert.equal(r.status,404);
});
test('21 deny raw underlying service_bookings path',async()=>{
  await expectDeny(404,'GET','/rest/v1/service_bookings');
});
test('22 deny unrelated service_quotes REST path',async()=>{
  await expectDeny(404,'GET','/rest/v1/service_quotes');
});
test('23 deny POST on read-only candidate route',async()=>{
  await expectDeny(405,'POST');
});
test('24 deny PATCH on read-only candidate route',async()=>{
  await expectDeny(405,'PATCH');
});
test('25 deny DELETE on read-only candidate route',async()=>{
  await expectDeny(405,'DELETE');
});
test('26 deny unrelated HTTP PUT',async()=>{
  await expectDeny(405,'PUT');
});
test('27 deny cross-origin HTTP request',async()=>{
  await expectDeny(403,'GET',route,{headers:{origin:'https://elsewhere.invalid'}});
});
test('28 deny absent Origin',async()=>{
  await expectDeny(403,'GET',route,{headers:{origin:''}});
});
test('29 deny unexpected client API key header',async()=>{
  await expectDeny(401,'GET',route,{headers:{apikey:'not-accepted-in-test-contract'}});
});
test('30 deny unexpected x-client-info',async()=>{
  await expectDeny(401,'GET',route,{headers:{'x-client-info':'unreviewed'}});
});
test('31 deny a raw HTTP body on read-only GET',async()=>{
  const r=await rawGet({'content-length':'1'},'X');
  assert.equal(r.status,400);
  assert.ok(!r.text.includes('HIDDEN_'));
});
test('32 deny raw HTTP transfer-encoding on read-only GET',async()=>{
  const r=await rawGet({'transfer-encoding':'chunked'});
  assert.equal(r.status,400);
  assert.ok(!r.text.includes('HIDDEN_'));
});
test('33 valid browser preflight, narrow method and headers',async()=>{
  const r=await http('OPTIONS',route,{headers:{
    'access-control-request-method':'GET',
    'access-control-request-headers':'authorization,accept'
  }});
  assert.equal(r.status,204);
  assert.equal(r.headers.get('access-control-allow-origin'),ORIGIN);
  assert.equal(r.headers.get('access-control-allow-methods'),'GET');
  assert.equal(r.headers.get('access-control-allow-headers'),'authorization,accept');
  assert.equal(r.headers.get('access-control-max-age'),'0');
});
test('34 reject CORS preflight requesting broad REST header',async()=>{
  await expectDeny(403,'OPTIONS',route,{headers:{
    'access-control-request-method':'GET',
    'access-control-request-headers':'authorization,apikey'
  }});
});
test('35 reject CORS preflight requesting POST',async()=>{
  await expectDeny(403,'OPTIONS',route,{headers:{
    'access-control-request-method':'POST',
    'access-control-request-headers':'authorization'
  }});
});
test('36 reject preflight from different origin',async()=>{
  await expectDeny(403,'OPTIONS',route,{headers:{
    origin:'https://other.invalid',
    'access-control-request-method':'GET',
    'access-control-request-headers':'authorization'
  }});
});
