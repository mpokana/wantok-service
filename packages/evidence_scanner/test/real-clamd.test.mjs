// Real integration tests. Requires a running local clamd at 127.0.0.1:3310.
// NEVER part of the default simulated unit test gate.
// This file opens no upload API and stores no applicant files.
import test from 'node:test';
import assert from 'node:assert/strict';
import {scanWithClamd, inspectAndScanEvidence, EvidenceError} from '../src/scan.mjs';

const good = Buffer.from('%PDF-1.7\n1 0 obj\n<<>>\nendobj\n%%EOF\n', 'ascii');
const eicar = Buffer.from(
  'X5O!P%@AP[4\\PZX54(P^)7CC)7}' +
  '$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*', 'ascii');

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
