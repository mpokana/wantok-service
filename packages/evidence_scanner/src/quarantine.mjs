import { createCipheriv, createDecipheriv, randomBytes, createHash } from 'node:crypto';
import { lstat, mkdir, readFile, unlink, writeFile } from 'node:fs/promises';
import { isAbsolute, join } from 'node:path';
import { inspectAndScanEvidence, EvidenceError } from './scan.mjs';
import { scanWithFreshClamd } from './freshness.mjs';

const ID = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const HEADER = Buffer.from('WQE1');
const VERSION = 1;

function insist(condition, message) {
  if (!condition) throw new EvidenceError('QUARANTINE_NOT_READY', message);
}
async function requireRoot(root) {
  insist(typeof root === 'string' && isAbsolute(root), 'An absolute private quarantine root is required');
  await mkdir(root, {recursive: true, mode:0o700});
  const st = await lstat(root);
  insist(st.isDirectory() && !st.isSymbolicLink(), 'Quarantine directory is not a regular directory');
  return root;
}
function aadFor(receipt) {
  return Buffer.from(JSON.stringify({
    v:receipt.v, intentId:receipt.intentId, subjectId:receipt.subjectId,
    checkId:receipt.checkId, applicationId:receipt.applicationId,
    sha256:receipt.sha256, bytes:receipt.bytes, mime:receipt.mime,
  }),'utf8');
}
function fields({intentId, subjectId, checkId, applicationId, key}) {
  for (const [name, value] of Object.entries({intentId,subjectId,checkId,applicationId})) {
    insist(typeof value==='string' && ID.test(value), 'Invalid '+name);
  }
  insist(Buffer.isBuffer(key) && key.length === 32, 'Separate 256-bit quarantine key required');
}

/*
 * INTERNAL-ONLY encryption and quarantine prototype. No HTTP routes, Storage
 * grants, review access or provider approvals. The verifyIntent callback must
 * be implemented by a separate trusted authenticated server, never a client.
 * No upload gateway is activated by this library.
 */
export async function quarantineWithVerifiedIntent({
  intentId, subjectId, checkId, applicationId,
  filename, declaredMime, bytes, key, root,
  verifyIntent, scanner = scanWithFreshClamd,
}) {
  fields({intentId,subjectId,checkId,applicationId,key});
  insist(typeof verifyIntent === 'function', 'Trusted intent verifier is mandatory');
  insist(Buffer.isBuffer(bytes), 'Buffer required');
  const permission = await verifyIntent({intentId,subjectId,checkId,applicationId});
  insist(permission?.intentId === intentId && permission?.subjectId === subjectId &&
    permission?.checkId === checkId && permission?.applicationId === applicationId &&
    permission?.state === 'awaiting_secure_gateway' && permission?.eligible === true,
    'Authenticated evidence intent not verified');
  const scan = await inspectAndScanEvidence({filename, declaredMime, bytes, scanner});
  insist(scan.verdict === 'candidate_clean', 'No clean scan');
  const target = await requireRoot(root);
  const receipt = Object.freeze({
    v:VERSION, intentId, subjectId, checkId, applicationId,
    sha256:scan.sha256, bytes:scan.bytes, mime:scan.mime,
    state:'quarantined_not_released',
    scannedAt:new Date().toISOString(),
  });
  const iv=randomBytes(12);
  const cipher=createCipheriv('aes-256-gcm',key,iv);
  cipher.setAAD(aadFor(receipt));
  const encrypted=Buffer.concat([cipher.update(bytes),cipher.final()]);
  const blob=Buffer.concat([HEADER,iv,cipher.getAuthTag(),encrypted]);
  const blobPath=join(target,intentId+'.qenc');
  const receiptPath=join(target,intentId+'.receipt.json');
  let blobCreated=false;
  try {
    await writeFile(blobPath,blob,{flag:'wx',mode:0o600});
    blobCreated=true;
    await writeFile(receiptPath,JSON.stringify(receipt)+'\n',{flag:'wx',mode:0o600});
  } catch (error) {
    if (blobCreated) await unlink(blobPath).catch(()=>{});
    throw error;
  }
  return Object.freeze({
    intentId, sha256:scan.sha256, bytes:scan.bytes,
    state:'quarantined_not_released',
    reviewerAccessPermitted:false, approved:false, uploadedToSupabase:false,
  });
}

/** Integrity check ONLY. Never releases decrypted document bytes. */
export async function verifyQuarantineIntegrity({intentId,root,key}) {
  insist(typeof intentId==='string' && ID.test(intentId), 'Invalid intent ID');
  insist(Buffer.isBuffer(key) && key.length===32, 'Quarantine key required');
  const target=await requireRoot(root);
  const receipt=JSON.parse(await readFile(join(target,intentId+'.receipt.json'),'utf8'));
  insist(receipt.v===VERSION && receipt.intentId===intentId &&
    receipt.state==='quarantined_not_released','Invalid receipt');
  const blob=await readFile(join(target,intentId+'.qenc'));
  insist(blob.length>=32 && blob.subarray(0,4).equals(HEADER),'Invalid sealed object');
  const iv=blob.subarray(4,16),tag=blob.subarray(16,32),encrypted=blob.subarray(32);
  const decipher=createDecipheriv('aes-256-gcm',key,iv);
  decipher.setAAD(aadFor(receipt));
  decipher.setAuthTag(tag);
  const plaintext=Buffer.concat([decipher.update(encrypted),decipher.final()]);
  try {
    insist(plaintext.length===receipt.bytes &&
      createHash('sha256').update(plaintext).digest('hex')===receipt.sha256,
      'Evidence hash mismatch');
    return Object.freeze({
      intentId,sha256:receipt.sha256,valid:true,
      reviewerAccessPermitted:false,approved:false,
    });
  } finally {
    plaintext.fill(0);
  }
}
