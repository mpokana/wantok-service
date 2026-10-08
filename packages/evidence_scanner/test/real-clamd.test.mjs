// Real integration tests. Requires a running local clamd at 127.0.0.1:3310.
// NEVER part of the default simulated unit test gate.
// This file opens no upload API and stores no applicant files.
import test from 'node:test';
import assert from 'node:assert/strict';
import {scanWithClamd, inspectAndScanEvidence, EvidenceError} from '../src/scan.mjs';
import {requireFreshClamd, scanWithFreshClamd} from '../src/freshness.mjs';
import {quarantineWithVerifiedIntent, verifyQuarantineIntegrity} from '../src/quarantine.mjs';
import {sealOfflineCustodyCandidate, verifyOfflineCustody} from '../src/custody.mjs';
import {randomBytes,randomUUID} from 'node:crypto';
import {mkdtemp,rm,readdir} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {join} from 'node:path';

const good = Buffer.from('%PDF-1.7\n1 0 obj\n<<>>\nendobj\n%%EOF\n', 'ascii');
const eicar = Buffer.from(
  'X5O!P%@AP[4\\PZX54(P^)7CC)7}' +
  '$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*', 'ascii');

test('real ClamAV signature timestamp is fresh and preflight gates scanning', async () => {
  const health = await requireFreshClamd({timeoutMs:20000});
  assert.equal(health.fresh,true);
  assert.ok(health.signatureVersion > 0);
  const verdict = await scanWithFreshClamd(good,{timeoutMs:20000});
  assert.equal(verdict.verdict,'candidate_clean');
});

test('real ClamAV socket recognises a clean in-memory PDF-like payload', async () => {
  const r = await scanWithClamd(good, {timeoutMs:20000});
  assert.equal(r.verdict, 'candidate_clean');
});

test('real ClamAV detects official harmless EICAR antivirus test signature', async () => {
  assert.equal(eicar.length,68);
  await assert.rejects(
    scanWithClamd(eicar, {timeoutMs:20000}),
    error => error instanceof EvidenceError && error.code === 'MALWARE_FOUND',
  );
});

test('real ClamAV clean verdict never releases storage, review or provider approval', async () => {
  const result = await inspectAndScanEvidence({
    filename:'test-document.pdf',
    declaredMime:'application/pdf',
    bytes:good,
    scanner: buffer => scanWithClamd(buffer, {timeoutMs:20000}),
  });
  assert.equal(result.verdict,'candidate_clean');
  assert.equal(result.storagePermitted,false);
  assert.equal(result.reviewerAccessPermitted,false);
  assert.equal(result.approved,false);
});

test('real clean scan produces encrypted held ciphertext and no reviewer access', async () => {
  const root=await mkdtemp(join(tmpdir(),'wantok-real-av-quarantine-'));
  const intentId=randomUUID(),subjectId=randomUUID(),checkId=randomUUID(),applicationId=randomUUID();
  const key=randomBytes(32);
  try {
    const input={root,key,intentId,subjectId,checkId,applicationId,
      bytes:good,filename:'test-document.pdf',declaredMime:'application/pdf',
      verifyIntent:async()=>({eligible:true,state:'awaiting_secure_gateway',
        intentId,subjectId,checkId,applicationId})};
    const receipt=await quarantineWithVerifiedIntent(input);
    assert.equal(receipt.state,'quarantined_not_released');
    assert.equal(receipt.reviewerAccessPermitted,false);
    assert.equal(receipt.uploadedToSupabase,false);
    assert.equal((await readdir(root)).length,2);
    assert.equal((await verifyQuarantineIntegrity(input)).valid,true);
  } finally {
    await rm(root,{recursive:true,force:true});
  }
});

// Explicit OFFLINE fixture: real scanner + single-file claim-bound envelope.
test('real ClamAV scans before offline claim-bound sealed envelope publication', async () => {
  const root=await mkdtemp(join(tmpdir(),'wantok-offline-custody-'));
  const binding={claimId:randomUUID(),intentId:randomUUID(),subjectId:randomUUID(),
    applicationId:randomUUID(),checkId:randomUUID()};
  const key=randomBytes(32);
  try {
    const sealed=await sealOfflineCustodyCandidate({
      mode:'OFFLINE_SYNTHETIC_FIXTURE_ONLY',root,binding,
      keyId:'synthetic-key-v1',key,
      filename:'synthetic.pdf',declaredMime:'application/pdf',bytes:good,
      verifyClaim:async()=>({...binding,eligible:true,state:'claimed_for_quarantine',
        storagePermitted:false,reviewerAccessPermitted:false,approved:false}),
    });
    assert.equal(sealed.state,'sealed_candidate_not_released');
    assert.equal(sealed.storagePermitted,false);
    assert.equal((await readdir(root)).length,1);
    const integrity=await verifyOfflineCustody({
      root,claimId:binding.claimId,keyId:'synthetic-key-v1',key,expected:binding,
    });
    assert.equal(integrity.valid,true);
    assert.equal(integrity.reviewerAccessPermitted,false);
  } finally {
    key.fill(0);
    await rm(root,{recursive:true,force:true});
  }
});
