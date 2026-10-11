/**
 * E6H scope regression without applying pending unrelated migrations.
 * Replaces case-scope functions INSIDE A ROLLBACK-ONLY transaction, runs
 * independently scoped pgTAP fixtures, then discards every schema/data change.
 *
 * Strictly targets the fixed EAGLT02 local Supabase Docker DB. It never uses
 * a remote DB URL, service-role key, real user ID, production VM or db reset.
 */
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {spawnSync} from 'node:child_process';
import {join} from 'node:path';

if (!process.argv.includes('--local')) {
  console.error('Run with --local from Wantok Services project only.');
  process.exit(2);
}
const migration = join('supabase','migrations',
  '20261011233000_operations_independent_case_review.sql');
const source=readFileSync(migration,'utf8');
assert.match(source,/CREATE OR REPLACE FUNCTION public\.has_operations_case_scope/i);
assert.match(source,/CREATE OR REPLACE FUNCTION public\.has_operations_clearance_scope/i);
const env={...process.env};
if (process.platform==='win32' && !env.DOCKER_HOST)
  env.DOCKER_HOST='npipe:////./pipe/dockerDesktopLinuxEngine';
const container='supabase_db_wantok-service';
const tests=['051','052','056','057'];
let total=0;
let failed=false;
for (const prefix of tests) {
  const fs=await import('node:fs');
  const name=fs.readdirSync('supabase/tests')
    .find(n=>n.startsWith(prefix+'_')&&n.endsWith('.test.sql'));
  assert.ok(name,'Missing pgTAP fixture '+prefix);
  const test=readFileSync(join('supabase','tests',name),'utf8');
  const plan=Number(test.match(/SELECT plan\((\d+)\);/i)?.[1]);
  assert.ok(plan>0 && plan<200,'Invalid test plan '+name);
  assert.match(test,/^BEGIN;/im);
  assert.match(test,/ROLLBACK;\s*$/i);
  // BEGIN outer transaction before E6H code; inner BEGIN is a PG no-op.
  // Test's final ROLLBACK also discards all E6H DDL and fixture data.
  const input='BEGIN;\n'+source+'\n'+test+'\n';
  const result=spawnSync('docker',
    ['exec','-i',container,'psql','-X','-v','ON_ERROR_STOP=1',
      '-U','postgres','-d','postgres','-P','pager=off','-At'],
    {input,encoding:'utf8',env,timeout:30000,maxBuffer:3_000_000});
  const output=(result.stdout??'').replace(/\r/g,'');
  const passed=(output.match(/^ok \d+\b/gm)??[]).length;
  const notOk=(output.match(/^not ok\b/gm)??[]).length;
  const rolledBack=output.trimEnd().endsWith('ROLLBACK');
  const okay=result.status===0&&passed===plan&&notOk===0&&rolledBack;
  console.log(`E6H ${prefix}: ${passed}/${plan}, rollback=${rolledBack}, ${okay?'PASS':'FAIL'}`);
  if (!okay) {
    failed=true;
    console.error((result.stderr??'').slice(-1200));
    const problems=output.split('\n').filter(s=>/not ok|ERROR|Bail out|Failed/i.test(s));
    console.error(problems.slice(0,8).join('\n'));
  }
  total+=passed;
}
console.log(`E6H rollback-only: ${total} expected 106 across 4 synthetic pgTAP suites.`);
if(failed||total!==106) process.exitCode=1;
