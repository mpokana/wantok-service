#!/usr/bin/env node
/**
 * Offline, read-only verification of a Wantok Linux VPS source archive.
 * Performs SHA-256 and archive entry/path checks. It does NOT execute install,
 * restore the database or grant production approval.
 */
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import {readFileSync} from 'node:fs';
import {resolve,basename} from 'node:path';
import {fileURLToPath} from 'node:url';

const required=[
 'deploy/vps/install.sh','deploy/vps/upgrade.sh','deploy/vps/backup.sh',
 'deploy/vps/migrate.sh','deploy/vps/provision-supabase.sh',
 'deploy/vps/docker-compose.yml','deploy/vps/.env.example',
 'supabase/config.toml','apps/wantok_app/pubspec.yaml',
 'apps/wantok_admin/pubspec.yaml','apps/wantok_tech/pubspec.yaml',
 'supabase/migrations/20261011195000_trusted_custody_reconciliation_read.sql',
];
const deny=(reason)=>{throw Error('RELEASE_VERIFICATION_FAILED: '+reason);};
function isUnsafe(path){
 const parts=path.replaceAll('\\','/').replace(/^\.\//,'').replace(/\/$/,'').split('/');
 return parts.some(s=>s==='..'||s===''||s==='.env' ||
   (s.startsWith('.env.') && s!=='.env.example') ||
   /\.(pem|key|p12|pfx|jks)$/i.test(s) ||
   /^(id_rsa|id_ed25519|credentials\.json)$/i.test(s)) ||
   path.startsWith('/') || /^[A-Za-z]:/.test(path);
}
export function verifyRelease(archive){
 const target=resolve(archive);
 if(!target.endsWith('.tar.gz'))deny('expected .tar.gz archive');
 const manifest=JSON.parse(readFileSync(target+'.manifest.json','utf8'));
 const checksum=readFileSync(target+'.sha256','utf8').trim();
 const actual=createHash('sha256').update(readFileSync(target)).digest('hex');
 if(manifest?.schema!=='wantok-vps-source-release-v1' ||
   manifest.archive!==basename(target) ||
   manifest.sha256!==actual ||
   manifest.status!=='source_release_not_production_security_approval' ||
   checksum!==actual+'  '+basename(target))deny('checksum or manifest mismatch');
 const listing=execFileSync('tar',['-tzf',target],{
   encoding:'utf8',maxBuffer:32*1024*1024,
 }).split(/\r?\n/).filter(Boolean).map(s=>s.replace(/^\.\//,''));
 if(!listing.length||listing.some(isUnsafe))deny('unsafe archive entry');
 for(const entry of required){
   if(!listing.includes(entry))deny('missing release dependency: '+entry);
 }
 if(!listing.some(s=>s.startsWith('supabase/migrations/')))
   deny('no database migrations included');
 return Object.freeze({
  verified:true,
  archive:basename(target),
  commit:manifest.git_commit,sha256:actual,
  files:listing.length,migrations:manifest.migration_files,
  productionApproved:false,
 });
}
if(process.argv[1]&&resolve(process.argv[1])===fileURLToPath(import.meta.url)){
 try{
  if(process.argv.length!==3)deny('usage: node scripts/verify-vps-release.mjs <archive.tar.gz>');
  console.log(JSON.stringify(verifyRelease(process.argv[2]),null,2));
 }catch(error){console.error(error.message);process.exitCode=1;}
}
