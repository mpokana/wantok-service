import test from 'node:test';
import assert from 'node:assert/strict';
import {randomUUID,randomBytes} from 'node:crypto';
import {mkdtemp,rm,readFile,writeFile} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {EvidenceError} from '../src/scan.mjs';
import {sealOfflineCustodyCandidate,buildOfflineCustodyManifestProposal} from '../src/custody.mjs';
import {createLocalTrustedCustodyReader} from '../src/trusted-reconciliation.mjs';

const mode='OFFLINE_SYNTHETIC_FIXTURE_ONLY';
const denied=e=>e instanceof EvidenceError&&e.code==='CUSTODY_NOT_READY';
const fakeKey='synthetic-service-only-test-key-123456789';

async function fixture(work,{seal=true,claimState='claimed_for_quarantine'}={}){
 const root=await mkdtemp(join(tmpdir(),'wantok-offline-custody-'));
 const expected={
  claimId:randomUUID(),intentId:randomUUID(),subjectId:randomUUID(),
  applicationId:randomUUID(),checkId:randomUUID(),
 };
 const key=randomBytes(32),keyId='offline-demo-key';
 const pdf=Buffer.from('%PDF-1.7\n1 0 obj\n<<>>\nendobj\n%%EOF\n','ascii');
 try{
  let snapshot=null;
  if(seal){
   await sealOfflineCustodyCandidate({
    mode,root,binding:expected,keyId,key,
    filename:'synthetic.pdf',declaredMime:'application/pdf',bytes:pdf,
    verifyClaim:async()=>({...expected,eligible:true,
      state:'claimed_for_quarantine',storagePermitted:false,
      reviewerAccessPermitted:false,approved:false}),
    scanner:async()=>({verdict:'candidate_clean'}),
   });
   const proposal=await buildOfflineCustodyManifestProposal({
    mode,root,expected,keyId,key,
   });
   snapshot={
    claim_id:proposal.p_claim_id,intent_id:proposal.p_intent_id,
    applicant_id:proposal.p_applicant_id,application_id:proposal.p_application_id,
    check_id:proposal.p_check_id,plain_sha256:proposal.p_plain_sha256,
    sealed_sha256:proposal.p_sealed_sha256,plain_bytes:proposal.p_plain_bytes,
    sealed_bytes:proposal.p_sealed_bytes,mime:proposal.p_mime,
    key_id:proposal.p_key_id,envelope_version:2,
    state:'pending_independent_reconciliation',
   };
  }
  const response={claim_id:expected.claimId,claim_state:claimState,
    withdrawn_at:claimState==='withdrawn'?'2026-10-11T00:00:00Z':null,
    snapshot};
  const calls=[];
  const config={
   supabaseUrl:'http://127.0.0.1:54321',serviceRoleKey:fakeKey,
   fetchImpl:async(url,options)=>{
    calls.push({url,options});
    return new Response(JSON.stringify(response),{
      status:200,headers:{'content-type':'application/json'},
    });
   },
  };
  return await work({root,expected,key,keyId,response,calls,config,
    args:{mode,root,expected,key,keyId}});
 }finally{key.fill(0);await rm(root,{recursive:true,force:true});}
}
test('read current local metadata using service role, no release',()=>fixture(async a=>{
 const reader=createLocalTrustedCustodyReader(a.config);
 const r=await reader.read(a.expected.claimId);
 assert.equal(r.state,'claimed_for_quarantine');
 assert.equal(r.approved,false);
 assert.equal(r.reviewerAccessPermitted,false);
 assert.equal(r.uploadAllowed,false);
 assert.equal(a.calls.length,1);
 assert.equal(a.calls[0].options.redirect,'error');
 assert.equal(a.calls[0].options.headers.Authorization,'Bearer '+fakeKey);
 assert.equal(a.calls[0].url,
  'http://127.0.0.1:54321/rest/v1/rpc/read_staged_custody_reconciliation');
 const report=await reader.reconcileSynthetic(a.args);
 assert.equal(report.state,'snapshot_matches_still_pending_independent_reconciliation');
 assert.equal(report.approved,false);
 assert.equal(report.storagePermitted,false);
 assert.equal(JSON.stringify(report).includes(fakeKey),false);
}));
test('withdrawal supersedes matching sealed synthetic object',()=>fixture(async a=>{
 const r=await createLocalTrustedCustodyReader(a.config).reconcileSynthetic(a.args);
 assert.equal(r.state,'claim_withdrawn_no_release');
 assert.equal(r.approved,false);
},{claimState:'withdrawn'}));
test('missing sealed object never matches current DB metadata',()=>fixture(async a=>{
 const r=await createLocalTrustedCustodyReader(a.config).reconcileSynthetic(a.args);
 assert.equal(r.state,'missing_sealed_candidate');
},{seal:false}));
test('modified DB digest results in investigation, never release',()=>fixture(async a=>{
 a.response.snapshot.sealed_sha256='a'.repeat(64);
 const r=await createLocalTrustedCustodyReader(a.config).reconcileSynthetic(a.args);
 assert.equal(r.state,'metadata_mismatch_requires_investigation');
 assert.equal(r.approved,false);
}));
test('tampered local ciphertext results in investigation',()=>fixture(async a=>{
 const filename=join(a.root,a.expected.claimId+'.held');
 const payload=await readFile(filename);payload[payload.length-1]^=0xff;
 await writeFile(filename,payload);
 const r=await createLocalTrustedCustodyReader(a.config).reconcileSynthetic(a.args);
 assert.equal(r.state,'sealed_integrity_requires_investigation');
}));
test('unexpected DB states and wrong IDs fail closed',()=>fixture(async a=>{
 for(const change of [
  {claim_state:'approved'},
  {claim_id:randomUUID()},
  {claim_state:'claimed_for_quarantine',withdrawn_at:'2026-10-11T00:00:00Z'},
  {snapshot:{...a.response.snapshot,key_id:'!'}},
  {snapshot:{...a.response.snapshot,envelope_version:3}},
  {snapshot:{...a.response.snapshot,plain_bytes:900000000}},
 ]){
  Object.assign(a.response,change);
  const reader=createLocalTrustedCustodyReader(a.config);
  await assert.rejects(reader.read(a.expected.claimId),denied);
  Object.assign(a.response,{
   claim_id:a.expected.claimId,claim_state:'claimed_for_quarantine',
   withdrawn_at:null,snapshot:{...a.response.snapshot,...{}},
  });
  a.response.snapshot=null; // Reconstruct a complete valid snapshot below.
  // This loop deliberately never reuses an unverified mutated snapshot.
  const p=await buildOfflineCustodyManifestProposal(a.args);
  a.response.snapshot={
    claim_id:p.p_claim_id,intent_id:p.p_intent_id,
    applicant_id:p.p_applicant_id,application_id:p.p_application_id,
    check_id:p.p_check_id,plain_sha256:p.p_plain_sha256,
    sealed_sha256:p.p_sealed_sha256,plain_bytes:p.p_plain_bytes,
    sealed_bytes:p.p_sealed_bytes,mime:p.p_mime,key_id:p.p_key_id,
    envelope_version:2,state:'pending_independent_reconciliation',
  };
 }
}));
test('loopback only, no client credentials or network-error secrets',async()=>{
 for(const address of ['https://127.0.0.1:54321','http://localhost:54321',
  'http://192.168.1.1:54321','http://evil@127.0.0.1:54321']){
  assert.throws(()=>createLocalTrustedCustodyReader({
   supabaseUrl:address,serviceRoleKey:fakeKey,
  }),denied);
 }
 const reader=createLocalTrustedCustodyReader({
  supabaseUrl:'http://127.0.0.1:54321',serviceRoleKey:fakeKey,
  fetchImpl:async()=>{throw Error('very secret upstream token');},
 });
 await assert.rejects(reader.read(randomUUID()),e=>{
  assert.ok(denied(e));assert.ok(!e.message.includes('secret'));return true;
 });
});
test('synthetic-only mode: cannot run reconciliation under live or prod mode',()=>fixture(async a=>{
 await assert.rejects(createLocalTrustedCustodyReader(a.config)
   .reconcileSynthetic({...a.args,mode:'production'}),denied);
}));
