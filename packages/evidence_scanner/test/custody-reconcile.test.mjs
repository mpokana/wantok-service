import test from 'node:test';
import assert from 'node:assert/strict';
import { randomBytes, randomUUID } from 'node:crypto';
import { mkdtemp, rm, writeFile, readFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import {
  sealOfflineCustodyCandidate, buildOfflineCustodyManifestProposal,
} from '../src/custody.mjs';
import { reconcileOfflineCustodySnapshot } from '../src/custody-reconcile.mjs';
import { EvidenceError } from '../src/scan.mjs';

const mode = 'OFFLINE_SYNTHETIC_FIXTURE_ONLY';
const pdf = Buffer.from('%PDF-1.7\n1 0 obj\n<<>>\nendobj\n%%EOF\n','ascii');
const denied = e => e instanceof EvidenceError && e.code === 'CUSTODY_NOT_READY';

async function fixture(work, {seal=true}={}) {
  const root=await mkdtemp(join(tmpdir(),'wantok-offline-custody-'));
  const expected={
    claimId:randomUUID(),intentId:randomUUID(),subjectId:randomUUID(),
    applicationId:randomUUID(),checkId:randomUUID(),
  };
  const key=randomBytes(32),keyId='test-data-key-01';
  try {
    const submission={
      mode,root,binding:expected,keyId,key,
      filename:'safe.pdf',declaredMime:'application/pdf',bytes:pdf,
      verifyClaim:async()=>({...expected,eligible:true,state:'claimed_for_quarantine',
        storagePermitted:false,reviewerAccessPermitted:false,approved:false}),
      scanner:async()=>({verdict:'candidate_clean'}),
    };
    if(seal) await sealOfflineCustodyCandidate(submission);
    const proposal=seal ? await buildOfflineCustodyManifestProposal({
      mode,root,expected,keyId,key,
    }) : null;
    const snapshot=proposal ? {
      claim_id:proposal.p_claim_id, intent_id:proposal.p_intent_id,
      applicant_id:proposal.p_applicant_id,
      application_id:proposal.p_application_id,check_id:proposal.p_check_id,
      plain_sha256:proposal.p_plain_sha256,
      sealed_sha256:proposal.p_sealed_sha256,
      plain_bytes:proposal.p_plain_bytes,
      sealed_bytes:proposal.p_sealed_bytes,
      mime:proposal.p_mime,key_id:proposal.p_key_id,
      envelope_version:2,state:'pending_independent_reconciliation',
    } : null;
    const args={mode,root,expected,keyId,key,snapshot,
      claimState:{state:'claimed_for_quarantine',withdrawnAt:null}};
    return await work(args);
  } finally {
    key.fill(0);
    await rm(root,{recursive:true,force:true});
  }
}

test('matching offline sealed envelope and snapshot remain NOT released',async()=>fixture(async args=>{
  const r=await reconcileOfflineCustodySnapshot(args);
  assert.equal(r.state,'snapshot_matches_still_pending_independent_reconciliation');
  assert.equal(r.requiresManualReconciliation,true);
  assert.equal(r.storagePermitted,false);
  assert.equal(r.reviewerAccessPermitted,false);
  assert.equal(r.uploadedToSupabase,false);
  assert.equal(r.approved,false);
  assert.equal(Object.isFrozen(r),true);
  assert.deepEqual(Object.keys(r).sort(),[
    'claimId','state','requiresManualReconciliation','storagePermitted',
    'reviewerAccessPermitted','approved','uploadedToSupabase',
  ].sort());
}));
test('missing sealed file is never mistaken for matching custody',async()=>fixture(async args=>{
  const r=await reconcileOfflineCustodySnapshot({...args,snapshot:null});
  assert.equal(r.state,'missing_sealed_candidate');
},{seal:false}));
test('metadata record missing leaves sealed file under manual investigation',async()=>fixture(async args=>{
  const r=await reconcileOfflineCustodySnapshot({...args,snapshot:null});
  assert.equal(r.state,'missing_metadata_snapshot');
}));
test('withdrawal blocks matching snapshot regardless of ciphertext integrity',async()=>fixture(async args=>{
  const r=await reconcileOfflineCustodySnapshot({
    ...args,claimState:{state:'withdrawn',withdrawnAt:new Date().toISOString()},
  });
  assert.equal(r.state,'claim_withdrawn_no_release');
}));
test('withdrawn timestamp blocks even when state erroneously still claimed',async()=>fixture(async args=>{
  const r=await reconcileOfflineCustodySnapshot({
    ...args,claimState:{state:'claimed_for_quarantine',withdrawnAt:new Date().toISOString()},
  });
  assert.equal(r.state,'claim_withdrawn_no_release');
}));
test('wrong ciphertext digest is marked mismatch',async()=>fixture(async args=>{
  const r=await reconcileOfflineCustodySnapshot({
    ...args,snapshot:{...args.snapshot,sealed_sha256:'0'.repeat(64)},
  });
  assert.equal(r.state,'metadata_mismatch_requires_investigation');
}));
test('different user, application, check or claim snapshot is marked mismatch',async()=>fixture(async args=>{
  for(const field of ['claim_id','intent_id','applicant_id','application_id','check_id']){
    const r=await reconcileOfflineCustodySnapshot({
      ...args,snapshot:{...args.snapshot,[field]:randomUUID()},
    });
    assert.equal(r.state,'metadata_mismatch_requires_investigation');
  }
}));
test('different key version, mime, size, envelope version, or state is marked mismatch',async()=>fixture(async args=>{
  const variants=[
    {key_id:'another-version'},{mime:'application/octet-stream'},
    {plain_bytes:123456},{sealed_bytes:987654},{envelope_version:3},
    {state:'reviewer_released'},
  ];
  for(const variant of variants){
    const r=await reconcileOfflineCustodySnapshot({
      ...args,snapshot:{...args.snapshot,...variant},
    });
    assert.equal(r.state,'metadata_mismatch_requires_investigation');
  }
}));
test('tampered ciphertext produces a non-releasing integrity investigation result',async()=>fixture(async args=>{
  const path=join(args.root,args.expected.claimId+'.held');
  const payload=await readFile(path);
  payload[payload.length-1]^=1;
  await writeFile(path,payload);
  const r=await reconcileOfflineCustodySnapshot(args);
  assert.equal(r.state,'sealed_integrity_requires_investigation');
  assert.equal(r.reviewerAccessPermitted,false);
}));
test('wrong key is not revealed in the reconciliation report',async()=>fixture(async args=>{
  const r=await reconcileOfflineCustodySnapshot({...args,key:randomBytes(32)});
  assert.equal(r.state,'sealed_integrity_requires_investigation');
  assert.equal(JSON.stringify(r).includes(args.snapshot.sealed_sha256),false);
}));
test('interrupted pending file is blocked regardless of manifest data',async()=>fixture(async args=>{
  await writeFile(join(args.root,args.expected.claimId+'.pending'),'forensic artifact');
  const r=await reconcileOfflineCustodySnapshot(args);
  assert.equal(r.state,'interrupted_custody_requires_investigation');
}));
test('unapproved mode and invalid claim state are rejected',async()=>fixture(async args=>{
  await assert.rejects(reconcileOfflineCustodySnapshot({...args,mode:'live'}),denied);
  await assert.rejects(reconcileOfflineCustodySnapshot({
    ...args,claimState:{state:'approved'},
  }),denied);
}));
