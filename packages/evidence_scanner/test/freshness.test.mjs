import test from 'node:test';
import assert from 'node:assert/strict';
import { createServer } from 'node:net';
import { EvidenceError } from '../src/scan.mjs';
import { parseClamdVersion, requireFreshClamd, scanWithFreshClamd } from '../src/freshness.mjs';

const stamp = 'ClamAV 1.5.4/28147/Thu Oct  8 06:24:12 2026';
const updated = Date.UTC(2026,9,8,6,24,12);
const stale = 'ClamAV 1.5.4/28147/Mon Jan  1 00:00:00 2024';
function freshStamp() {
  const date = new Date();
  const weekdays = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];
  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  const hms = [date.getUTCHours(),date.getUTCMinutes(),date.getUTCSeconds()]
    .map(n=>String(n).padStart(2,'0')).join(':');
  return `ClamAV 1.5.4/28147/${weekdays[date.getUTCDay()]} ${months[date.getUTCMonth()]} ${String(date.getUTCDate()).padStart(2,' ')} ${hms} ${date.getUTCFullYear()}`;
}
const pdf = Buffer.from('%PDF-1.7\n1 0 obj\n<<>>\nendobj\n%%EOF\n');
const denied = e => e instanceof EvidenceError && e.code === 'SCANNER_UNAVAILABLE';

async function withFakeClamd(version, work, {stall=false, badScan=false} = {}) {
  const sockets = new Set();
  let scanRequests = 0;
  const server = createServer(socket => {
    sockets.add(socket);
    socket.on('close', () => sockets.delete(socket));
    socket.on('error', () => {});
    let seen = Buffer.alloc(0);
    socket.on('data', chunk => {
      seen = Buffer.concat([seen,chunk]);
      if (seen.subarray(0,9).toString('ascii') === 'zVERSION\0') {
        if (!stall) socket.end(Buffer.from(version + '\0'));
      } else if (seen.subarray(0,10).toString('ascii') === 'zINSTREAM\0') {
        // Wait for the final INSTREAM zero-length frame.
        let pos = 10;
        while (pos + 4 <= seen.length) {
          const n = seen.readUInt32BE(pos);
          if (pos + 4 + n > seen.length) return;
          pos += 4 + n;
          if (n === 0) {
            scanRequests++;
            socket.end(Buffer.from(badScan ? 'stream: ERROR\0' : 'stream: OK\0'));
            return;
          }
        }
      } else {
        socket.destroy();
      }
    });
  });
  await new Promise(resolve => server.listen(0,'127.0.0.1',resolve));
  try {
    await work(server.address().port, () => scanRequests);
  } finally {
    for (const socket of sockets) socket.destroy();
    await new Promise(resolve => server.close(resolve));
  }
}

test('ClamAV version metadata is parsed with a strict UTC signature age', () => {
  const r = parseClamdVersion(stamp, {nowMs:updated + 3600000});
  assert.equal(r.signatureVersion,28147);
  assert.equal(r.updatedAt,'2026-10-08T06:24:12.000Z');
  assert.equal(r.ageMs,3600000);
  assert.equal(r.fresh,true);
  assert.ok(Object.isFrozen(r));
});
test('old signatures are rejected, including the exact freshness boundary', () => {
  assert.equal(parseClamdVersion(stamp,{nowMs:updated+48*3600000}).fresh,true);
  assert.throws(()=>parseClamdVersion(stamp,{nowMs:updated+48*3600000+1}),denied);
});
test('future-dated signatures reject clock drift beyond five minutes', () => {
  assert.equal(parseClamdVersion(stamp,{nowMs:updated-5*60000}).fresh,true);
  assert.throws(()=>parseClamdVersion(stamp,{nowMs:updated-5*60000-1}),denied);
});
test('fabricated, truncated or extra ClamAV reply fields fail closed', () => {
  for (const line of ['clamd ready','ClamAV 1.5.4/28147', 'ClamAV 1.5.4/0/Thu Oct  8 06:24:12 2026',
    stamp+'\nstream: OK', stamp + 'unexpected', 'ClamAV 1.5.4/28147/not-a-date']) {
    assert.throws(()=>parseClamdVersion(line,{nowMs:updated}),denied);
  }
});
test('cannot weaken the configured 72h absolute freshness ceiling', () => {
  assert.throws(()=>parseClamdVersion(stamp,{nowMs:updated,maxAgeMs:365*86400000}),denied);
});
test('loopback-only version probe returns fresh metadata', async () => {
  await withFakeClamd(freshStamp(),async port => {
    const r=await requireFreshClamd({port});
    assert.equal(r.signatureVersion,28147);
  });
});
test('stale signature probe fails before sending document bytes', async () => {
  await withFakeClamd(stale,async (port, scans) => {
    await assert.rejects(scanWithFreshClamd(pdf,{port}),denied);
    assert.equal(scans(),0);
  });
});
test('healthy fresh signature probe permits a separate clean INSTREAM scan',async()=>{
  await withFakeClamd(freshStamp(),async (port, scans)=>{
    const r=await scanWithFreshClamd(pdf,{port});
    assert.equal(r.verdict,'candidate_clean');
    assert.equal(scans(),1);
  });
});
test('scanner protocol error after valid freshness probe never counts as clean',async()=>{
  await withFakeClamd(freshStamp(),async port=>{
    await assert.rejects(scanWithFreshClamd(pdf,{port}),denied);
  },{badScan:true});
});
test('version outage and malformed response fail closed',async()=>{
  await withFakeClamd('INVALID',async port=>{
    await assert.rejects(requireFreshClamd({port}),denied);
  });
  await withFakeClamd(freshStamp(),async port=>{
    await assert.rejects(requireFreshClamd({port,timeoutMs:150}),denied);
  },{stall:true});
});
test('remote hosts and invalid configs never open a scanner connection',async()=>{
  for (const options of [{host:'192.168.1.5'}, {host:'localhost'},{port:0},
    {timeoutMs:1},{maxAgeMs:0},{maxAgeMs:7*86400000}]) {
    await assert.rejects(requireFreshClamd(options),denied);
  }
});
