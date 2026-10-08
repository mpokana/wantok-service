import test from 'node:test';
import assert from 'node:assert/strict';
import { randomBytes, randomUUID } from 'node:crypto';
import { mkdtemp, readFile, writeFile, readdir, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { quarantineWithVerifiedIntent, verifyQuarantineIntegrity } from '../src/quarantine.mjs';
import { EvidenceError } from '../src/scan.mjs';

const good=Buffer.from('%PDF-1.7\n1 0 obj\n<<>>\nendobj\n%%EOF\n','ascii');
const key=()=>randomBytes(32);
const subjectId=randomUUID();
const checkId=randomUUID();
const applicationId=randomUUID();
const intentId=randomUUID();
async function fixture(run) {
 const root=await mkdtemp(join(tmpdir(),'wantok-quarantine-test-'));
 try {return await run(root);} finally {await rm(root,{recursive:true,force:true});}
}
function make(root,opts={}) {
 const id=opts.intentId??intentId;
 return {
  root, key:opts.key??key(), intentId:id, subjectId,checkId,applicationId,
  filename:'example.pdf',declaredMime:'application/pdf',bytes:good,
  verifyIntent: async () => ({
   intentId:id,subjectId,checkId,applicationId,state:'awaiting_secure_gateway',eligible:true,
  }),
  scanner:async()=>({verdict:'candidate_clean'}),
  ...opts,
 };
}
const forbidden=(e)=>e instanceof EvidenceError && e.code==='QUARANTINE_NOT_READY';

test('valid, scanned bytes are encrypted only, never released',async()=>fixture(async root=>{
 const f=make(root);
 const result=await quarantineWithVerifiedIntent(f);
 assert.equal(result.state,'quarantined_not_released');
 assert.equal(result.reviewerAccessPermitted,false);
 assert.equal(result.uploadedToSupabase,false);
 assert.equal(result.approved,false);
 const files=await readdir(root);
 assert.equal(files.length,2);
 const blob=await readFile(join(root,f.intentId+'.qenc'));
 assert.ok(blob.subarray(0,4).equals(Buffer.from('WQE1')));
 assert.equal(blob.includes(good),false);
 assert.notEqual(blob.toString('utf8').includes('%PDF-'),true);
 const receipt=await readFile(join(root,f.intentId+'.receipt.json'),'utf8');
 assert.equal(receipt.includes('%PDF'),false);
 assert.equal(receipt.includes('example.pdf'),false);
 const checked=await verifyQuarantineIntegrity(f);
 assert.equal(checked.valid,true);
 assert.equal(checked.reviewerAccessPermitted,false);
}));

test('unverified caller never scans and never writes',async()=>fixture(async root=>{
 let scans=0;
 const f=make(root,{
  verifyIntent:async()=>({...{intentId,subjectId,checkId,applicationId},
    state:'awaiting_secure_gateway',eligible:false}),
  scanner:async()=>{scans++;return{verdict:'candidate_clean'};},
 });
 await assert.rejects(quarantineWithVerifiedIntent(f),forbidden);
 assert.equal(scans,0);
 assert.deepEqual(await readdir(root),[]);
}));

test('missing server-side gate cannot be bypassed',async()=>fixture(async root=>{
 await assert.rejects(quarantineWithVerifiedIntent(make(root,{verifyIntent:undefined})),forbidden);
 assert.deepEqual(await readdir(root),[]);
}));

test('failed scanner never creates a file',async()=>fixture(async root=>{
 await assert.rejects(quarantineWithVerifiedIntent(make(root,{scanner:async()=>{throw new EvidenceError('MALWARE_FOUND','reject')}})),
  e=>e.code==='MALWARE_FOUND');
 assert.deepEqual(await readdir(root),[]);
}));

test('scanner-unavailable verdict cannot be accepted',async()=>fixture(async root=>{
 await assert.rejects(quarantineWithVerifiedIntent(make(root,{scanner:async()=>({verdict:'unavailable'})})),
  e=>e.code==='SCANNER_UNAVAILABLE');
 assert.deepEqual(await readdir(root),[]);
}));

test('a second attempt cannot replace encrypted evidence',async()=>fixture(async root=>{
 const f=make(root);
 await quarantineWithVerifiedIntent(f);
 const old=await readFile(join(root,intentId+'.qenc'));
 await assert.rejects(quarantineWithVerifiedIntent(f),e=>e.code==='EEXIST');
 const current=await readFile(join(root,intentId+'.qenc'));
 assert.deepEqual(old,current);
}));

test('ciphertext tampering fails authenticated decryption',async()=>fixture(async root=>{
 const f=make(root);
 await quarantineWithVerifiedIntent(f);
 const path=join(root,intentId+'.qenc');
 const blob=await readFile(path);
 blob[blob.length-1]^=0x01;
 await writeFile(path,blob);
 await assert.rejects(verifyQuarantineIntegrity(f));
}));

test('receipt digest tampering cannot pass GCM or SHA check',async()=>fixture(async root=>{
 const f=make(root);
 await quarantineWithVerifiedIntent(f);
 const path=join(root,intentId+'.receipt.json');
 const receipt=JSON.parse(await readFile(path,'utf8'));
 receipt.sha256='0'.repeat(64);
 await writeFile(path,JSON.stringify(receipt));
 await assert.rejects(verifyQuarantineIntegrity(f));
}));

test('wrong encryption key cannot authenticate or recover any content',async()=>fixture(async root=>{
 const f=make(root);
 await quarantineWithVerifiedIntent(f);
 await assert.rejects(verifyQuarantineIntegrity({...f,key:key()}));
}));

test('input with unsupported signature cannot create quarantine file',async()=>fixture(async root=>{
 const f=make(root,{bytes:Buffer.from('This text is not PDF content')});
 await assert.rejects(quarantineWithVerifiedIntent(f),e=>e.code==='INVALID_CONTENT');
 assert.deepEqual(await readdir(root),[]);
}));

test('invalid or missing 256-bit key is rejected before scanning',async()=>fixture(async root=>{
 let scans=0;
 const f=make(root,{key:Buffer.alloc(10),scanner:async()=>{scans++;return{verdict:'candidate_clean'}}});
 await assert.rejects(quarantineWithVerifiedIntent(f),forbidden);
 assert.equal(scans,0);
 assert.deepEqual(await readdir(root),[]);
}));
