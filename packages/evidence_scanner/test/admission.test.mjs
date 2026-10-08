import test from 'node:test';
import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { createLocalEvidenceClaimService } from '../src/admission.mjs';
import { EvidenceError } from '../src/scan.mjs';

const intentId = randomUUID();
const applicationId = randomUUID();
const checkId = randomUUID();
const subjectId = randomUUID();
const claimId = randomUUID();
const authorization = 'Bearer ' + 'a'.repeat(8) + '.' + 'b'.repeat(8) + '.' + 'c'.repeat(8);
const input = {authorization, intentId, applicationId, checkId};
const rejected = e => e instanceof EvidenceError && e.code === 'EVIDENCE_ADMISSION_DENIED';
const json = (data, status=200) => new Response(JSON.stringify(data), {
  status, headers: {'content-type':'application/json'},
});

function fixture({identity={id:subjectId,role:'authenticated',aud:'authenticated'},
  authStatus=200, rpcStatus=200, result=claimId, throwOnFetch=false}={}) {
  const calls = [];
  const service = createLocalEvidenceClaimService({
    supabaseUrl:'http://127.0.0.1:54321',
    publishableKey:'public-test-key-123456',
    serviceRoleKey:'private-test-service-key-123456',
    fetchImpl:async (url, options) => {
      calls.push({url, options});
      if (throwOnFetch) throw Error('Pretend network failure with secret');
      if (url.endsWith('/auth/v1/user')) return json(identity,authStatus);
      if (url.endsWith('/rest/v1/rpc/claim_staged_evidence_intake'))
        return json(result,rpcStatus);
      throw Error('Unexpected endpoint');
    },
  });
  return {service,calls};
}
test('trusted GoTrue lookup precedes a one-time server-role RPC',async()=>{
  const {service,calls}=fixture();
  const result=await service.claimForAuthenticatedRequest(input);
  assert.equal(result.subjectId,subjectId);
  assert.equal(result.claimId,claimId);
  assert.equal(result.state,'claimed_for_quarantine');
  assert.equal(result.storagePermitted,false);
  assert.equal(result.reviewerAccessPermitted,false);
  assert.equal(result.approved,false);
  assert.equal(result.uploadedToSupabase,false);
  assert.equal(calls.length,2);
  assert.match(calls[0].url,/\/auth\/v1\/user$/);
  assert.equal(calls[0].options.headers.Authorization,authorization);
  assert.match(calls[1].url,/\/rest\/v1\/rpc\/claim_staged_evidence_intake$/);
  assert.equal(calls[1].options.method,'POST');
  assert.equal(calls[1].options.redirect,'error');
  assert.deepEqual(JSON.parse(calls[1].options.body),{
    p_intent_id:intentId,p_applicant_id:subjectId,
    p_application_id:applicationId,p_check_id:checkId,
  });
  assert.equal(JSON.stringify(result).includes('private-test-service-key'),false);
});
test('body-supplied subject cannot override verified GoTrue subject',async()=>{
  const {service,calls}=fixture();
  await service.claimForAuthenticatedRequest({...input,subjectId:randomUUID(),eligible:true});
  const posted=JSON.parse(calls[1].options.body);
  assert.equal(posted.p_applicant_id,subjectId);
  assert.equal(Object.hasOwn(posted,'eligible'),false);
});
test('rejects missing bearer and malformed JWT without contacting Supabase',async()=>{
  for(const bearer of ['', 'Bearer gibberish', 'bearer a.b.c', 'Bearer a.b.c\nExtra',
    'Bearer a.b.c ', 'Bearer '+ 'z'.repeat(8193)]) {
    const {service,calls}=fixture();
    await assert.rejects(service.claimForAuthenticatedRequest({...input,authorization:bearer}),rejected);
    assert.equal(calls.length,0);
  }
});
test('rejects forged or malformed IDs before network access',async()=>{
  for(const candidate of ['bad', '../bad', '', null, '00000000-0000-0000-0000-000000000000']) {
    const {service,calls}=fixture();
    await assert.rejects(service.claimForAuthenticatedRequest({...input,checkId:candidate}),rejected);
    assert.equal(calls.length,0);
  }
});
test('GoTrue rejection cannot reach privileged RPC',async()=>{
  const {service,calls}=fixture({authStatus:401});
  await assert.rejects(service.claimForAuthenticatedRequest(input),rejected);
  assert.equal(calls.length,1);
});
test('anonymous, incorrect-audience or invalid GoTrue subjects cannot claim',async()=>{
  for(const identity of [
    {id:subjectId,role:'anon',aud:'authenticated'},
    {id:subjectId,role:'authenticated',aud:'anon'},
    {id:subjectId,role:'authenticated',aud:'authenticated',is_anonymous:true},
    {id:subjectId,role:'authenticated',aud:'authenticated',banned_until:new Date(Date.now()+86400000).toISOString()},
    {id:'fake',role:'authenticated',aud:'authenticated'}, null,
  ]) {
    const {service,calls}=fixture({identity});
    await assert.rejects(service.claimForAuthenticatedRequest(input),rejected);
    assert.equal(calls.length,1);
  }
});
test('SQL claim rejection, including duplicate or withdrawn intent, remains closed',async()=>{
  const {service,calls}=fixture({rpcStatus:400,result:{message:'already claimed'}});
  await assert.rejects(service.claimForAuthenticatedRequest(input),rejected);
  assert.equal(calls.length,2);
});
test('malformed claim receipt is rejected even on HTTP 200',async()=>{
  const {service}=fixture({result:{claim_id:claimId}});
  await assert.rejects(service.claimForAuthenticatedRequest(input),rejected);
});
test('network error fails closed and does not expose server secrets',async()=>{
  const {service,calls}=fixture({throwOnFetch:true});
  await assert.rejects(service.claimForAuthenticatedRequest(input),e=>{
    assert.ok(rejected(e));
    assert.equal(e.message.includes('secret'),false);
    return true;
  });
  assert.equal(calls.length,1);
});
test('remote, malformed, credentialed and non-loopback Supabase URLs are refused',()=>{
  for(const url of [
    'https://wantokservices.com','https://127.0.0.1:54321',
    'http://192.168.121.18:54321', 'http://evil@localhost:54321',
    'http://localhost:54321', 'http://localhost:54321/api','http://localhost:54321/?key=a',
    'http://localhost:54321/#frag', 'not-a-url',
  ]) {
    assert.throws(()=>createLocalEvidenceClaimService({
      supabaseUrl:url,publishableKey:'public-test-key-123456',
      serviceRoleKey:'private-test-service-key-123456',
    }),rejected);
  }
});
test('incomplete or reused privileged credentials fail before construction',()=>{
  assert.throws(()=>createLocalEvidenceClaimService({
    supabaseUrl:'http://127.0.0.1:54321',publishableKey:'same-secret-123456',
    serviceRoleKey:'same-secret-123456',
  }),rejected);
});
