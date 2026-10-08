import test from 'node:test';
import assert from 'node:assert/strict';
import { createServer } from 'node:net';
import {
  inspectEvidence, inspectAndScanEvidence, scanWithClamd,
  MAX_BYTES, EvidenceError,
} from '../src/scan.mjs';

const pdf = Buffer.from('%PDF-1.7\n1 0 obj\nendobj\n%%EOF\n');
const png = Buffer.from(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/j5sAAAAASUVORK5CYII=',
  'base64',
);
const jpeg = Buffer.from([255,216,255,224,1,2,3,4,5,6,7,8,255,217]);

const valid = { filename:'evidence.pdf', declaredMime:'application/pdf', bytes:pdf };
function expectReject(fn, code) {
  assert.throws(fn, err => err instanceof EvidenceError && err.code === code);
}
async function expectAsyncReject(promise, code) {
  await assert.rejects(promise, err => err instanceof EvidenceError && err.code === code);
}

test('signature metadata is immutable SHA-256, size and MIME', () => {
  const result = inspectEvidence(valid);
  assert.equal(result.bytes, pdf.length);
  assert.equal(result.mime,'application/pdf');
  assert.match(result.sha256,/^[a-f0-9]{64}$/);
  assert.ok(Object.isFrozen(result));
});
test('PNG header, dimensions and end are structurally recognised', () => {
  assert.equal(inspectEvidence({filename:'picture.png',declaredMime:'image/png',bytes:png}).mime,'image/png');
});
test('JPEG signature is checked before scan', () => {
  assert.equal(inspectEvidence({filename:'picture.jpg',declaredMime:'image/jpeg',bytes:jpeg}).mime,'image/jpeg');
});
test('MIME is checked against filename, not blindly trusted', () => {
  expectReject(()=>inspectEvidence({...valid,declaredMime:'image/jpeg'}),'MIME_MISMATCH');
});
test('Real bytes must match filename and declared type', () => {
  expectReject(()=>inspectEvidence({...valid,filename:'fake.png',declaredMime:'image/png'}),'SIGNATURE_MISMATCH');
});
test('Unrecognised file signatures are rejected', () => {
  expectReject(()=>inspectEvidence({...valid,bytes:Buffer.from('unknown file data')}),'INVALID_CONTENT');
});
test('Encrypted ZIP and other unapproved extensions never reach scanning', () => {
  expectReject(()=>inspectEvidence({...valid,filename:'bundle.zip'}),'DISALLOWED_EXTENSION');
});
test('Windows paths and traversals are not accepted', () => {
  for(const filename of ['..\\hidden.pdf','../evil.pdf','C:\\secret.pdf','bad:stream.pdf']) {
    expectReject(()=>inspectEvidence({...valid,filename}),'INVALID_FILENAME');
  }
});
test('Bidi control, leading dot and control characters are forbidden', () => {
  for(const filename of ['evil\u202epdf.pdf','.private.pdf','bad\nname.pdf']) {
    expectReject(()=>inspectEvidence({...valid,filename}),'INVALID_FILENAME');
  }
});
test('Empty, over-limit, non-buffer input fails', () => {
  expectReject(()=>inspectEvidence({...valid,bytes:Buffer.alloc(0)}),'INVALID_SIZE');
  expectReject(()=>inspectEvidence({...valid,bytes:Buffer.alloc(MAX_BYTES+1)}),'INVALID_SIZE');
  expectReject(()=>inspectEvidence({...valid,bytes:'hello'}),'INVALID_BUFFER');
});
test('Truncated JPEG and PDF are rejected', () => {
  expectReject(()=>inspectEvidence({...valid,bytes:pdf.subarray(0,8)}),'INVALID_SIZE');
  expectReject(()=>inspectEvidence({...valid,bytes:Buffer.from('%PDF-1.7\nnone\n') }),'INVALID_CONTENT');
  expectReject(()=>inspectEvidence({filename:'snap.jpg',declaredMime:'image/jpeg',bytes:jpeg.subarray(0,-1)}),'INVALID_CONTENT');
});
test('Out-of-range PNG dimensions are rejected', () => {
  const invalid = Buffer.from(png);
  invalid.writeUInt32BE(50_000_000,16);
  expectReject(()=>inspectEvidence({filename:'large.png',declaredMime:'image/png',bytes:invalid}),'IMAGE_DIMENSIONS');
});
test('PNG with extra tail is rejected', () => {
  expectReject(()=>inspectEvidence({filename:'picture.png',declaredMime:'image/png',bytes:Buffer.concat([png,Buffer.from('JUNK')])}),'INVALID_CONTENT');
});
test('Unknown scanner result cannot make a file accessible', async () => {
  await expectAsyncReject(inspectAndScanEvidence({...valid,scanner:async()=>({verdict:'unknown'})}), 'SCANNER_UNAVAILABLE');
});
test('Even a clean scanner result does not permit storage or reviewer access', async () => {
  const r=await inspectAndScanEvidence({...valid,scanner:async()=>({verdict:'candidate_clean'})});
  assert.equal(r.verdict,'candidate_clean');
  assert.equal(r.storagePermitted,false);
  assert.equal(r.reviewerAccessPermitted,false);
  assert.equal(r.approved,false);
  assert.ok(Object.isFrozen(r));
});
test('Unexpected extensions are rejected before a scanner callback is called', async () => {
  let invoked=0;
  await expectAsyncReject(inspectAndScanEvidence({
    ...valid,filename:'virus.exe',scanner:async()=>{invoked++; return {verdict:'candidate_clean'};},
  }), 'DISALLOWED_EXTENSION');
  assert.equal(invoked,0);
});

/** Small LOCAL test double for the clamd wire protocol. Not a real AV scanner. */
async function withFakeClamd(reply, fn, {noResponse=false}={}) {
  let scanned=Buffer.alloc(0);
  const sockets=new Set();
  const server=createServer(socket=>{
    sockets.add(socket);
    socket.on('close',()=>sockets.delete(socket));
    socket.on('error',()=>{});
    socket.on('data',data=>{
      scanned=Buffer.concat([scanned,data]);
      const header=Buffer.from('zINSTREAM\0');
      if(scanned.length < header.length) return;
      if(!scanned.subarray(0,header.length).equals(header)) {
        socket.destroy(); return;
      }
      let pos=header.length;
      while(pos+4<=scanned.length) {
        const n=scanned.readUInt32BE(pos);
        if(pos+4+n>scanned.length) return;
        pos+=4+n;
        if(n===0) {
          if(!noResponse) socket.end(Buffer.from(reply+'\0'));
          return;
        }
      }
    });
  });
  await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
  try {await fn(server.address().port,()=>scanned);}
  finally {
    for(const socket of sockets) socket.destroy();
    await new Promise(resolve=>server.close(resolve));
  }
}

test('ClamAV INSTREAM framing and clean response',async()=>{
  await withFakeClamd('stream: OK',async(port,getData)=>{
    const result=await scanWithClamd(pdf,{port,timeoutMs:1500});
    assert.equal(result.verdict,'candidate_clean');
    const bytes=getData();
    assert.ok(bytes.subarray(0,10).equals(Buffer.from('zINSTREAM\0')));
    assert.equal(bytes.readUInt32BE(10),pdf.length);
    assert.ok(bytes.subarray(14,14+pdf.length).equals(pdf));
    assert.equal(bytes.readUInt32BE(14+pdf.length),0);
  });
});
test('ClamAV INSTREAM splits larger inputs into 64 KiB frames',async()=>{
  const bigPdf=Buffer.from('%PDF-1.7\n'+ 'x'.repeat(80_000)+'\n%%EOF\n');
  await withFakeClamd('stream: OK',async(port,getData)=>{
    const result=await scanWithClamd(bigPdf,{port,timeoutMs:1500});
    assert.equal(result.verdict,'candidate_clean');
    const packet=getData();
    const header=Buffer.from('zINSTREAM\0');
    assert.ok(packet.subarray(0,header.length).equals(header));
    const start=header.length;
    assert.equal(packet.readUInt32BE(start),65536);
    assert.equal(packet.readUInt32BE(start+4+65536),bigPdf.length-65536);
    assert.equal(packet.readUInt32BE(start+4+65536+4+bigPdf.length-65536),0);
  });
});

test('Malware FOUND response is a hard rejection',async()=>{
  await withFakeClamd('stream: Example.Signature FOUND',async(port)=>{
    await expectAsyncReject(scanWithClamd(pdf,{port}), 'MALWARE_FOUND');
  });
});
test('Unexpected scanner reply fails closed',async()=>{
  await withFakeClamd('INTERNAL ERROR',async(port)=>{
    await expectAsyncReject(scanWithClamd(pdf,{port}), 'SCANNER_UNAVAILABLE');
  });
});
test('Scanner outage (connection refused) fails closed', async()=>{
  // Port 0 is invalid, test with a reserved unbound listener port to avoid a network dependency.
  const tmp=createServer(); await new Promise(resolve=>tmp.listen(0,'127.0.0.1',resolve));
  const port=tmp.address().port; await new Promise(resolve=>tmp.close(resolve));
  await expectAsyncReject(scanWithClamd(pdf,{port,timeoutMs:300}), 'SCANNER_UNAVAILABLE');
});
test('Scanner non-response times out and fails closed', async()=>{
  await withFakeClamd('',async(port)=>{
    await expectAsyncReject(scanWithClamd(pdf,{port,timeoutMs:160}), 'SCANNER_UNAVAILABLE');
  },{noResponse:true});
});
test('Remote scanner host cannot be injected',async()=>{
  await expectAsyncReject(scanWithClamd(pdf,{host:'8.8.8.8'}),'INVALID_SCANNER_CONFIG');
});
test('Scan rejects over-limit buffers before opening a network connection',async()=>{
  await expectAsyncReject(scanWithClamd(Buffer.alloc(MAX_BYTES+1)),'INVALID_SIZE');
});
