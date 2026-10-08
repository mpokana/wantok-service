// INTERNAL OFFLINE PROTOTYPE ONLY. No user uploads, DB writes or reviewer release.
import { createCipheriv, createDecipheriv, createHash, randomBytes } from 'node:crypto';
import { lstat, open, readFile, link, unlink, realpath } from 'node:fs/promises';
import { basename, isAbsolute, join, relative, sep } from 'node:path';
import { tmpdir } from 'node:os';
import { inspectAndScanEvidence, EvidenceError, MAX_BYTES } from './scan.mjs';
import { scanWithFreshClamd } from './freshness.mjs';

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const KEY_ID = /^[a-zA-Z0-9][a-zA-Z0-9._-]{0,63}$/;
const MAGIC = Buffer.from('WQE2');
const LIMIT = 4096;
const TEST_ONLY = 'OFFLINE_SYNTHETIC_FIXTURE_ONLY';

function refuse() {
  throw new EvidenceError('CUSTODY_NOT_READY', 'Sealed offline custody operation denied');
}
function checkedIds(binding) {
  for (const field of ['claimId','intentId','subjectId','checkId','applicationId']) {
    if (typeof binding?.[field] !== 'string' || !UUID.test(binding[field])) refuse();
  }
}
async function scratch(root) {
  if (typeof root !== 'string' || !isAbsolute(root)) refuse();
  let actual, expected, stat;
  try {
    [actual,expected,stat] = await Promise.all([realpath(root),realpath(tmpdir()),lstat(root)]);
  } catch { refuse(); }
  const rel = relative(expected, actual);
  // Absolute top-level system temp *child*, not a repository or permanent vault.
  if (!stat.isDirectory() || stat.isSymbolicLink() ||
      !rel.startsWith('wantok-offline-custody-') || rel.includes(sep) ||
      rel === '..' || basename(actual) !== rel) refuse();
  return actual;
}
function paths(root, claimId) {
  return Object.freeze({
    lock: join(root, claimId + '.lock'),
    pending: join(root, claimId + '.pending'),
    held: join(root, claimId + '.held'),
  });
}
async function existsRegular(path) {
  try {
    const stat = await lstat(path);
    if (!stat.isFile() || stat.isSymbolicLink()) refuse();
    return true;
  } catch (error) {
    if (error?.code === 'ENOENT') return false;
    throw error;
  }
}
/**
 * Read-only crash inventory: NEVER repairs files or reopens a consumed claim.
 * Lock or pending artifacts require investigation, not blind replay.
 */
export async function inspectOfflineCustody({ root, claimId }) {
  if (typeof claimId !== 'string' || !UUID.test(claimId)) refuse();
  const fsRoot = await scratch(root);
  const p = paths(fsRoot, claimId);
  const [lock, pending, held] = await Promise.all([
    existsRegular(p.lock), existsRegular(p.pending), existsRegular(p.held),
  ]);
  const state = held ?
    ((lock || pending) ? 'sealed_needs_reconciliation' : 'sealed_candidate') :
    (pending ? 'interrupted_pending' : lock ? 'interrupted_lock_only' : 'absent');
  return Object.freeze({
    claimId, state, requiresManualReconciliation: lock || pending,
    reviewerAccessPermitted:false, storagePermitted:false, approved:false,
  });
}
function metadata(binding, scan, keyId) {
  return Object.freeze({
    v:2, claimId:binding.claimId, intentId:binding.intentId,
    subjectId:binding.subjectId, applicationId:binding.applicationId,
    checkId:binding.checkId, keyId, sha256:scan.sha256,
    bytes:scan.bytes, mime:scan.mime, scannedAt:new Date().toISOString(),
    state:'sealed_candidate_not_released',
  });
}
/**
 * A self-contained AES-GCM envelope: header + authenticated metadata + IV/tag
 * + ciphertext. One hard-link publication rejects replace-on-rename races.
 * This is a scratch simulation, NOT accepted NTFS ACL, KMS or DB/file atomicity.
 *
 * The verification callback here is a TEST DOUBLE. No trusted claim adapter
 * is attached; a real JWT or real applicant document must never be passed.
 */
export async function sealOfflineCustodyCandidate({
  mode, root, binding, keyId, key, filename, declaredMime, bytes,
  verifyClaim, scanner = scanWithFreshClamd, simulateCrashAt = null,
}) {
  if (![null,'after_pending_sync','after_exclusive_publish'].includes(simulateCrashAt)) refuse();
  if (mode !== TEST_ONLY || !Buffer.isBuffer(key) || key.length !== 32 ||
      typeof keyId !== 'string' || !KEY_ID.test(keyId) ||
      typeof verifyClaim !== 'function' || !Buffer.isBuffer(bytes)) refuse();
  checkedIds(binding);
  const fsRoot = await scratch(root);
  const verified = await verifyClaim(Object.freeze({...binding}));
  if (!verified || verified.eligible !== true ||
      verified.state !== 'claimed_for_quarantine' ||
      verified.storagePermitted !== false || verified.reviewerAccessPermitted !== false ||
      verified.approved !== false ||
      ['claimId','intentId','subjectId','checkId','applicationId']
        .some(k => verified[k] !== binding[k])) refuse();

  const scan = await inspectAndScanEvidence({filename,declaredMime,bytes,scanner});
  if (scan.verdict !== 'candidate_clean') refuse();
  const meta = metadata(binding,scan,keyId);
  const metadataBytes = Buffer.from(JSON.stringify(meta),'utf8');
  if (metadataBytes.length > LIMIT) refuse();
  const iv = randomBytes(12);
  const cipher = createCipheriv('aes-256-gcm', key, iv);
  cipher.setAAD(metadataBytes);
  const ciphertext = Buffer.concat([cipher.update(bytes),cipher.final()]);
  const length = Buffer.alloc(4);
  length.writeUInt32BE(metadataBytes.length);
  const envelope = Buffer.concat([
    MAGIC,length,metadataBytes,iv,cipher.getAuthTag(),ciphertext,
  ]);
  const p = paths(fsRoot, binding.claimId);
  // The lock is exclusive. Never delete it on error: an interrupted write is
  // a forensic state, not permission to retry a one-time DB claim.
  if (await existsRegular(p.held) || await existsRegular(p.pending)) refuse();
  const lock = await open(p.lock,'wx',0o600);
  try { await lock.writeFile('OFFLINE_LOCK_V1\n'); await lock.sync(); }
  finally { await lock.close(); }
  const pending = await open(p.pending,'wx',0o600);
  try { await pending.writeFile(envelope); await pending.sync(); }
  finally { await pending.close(); }
  if (simulateCrashAt === 'after_pending_sync') refuse(); // Synthetic crash injection.
  // Atomic exclusive publication ON THE SAME filesystem. No rename-overwrite.
  await link(p.pending,p.held);
  if (simulateCrashAt === 'after_exclusive_publish') refuse();
  await unlink(p.pending);
  await unlink(p.lock);
  return Object.freeze({
    claimId:binding.claimId, intentId:binding.intentId, keyId,
    sha256:scan.sha256, ciphertextSha256:createHash('sha256').update(envelope).digest('hex'),
    bytes:scan.bytes, state:'sealed_candidate_not_released',
    reviewerAccessPermitted:false, storagePermitted:false, approved:false,
  });
}
/** Offline integrity check only: no caller-visible decrypted document bytes. */
export async function verifyOfflineCustody({root, claimId, keyId, key, expected}) {
  if (!Buffer.isBuffer(key) || key.length !== 32 ||
      typeof keyId !== 'string' || !KEY_ID.test(keyId)) refuse();
  if (expected) { checkedIds(expected); if (expected.claimId !== claimId) refuse(); }
  const inventory = await inspectOfflineCustody({root,claimId});
  if (inventory.state !== 'sealed_candidate') refuse();
  const payload = await readFile(join(await scratch(root),claimId+'.held'));
  if (payload.length < 8+2+12+16 || payload.length > MAX_BYTES+LIMIT+64 ||
      !payload.subarray(0,4).equals(MAGIC)) refuse();
  const size = payload.readUInt32BE(4);
  if (!size || size > LIMIT || payload.length < 8+size+28) refuse();
  const aad=payload.subarray(8,8+size);
  let meta;
  try { meta=JSON.parse(aad.toString('utf8')); } catch { refuse(); }
  if (meta?.v !== 2 || meta?.claimId !== claimId || meta?.keyId !== keyId ||
      meta?.state !== 'sealed_candidate_not_released' ||
      !Number.isInteger(meta.bytes) || meta.bytes < 12 || meta.bytes > MAX_BYTES ||
      typeof meta.sha256 !== 'string' || !/^[0-9a-f]{64}$/.test(meta.sha256) ||
      ['intentId','subjectId','checkId','applicationId'].some(k=>!UUID.test(meta[k])) ||
      (expected && ['intentId','subjectId','checkId','applicationId'].some(k=>expected[k] !== meta[k])))
    refuse();
  const offset=8+size;
  const decipher=createDecipheriv('aes-256-gcm',key,payload.subarray(offset,offset+12));
  decipher.setAAD(aad);
  decipher.setAuthTag(payload.subarray(offset+12,offset+28));
  const partial=decipher.update(payload.subarray(offset+28));
  let tail=Buffer.alloc(0);
  try {
    tail=decipher.final();
    const hash=createHash('sha256').update(partial).update(tail).digest('hex');
    if (partial.length + tail.length !== meta.bytes || hash !== meta.sha256) refuse();
    return Object.freeze({
      claimId, keyId, sha256:hash, plainBytes:meta.bytes,
      sealedBytes:payload.length, mime:meta.mime,
      ciphertextSha256:createHash('sha256').update(payload).digest('hex'),
      valid:true, reviewerAccessPermitted:false, storagePermitted:false, approved:false,
    });
  } catch { refuse(); }
  finally { partial.fill(0); tail.fill(0); }
}

/**
 * Build metadata-only RPC arguments from a verified SYNTHETIC envelope.
 * This function does not contact Postgres, obtain a claim, or publish a file.
 * Only a separately authorised future service could ever submit these args.
 */
export async function buildOfflineCustodyManifestProposal({
  mode, root, expected, keyId, key,
}) {
  if (mode !== TEST_ONLY) refuse();
  checkedIds(expected);
  const result = await verifyOfflineCustody({
    root,claimId:expected.claimId,keyId,key,expected,
  });
  if (!result.valid || !Number.isInteger(result.plainBytes) ||
      !Number.isInteger(result.sealedBytes) ||
      !['application/pdf','image/jpeg','image/png'].includes(result.mime) ||
      result.sealedBytes <= result.plainBytes ||
      result.sealedBytes > result.plainBytes + 8192) refuse();
  return Object.freeze({
    p_claim_id:expected.claimId,
    p_intent_id:expected.intentId,
    p_applicant_id:expected.subjectId,
    p_application_id:expected.applicationId,
    p_check_id:expected.checkId,
    p_plain_sha256:result.sha256,
    p_sealed_sha256:result.ciphertextSha256,
    p_plain_bytes:result.plainBytes,
    p_sealed_bytes:result.sealedBytes,
    p_mime:result.mime,
    p_key_id:keyId,
  });
}
