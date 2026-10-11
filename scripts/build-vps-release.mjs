#!/usr/bin/env node
/**
 * Build an installable, source-based Wantok VPS release archive from exactly
 * one committed Git revision. No local .env, databases, node_modules, images
 * generated outside Git, device settings, or uncommitted files are copied.
 *
 * This is a packaging/checksum operation, NOT deployment or production
 * approval. Building the Flutter Docker images and Supabase still requires
 * authorised network/runtime access on the destination VPS.
 */
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import {mkdirSync,readFileSync,writeFileSync,rmSync,readdirSync} from 'node:fs';
import {resolve,dirname,join,basename} from 'node:path';
import {fileURLToPath} from 'node:url';
const root=resolve(dirname(fileURLToPath(import.meta.url)),'..');
const git=(args)=>execFileSync('git',args,{
 cwd:root,encoding:'utf8',stdio:['ignore','pipe','pipe'],maxBuffer:16*1024*1024,
}).trim();
const includes=[
 'apps','packages','deploy/vps','supabase/migrations',
 'supabase/config.toml','VERSION','README.md','package.json','package-lock.json',
];
const required=[
 'deploy/vps/install.sh','deploy/vps/upgrade.sh',
 'deploy/vps/backup.sh','deploy/vps/migrate.sh',
 'deploy/vps/provision-supabase.sh',
 'deploy/vps/docker-compose.yml','deploy/vps/.env.example',
 'supabase/config.toml','apps/wantok_app/pubspec.yaml',
 'apps/wantok_admin/pubspec.yaml','apps/wantok_tech/pubspec.yaml',
 'supabase/migrations/20261011195000_trusted_custody_reconciliation_read.sql',
];
function abort(message){throw new Error('RELEASE_BLOCKED: '+message);}
function outputDir(){
 const pos=process.argv.indexOf('--output');
 if(pos>=0 && (!process.argv[pos+1]||process.argv[pos+2])){
  abort('Specify --output followed by exactly one directory');
 }
 if(pos<0 && process.argv.length>2)abort('Usage: node scripts/build-vps-release.mjs [--output directory]');
 return resolve(pos>=0 ? process.argv[pos+1] : join(root,'.wantok','releases'));
}
export function validateArchivePaths(paths){
 for(const name of paths){
  const normalized=name.replaceAll('\\','/');
  if(normalized.startsWith('/') || normalized.includes('../') ||
    normalized==='..'||/^[A-Za-z]:/.test(normalized))abort('unsafe archive path');
  const segments=normalized.split('/');
  if(segments.some(s=>s==='.env' || (s.startsWith('.env.') && s!=='.env.example') ||
    /\.(pem|p12|pfx|key|jks)$/i.test(s) ||
    /^(?:id_rsa|id_ed25519|credentials\.json)$/i.test(s)))
    abort('secret-like file path in packaging inputs');
 }
}
function main(){
 const sha=git(['rev-parse','HEAD']),short=sha.slice(0,12);
 if(!/^[a-f0-9]{40}$/.test(sha))abort('unverified Git revision');
 const changes=git(['status','--porcelain','--untracked-files=no']);
 if(changes)abort('tracked changes are not committed; commit/test first');
 const tracked=git(['ls-files','-z','--',...includes]).split('\0').filter(Boolean);
 validateArchivePaths(tracked);
 for(const name of required){
  if(!tracked.includes(name))abort('missing required release input '+name);
 }
 // Exclude known local-only files and untracked content. Explicit pathspecs
 // ensure .env and runtime directories never enter this archive.
 const dest=outputDir();
 mkdirSync(dest,{recursive:true});
 const artifact=join(dest,'wantok-vps-'+short+'.tar.gz');
 const manifestPath=artifact+'.manifest.json';
 const checksumPath=artifact+'.sha256';
 if(readdirSync(dest).some(n=>n===basename(artifact)))abort('release file already exists');
 try{
  execFileSync('git',[
   'archive','--format=tar.gz','--output='+artifact,sha,...includes,
  ],{cwd:root,stdio:['ignore','pipe','pipe'],maxBuffer:16*1024*1024});
  const bytes=readFileSync(artifact);
  const sum=createHash('sha256').update(bytes).digest('hex');
  const manifest={
   schema:'wantok-vps-source-release-v1',
   git_commit:sha,
   created_utc:new Date().toISOString(),
   archive:basename(artifact),
   sha256:sum,archive_bytes:bytes.length,
   service_names:['wantok-web','wantok-admin','wantok-tech','caddy'],
   includes:includes,
   migration_files:tracked.filter(s=>s.startsWith('supabase/migrations/')&&s.endsWith('.sql')).length,
   status:'source_release_not_production_security_approval',
   warnings:[
    'No secrets, runtime data, or database contents are included',
    'Production identity-document uploads and final KYC remain disabled',
    'Flutter and Supabase installation requires destination runtime and network',
   ],
  };
  writeFileSync(manifestPath,JSON.stringify(manifest,null,2)+'\n',{flag:'wx',mode:0o600});
  writeFileSync(checksumPath,sum+'  '+basename(artifact)+'\n',{flag:'wx',mode:0o600});
  console.log(JSON.stringify({
   archive:artifact,manifest:manifestPath,sha256_file:checksumPath,
   git_commit:sha,files:tracked.length,migrations:manifest.migration_files,
   bytes:bytes.length,sha256:sum,
  },null,2));
 }catch(error){
  rmSync(artifact,{force:true});
  rmSync(manifestPath,{force:true});
  rmSync(checksumPath,{force:true});
  throw error;
 }
}
if(process.argv[1] && resolve(process.argv[1])===fileURLToPath(import.meta.url)){
 try {main();}catch(error){console.error(error.message);process.exitCode=1;}
}
