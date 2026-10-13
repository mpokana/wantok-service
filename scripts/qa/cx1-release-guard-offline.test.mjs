/**
 * Synthetic CX1 release guard regression, no network or user credentials.
 * Shadow PowerShell Invoke-WebRequest so each test is deterministic/offline.
 */
import test from 'node:test';
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {resolve} from 'node:path';

const shell=process.platform==='win32'?'powershell.exe':'pwsh';
const script=resolve('scripts/qa/verify-cx1-local.ps1').replaceAll("'","''");
const okResponse=
  "$uri=([string]$Uri); "+
  "if($uri -match '/main\\.dart\\.js$'){return [pscustomobject]@{StatusCode=200;Content='Refresh saved items Refresh Inbox Refresh activity'}}; "+
  "if($uri -match '/assets/'){return [pscustomobject]@{StatusCode=200;Content=[byte[]](1,2,3,4,5)}}; "+
  "return [pscustomobject]@{StatusCode=200;Content='mock html'}";
function run(body,flags=''){
 const command="function global:Invoke-WebRequest {param($Uri,[switch]$UseBasicParsing,$TimeoutSec) "+
  body+" }; & '"+script+"' -TimeoutSeconds 1 "+flags;
 const result=spawnSync(shell,['-NoProfile','-ExecutionPolicy','Bypass','-Command',command],
  {cwd:process.cwd(),encoding:'utf8',timeout:30000,maxBuffer:500000});
 if(result.error)throw result.error;
 return {exit:result.status,output:(result.stdout||'')+'\n'+(result.stderr||'')};
}
test('mock all endpoints reachable: guard still passes',()=>{
 const r=run(okResponse);
 assert.equal(r.exit,0,r.output);
 assert.match(r.output,/CX1_RELEASE_QA_PASS/);
 assert.match(r.output,/PASS Client main\/staging JS parity/);
 assert.match(r.output,/PASS Shared category photo exact-byte parity/);
});
test('mock all endpoints unavailable: fail closed without a single false PASS',()=>{
 const r=run("throw 'synthetic: endpoint deliberately offline'");
 assert.notEqual(r.exit,0,r.output);
 assert.match(r.output,/CX1_RELEASE_QA_FAIL/);
 assert.doesNotMatch(r.output,/^PASS /m);
 assert.doesNotMatch(r.output,/Client main\/staging JS parity/);
});
test('mock missing Client JS: no fake hash or false Client parity PASS',()=>{
 const body="if(([string]$Uri) -match ':3000/main\\.dart\\.js$'){throw 'synthetic missing client bundle'}; "+okResponse;
 const r=run(body);
 assert.notEqual(r.exit,0,r.output);
 assert.match(r.output,/FAIL 3000 \/main\.dart\.js/);
 assert.doesNotMatch(r.output,/PASS JS :3000/);
 assert.doesNotMatch(r.output,/PASS Client main\/staging JS parity/);
});

test('ClientOnly checks both Client ports without requiring Operations or Technical',()=>{
 const refuseOthers=
  "if(([string]$Uri) -match ':3(100|200|400)/'){throw 'unexpected non-Client request'}; "+
  okResponse;
 const r=run(refuseOthers,'-ClientOnly');
 assert.equal(r.exit,0,r.output);
 assert.match(r.output,/CX1_CLIENT_RELEASE_QA_PASS/);
 assert.match(r.output,/PASS Client main\/staging JS parity/);
 assert.match(r.output,/PASS Client main\/staging category photo exact-byte parity/);
 assert.doesNotMatch(r.output,/HTTP shell :3100|HTTP shell :3200|HTTP shell :3400/);
 assert.doesNotMatch(r.output,/CX1_RELEASE_QA_PASS/);
});
test('ClientOnly missing staging Client JS fails with no false parity',()=>{
 const failStaging=
  "if(([string]$Uri) -match ':3300/main\\.dart\\.js$'){throw 'missing staging JS'}; "+
  okResponse;
 const r=run(failStaging,'-ClientOnly');
 assert.equal(r.exit,1,r.output);
 assert.match(r.output,/CX1_CLIENT_RELEASE_QA_FAIL/);
 assert.doesNotMatch(r.output,/PASS Client main\/staging JS parity/);
});
test('ClientOnly category image drift fails even with identical Client JS',()=>{
 const imageDrift=
  "if(([string]$Uri) -match ':3300/.+/category_taxi\\.webp$'){return [pscustomobject]@{StatusCode=200;Content=[byte[]](6,7,8,9)}}; "+
  okResponse;
 const r=run(imageDrift,'-ClientOnly');
 assert.equal(r.exit,1,r.output);
 assert.match(r.output,/Category photo differs across main\/staging apps/);
 assert.match(r.output,/CX1_CLIENT_RELEASE_QA_FAIL/);
});
