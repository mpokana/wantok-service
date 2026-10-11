import test from 'node:test';
import assert from 'node:assert/strict';
import {randomUUID} from 'node:crypto';
import {createLocalEvidencePreflight,startLocalEvidencePreflightServer}
 from '../src/preflight.mjs';
import {EvidenceError} from '../src/scan.mjs';

const requestId=randomUUID(), subjectId=randomUUID();
const jwt='a'.repeat(12)+'.'+'b'.repeat(12)+'.'+'c'.repeat(12);
const bearer='Bearer '+jwt;
const json=(body,status=200)=>new Response(JSON.stringify(body),{
  status,headers:{'content-type':'application/json'},
});
const blocked={
  request_id:requestId,status:'requested',
  expires_at:'2099-12-31T00:00:00+00:00',
  notice_version:'WANTOK-EVIDENCE-NOTICE-DRAFT-2026-10',
  expired:false,upload_allowed:false,reviewer_access_allowed:false,
  identity_verified:false,reason:'secure_gateway_and_approved_notice_required',
};
const isDenied=e=>e instanceof EvidenceError&&e.code==='EVIDENCE_PREFLIGHT_DENIED';
function fixture({identity={id:subjectId,role:'authenticated',aud:'authenticated'},
 authStatus=200,body=blocked,restStatus=200,throwNetwork=false}={}){
 const calls=[];
 const options={
  supabaseUrl:'http://127.0.0.1:54321',
  publishableKey:'safe-development-public-key-123456',
  fetchImpl:async(url,init)=>{
   calls.push({url,init});
   if(throwNetwork)throw Error('secret token pretend network exception');
   if(url.endsWith('/auth/v1/user'))return json(identity,authStatus);
   if(url.endsWith('/rest/v1/rpc/vendor_evidence_preflight'))
     return json(body,restStatus);
   throw Error('unexpected endpoint');
  },
 };
 return {calls,options,service:createLocalEvidencePreflight(options)};
}
test('GoTrue verification precedes caller-RLS PostgREST preflight; no service key',async()=>{
 const {service,calls}=fixture();
 const out=await service.check({authorization:bearer,requestId});
 assert.deepEqual(out,{
  state:'blocked_pending_secure_gateway',uploadAllowed:false,
  reviewerAccessAllowed:false,identityVerified:false,
  privacyConsentRecorded:false,requestStatus:'requested',expired:false,
 });
 assert.equal(calls.length,2);
 assert.match(calls[0].url,/\/auth\/v1\/user$/);
 assert.match(calls[1].url,/\/rest\/v1\/rpc\/vendor_evidence_preflight$/);
 assert.equal(calls[1].init.headers.Authorization,bearer);
 assert.equal(calls[1].init.headers.apikey,'safe-development-public-key-123456');
 assert.equal(calls[1].init.redirect,'error');
 assert.deepEqual(JSON.parse(calls[1].init.body),{p_request_id:requestId});
 assert.equal(JSON.stringify(out).includes(jwt),false);
});
test('bad ids and bearer fail before contacting GoTrue',async()=>{
 for(const id of ['missing','../evil',null,randomUUID().replace(/.$/,'!')]){
  const {service,calls}=fixture();
  await assert.rejects(service.check({authorization:bearer,requestId:id}),isDenied);
  assert.equal(calls.length,0);
 }
 for(const authorization of ['Bearer fake','bearer '+jwt,'',bearer+'\nsecret']){
  const {service,calls}=fixture();
  await assert.rejects(service.check({authorization,requestId}),isDenied);
  assert.equal(calls.length,0);
 }
});
test('GoTrue rejection/anonymous/untrusted claims never invoke the database',async()=>{
 for(const caseData of [
  {authStatus:401},
  {identity:{id:subjectId,role:'anon',aud:'authenticated'}},
  {identity:{id:subjectId,role:'authenticated',aud:'anon'}},
  {identity:{id:subjectId,role:'authenticated',aud:'authenticated',is_anonymous:true}},
  {identity:{id:subjectId,role:'authenticated',aud:'authenticated',
    banned_until:new Date(Date.now()+86400000).toISOString()}},
  {identity:{id:'bad',role:'authenticated',aud:'authenticated'}},
 ]){
  const {service,calls}=fixture(caseData);
  await assert.rejects(service.check({authorization:bearer,requestId}),isDenied);
  assert.equal(calls.length,1);
 }
});
test('caller-scoped RLS denial and network failure fail closed with no secret echo',async()=>{
 for(const options of [{restStatus:403,body:{message:'private account data'}},
  {throwNetwork:true}]){
  const {service}=fixture(options);
  await assert.rejects(service.check({authorization:bearer,requestId}),e=>{
    assert.ok(isDenied(e));
    assert.ok(!e.message.includes('secret'));
    assert.ok(!e.message.includes(jwt));
    return true;
  });
 }
});
test('upgraded or malformed replies never enable upload or identity approval',async()=>{
 for(const patch of [
  {upload_allowed:true},{identity_verified:true},{reviewer_access_allowed:true},
  {notice_version:'WANTOK-EVIDENCE-NOTICE-APPROVED'},
  {request_id:randomUUID()},{status:'approved'},
  {reason:'ready_for_upload'},{expired:'false'}
 ]){
  const {service}=fixture({body:{...blocked,...patch}});
  await assert.rejects(service.check({authorization:bearer,requestId}),isDenied);
 }
});
test('foreign and credentialed origins are rejected',()=>{
 for(const url of ['https://127.0.0.1:54321','http://localhost:54321',
  'http://10.1.1.4:54321','https://public.example','http://evil@127.0.0.1:54321',
  'http://127.0.0.1:54321/path','http://127.0.0.1:54321/#fragment']){
  assert.throws(()=>createLocalEvidencePreflight({
    supabaseUrl:url,publishableKey:'test-key-value-123456',
  }),isDenied);
 }
});
test('real loopback HTTP handler always blocks upload, even when authenticated',async()=>{
 const {options}=fixture();
 const handle=await startLocalEvidencePreflightServer({...options,port:0});
 const url='http://127.0.0.1:'+handle.port;
 try {
  const health=await fetch(url+'/health');
  assert.equal(health.status,200);
  assert.equal((await health.json()).uploadsEnabled,false);
  const authorized=await fetch(url+'/v1/preflight',{
    method:'POST',
    headers:{Authorization:bearer,'Content-Type':'application/json'},
    body:JSON.stringify({requestId}),
  });
  assert.equal(authorized.status,423);
  const reply=await authorized.json();
  assert.equal(reply.uploadAllowed,false);
  assert.equal(reply.identityVerified,false);
  const fakeUpload=await fetch(url+'/v1/upload',{
   method:'POST',
   headers:{'Content-Type':'application/octet-stream'},
   body:Buffer.alloc(48,0x41),
  });
  assert.equal(fakeUpload.status,404);
  const browser=await fetch(url+'/v1/preflight',{
   method:'POST',headers:{Authorization:bearer,'Content-Type':'application/json',
     Origin:'https://hostile.example'},
   body:JSON.stringify({requestId}),
  });
  assert.equal(browser.status,403);
  const overlarge=await fetch(url+'/v1/preflight',{
   method:'POST',headers:{Authorization:bearer,'Content-Type':'application/json'},
   body:JSON.stringify({requestId,garbage:'a'.repeat(300)}),
  });
  assert.equal(overlarge.status,404);
 } finally {await handle.close();}
});
test('loopback handler requires bearer, allows no arbitrary body keys or status bypass',async()=>{
 const {options}=fixture();
 const handle=await startLocalEvidencePreflightServer({...options,port:0});
 try {
  const base='http://127.0.0.1:'+handle.port+'/v1/preflight';
  for(const init of [
   {headers:{'Content-Type':'application/json'},body:JSON.stringify({requestId})},
   {headers:{Authorization:bearer,'Content-Type':'application/json'},
     body:JSON.stringify({requestId,subjectId})},
   {headers:{Authorization:bearer,'Content-Type':'text/plain'},
     body:JSON.stringify({requestId})},
  ]){
   const response=await fetch(base,{method:'POST',...init});
   assert.ok([403,404].includes(response.status));
  }
 } finally {await handle.close();}
});
