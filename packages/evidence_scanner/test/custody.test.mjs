import test from 'node:test';
import assert from 'node:assert/strict';
import {randomUUID,randomBytes} from 'node:crypto';
import {mkdtemp,rm,readFile,readdir,writeFile,symlink} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {sealOfflineCustodyCandidate,inspectOfflineCustody,verifyOfflineCustody} from '../src/custody.mjs';
import {EvidenceError} from '../src/scan.mjs';

const pdf=Buffer.from('%PDF-1.7\n1 0 obj\n<<>>\nendobj\n%%EOF\n','ascii');
const mode='OFFLINE_SYNTHETIC_FIXTURE_ONLY';
const denied=e=>e instanceof EvidenceError && e.code==='CUSTODY_NOT_READY';
async function fixture(action) {
  const root=await mkdtemp(join(tmpdir(),'wantok-offline-custody-'));
  try {return await action(root);}
  finally {await rm(root,{recursive:true,force:true});}
}
function input(root,opts={}) {
  const binding=Object.freeze({
    claimId:randomUUID(),intentId:randomUUID(),subjectId:randomUUID(),
    applicationId:randomUUID(),checkId:randomUUID(),
  });
  return {
    mode,root,binding,keyId:'dev-key-v1',key:randomBytes(32),
    bytes:pdf,filename:'synthetic.pdf',declaredMime:'application/pdf',
    scanner:async()=>({verdict:'candidate_clean'}),
    verifyClaim:async()=>({...binding,eligible:true,state:'claimed_for_quarantine',
      storagePermitted:false,reviewerAccessPermitted:false,approved:false}),
    ...opts,
  };
}
test('offline AES-GCM envelope is a single committed blob with bound claim and key ID',async()=>fixture(async root=>{
  const f=input(root);
  const result=await sealOfflineCustodyCandidate(f);
  assert.equal(result.state,'sealed_candidate_not_released');
  assert.equal(result.storagePermitted,false);
  assert.equal(result.reviewerAccessPermitted,false);
  assert.equal(result.approved,false);
  assert.deepEqual(await readdir(root),[f.binding.claimId+'.held']);
  const ciphertext=await readFile(join(root,f.binding.claimId+'.held'));
  assert.ok(ciphertext.subarray(0,4).equals(Buffer.from('WQE2')));
  assert.equal(ciphertext.includes(pdf),false);
  assert.equal(ciphertext.includes(f.key),false);
  assert.equal(ciphertext.toString('utf8').includes('synthetic.pdf'),false);
  assert.equal((await inspectOfflineCustody({root,claimId:f.binding.claimId})).state,'sealed_candidate');
  const verified=await verifyOfflineCustody({root,claimId:f.binding.claimId,keyId:f.keyId,key:f.key,expected:f.binding});
  assert.equal(verified.valid,true);
  assert.equal(verified.ciphertextSha256,result.ciphertextSha256);
}));
test('missing mode and untrusted claim verifier never scan or write',async()=>fixture(async root=>{
  let scanned=0;
  const f=input(root,{scanner:async()=>{scanned++;return{verdict:'candidate_clean'};}});
  await assert.rejects(sealOfflineCustodyCandidate({...f,mode:'production'}),denied);
  await assert.rejects(sealOfflineCustodyCandidate({...f,verifyClaim:async()=>({...f.binding,
    eligible:true,state:'awaiting_secure_gateway',storagePermitted:false,
    reviewerAccessPermitted:false,approved:false})}),denied);
  assert.equal(scanned,0);
  assert.deepEqual(await readdir(root),[]);
}));
test('mismatched subject/claim, reviewer flag or key ID reject before scanning',async()=>fixture(async root=>{
  let count=0;
  const f=input(root,{scanner:async()=>{count++;return{verdict:'candidate_clean'};}});
  for (const verifyClaim of [
    async()=>({...f.binding,subjectId:randomUUID(),eligible:true,state:'claimed_for_quarantine',
      storagePermitted:false,reviewerAccessPermitted:false,approved:false}),
    async()=>({...f.binding,eligible:true,state:'claimed_for_quarantine',
      storagePermitted:false,reviewerAccessPermitted:true,approved:false}),
  ]) await assert.rejects(sealOfflineCustodyCandidate({...f,verifyClaim}),denied);
  await assert.rejects(sealOfflineCustodyCandidate({...f,keyId:'../bad'}),denied);
  assert.equal(count,0);
  assert.deepEqual(await readdir(root),[]);
}));
test('scanner outage and infected verdict cannot leave any custody files',async()=>fixture(async root=>{
  const f=input(root);
  await assert.rejects(sealOfflineCustodyCandidate({...f,scanner:async()=>{throw Error('down')}}));
  await assert.rejects(sealOfflineCustodyCandidate({...f,scanner:async()=>({verdict:'infected'})}),
    e=>e?.code==='SCANNER_UNAVAILABLE');
  assert.deepEqual(await readdir(root),[]);
}));
test('duplicated claim cannot overwrite existing sealed data',async()=>fixture(async root=>{
  const f=input(root);
  await sealOfflineCustodyCandidate(f);
  const original=await readFile(join(root,f.binding.claimId+'.held'));
  await assert.rejects(sealOfflineCustodyCandidate(f),denied);
  assert.deepEqual(await readFile(join(root,f.binding.claimId+'.held')),original);
}));
test('concurrent callers cannot both publish same claim and will not overwrite',async()=>fixture(async root=>{
  const f=input(root);
  const r=await Promise.allSettled([sealOfflineCustodyCandidate(f),sealOfflineCustodyCandidate(f)]);
  assert.equal(r.filter(x=>x.status==='fulfilled').length,1);
  assert.equal(r.filter(x=>x.status==='rejected').length,1);
  assert.equal((await readdir(root)).filter(x=>x.endsWith('.held')).length,1);
  const v=await verifyOfflineCustody({root,claimId:f.binding.claimId,keyId:f.keyId,key:f.key});
  assert.equal(v.valid,true);
}));
test('ciphertext tampering fails verification without disclosing plaintext',async()=>fixture(async root=>{
  const f=input(root);
  await sealOfflineCustodyCandidate(f);
  const path=join(root,f.binding.claimId+'.held');
  const buffer=await readFile(path);
  buffer[buffer.length-1]^=1;
  await writeFile(path,buffer);
  await assert.rejects(verifyOfflineCustody({root,claimId:f.binding.claimId,keyId:f.keyId,key:f.key}),denied);
}));
test('wrong key, key ID and cross-claim binding fail integrity',async()=>fixture(async root=>{
  const f=input(root);
  await sealOfflineCustodyCandidate(f);
  await assert.rejects(verifyOfflineCustody({root,claimId:f.binding.claimId,keyId:f.keyId,key:randomBytes(32)}),denied);
  await assert.rejects(verifyOfflineCustody({root,claimId:f.binding.claimId,keyId:'another-key',key:f.key}),denied);
  await assert.rejects(verifyOfflineCustody({root,claimId:f.binding.claimId,keyId:f.keyId,key:f.key,
    expected:{...f.binding,checkId:randomUUID()}}),denied);
}));
test('orphan lock/pending are visible for manual recovery and never removed automatically',async()=>fixture(async root=>{
  const f=input(root);
  const base=join(root,f.binding.claimId);
  await writeFile(base+'.lock','LOCK');
  assert.equal((await inspectOfflineCustody({root,claimId:f.binding.claimId})).state,'interrupted_lock_only');
  await writeFile(base+'.pending',Buffer.from('PARTIAL'));
  const report=await inspectOfflineCustody({root,claimId:f.binding.claimId});
  assert.equal(report.state,'interrupted_pending');
  assert.equal(report.requiresManualReconciliation,true);
  await assert.rejects(sealOfflineCustodyCandidate(f),denied);
  assert.deepEqual((await readdir(root)).sort(),
    [f.binding.claimId+'.lock',f.binding.claimId+'.pending'].sort());
}));
test('sealed candidate with crash leftovers requires reconciliation, not automatic release',async()=>fixture(async root=>{
  const f=input(root);
  await sealOfflineCustodyCandidate(f);
  await writeFile(join(root,f.binding.claimId+'.lock'),'STALE LOCK');
  const report=await inspectOfflineCustody({root,claimId:f.binding.claimId});
  assert.equal(report.state,'sealed_needs_reconciliation');
  await assert.rejects(verifyOfflineCustody({root,claimId:f.binding.claimId,keyId:f.keyId,key:f.key}),denied);
}));
test('invented absent claim and invalid filesystem root are denied',async()=>fixture(async root=>{
  const f=input(root);
  assert.equal((await inspectOfflineCustody({root,claimId:f.binding.claimId})).state,'absent');
  await assert.rejects(sealOfflineCustodyCandidate({...f,root:tmpdir()}),denied);
  await assert.rejects(inspectOfflineCustody({root,claimId:'../bad'}),denied);
  await assert.rejects(verifyOfflineCustody({root,claimId:f.binding.claimId,keyId:f.keyId,key:f.key}),denied);
}));
test('symlink roots are rejected, where the filesystem supports junctions/symlinks',async()=>fixture(async root=>{
  const linkPath=join(tmpdir(),'wantok-offline-custody-'+randomUUID());
  try {
    try {await symlink(root,linkPath,'dir');} catch(e) {
      if (['EPERM','EACCES','ENOTSUP','UNKNOWN'].includes(e?.code)) return;
      throw e;
    }
    await assert.rejects(inspectOfflineCustody({root:linkPath,claimId:randomUUID()}),denied);
  } finally {await rm(linkPath,{force:true});}
}));

test('injected stop after pending fsync leaves encrypted pending and lock for review',async()=>fixture(async root=>{
  const f=input(root);
  await assert.rejects(sealOfflineCustodyCandidate({...f,simulateCrashAt:'after_pending_sync'}),denied);
  const p=join(root,f.binding.claimId+'.pending');
  const pending=await readFile(p);
  assert.ok(pending.subarray(0,4).equals(Buffer.from('WQE2')));
  assert.equal(pending.includes(pdf),false);
  const state=await inspectOfflineCustody({root,claimId:f.binding.claimId});
  assert.equal(state.state,'interrupted_pending');
  await assert.rejects(sealOfflineCustodyCandidate(f),denied);
}));
test('injected stop after hard-link publication stays blocked until manual reconciliation',async()=>fixture(async root=>{
  const f=input(root);
  await assert.rejects(sealOfflineCustodyCandidate({...f,simulateCrashAt:'after_exclusive_publish'}),denied);
  const state=await inspectOfflineCustody({root,claimId:f.binding.claimId});
  assert.equal(state.state,'sealed_needs_reconciliation');
  const files=await readdir(root);
  assert.equal(files.length,3);
  assert.ok(files.includes(f.binding.claimId+'.held'));
  await assert.rejects(verifyOfflineCustody({root,claimId:f.binding.claimId,keyId:f.keyId,key:f.key}),denied);
  await assert.rejects(sealOfflineCustodyCandidate(f),denied);
}));
