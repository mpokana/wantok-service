/**
 * CX1S: explicitly authorised test-data-only GoTrue + PostgREST witness.
 * Local EAGLT02 development Kong only. Never real administrator sessions.
 * Two new disposable accounts and two fixture bookings only.
 * A pre-existing verified backup is mandatory.
 */
import {spawnSync} from 'node:child_process';
import {randomBytes} from 'node:crypto';
import {mkdirSync,existsSync,readFileSync,writeFileSync,renameSync,statSync} from 'node:fs';
import {resolve,dirname,join} from 'node:path';
import {fileURLToPath} from 'node:url';
import assert from 'node:assert/strict';

const worktree=resolve(dirname(fileURLToPath(import.meta.url)),'../..');
const project='D:/Project-M.2/wantok-service-recovery';
const backup='D:/Wantok_CX1S_Local_Backup_20261015/cx1s-pre-auth-bookings-20261015.dump';
const local=resolve(project,'.wantok/cx1s-real-dev-20261015b');
const manifest=join(local,'owner-manifest.json');
const marker='CX1S_20261015B';
const host='http://127.0.0.1:54321';
const issue=(text)=>{throw Error('CX1S: '+text);};
if(process.argv.slice(2).join(' ')!=='--create-and-test-local-only')
  issue('requires exact --create-and-test-local-only flag');
if(process.platform!=='win32'||!existsSync(backup)||statSync(backup).size<100000)
  issue('verified EAGLT02 pre-test DB backup missing');
if(!existsSync(resolve(project,'supabase/config.toml'))||
   !existsSync(resolve(worktree,'docs/SMOKE_DATA.md')))
  issue('approved local developer project boundary missing');
if(existsSync(manifest))issue('existing fixture manifest: recover/inspect before creating another set');
const envTool=resolve(project,'node_modules/.bin/supabase.cmd');
if(!existsSync(envTool))issue('local Supabase CLI missing');
const status=spawnSync('powershell.exe',
  ['-NoProfile','-NonInteractive','-Command',
   "& '"+envTool.replace(/'/g,"''")+"' status -o env"],{
  cwd:project,encoding:'utf8',timeout:25000,windowsHide:true,maxBuffer:50000
});
if(status.status!==0)issue('local Supabase CLI credentials unavailable');
const entries=Object.fromEntries((status.stdout||'').split(/\r?\n/)
 .filter(x=>/^[A-Z_]+=.*/.test(x)).map(line=>{
   const at=line.indexOf('=');return [line.slice(0,at),line.slice(at+1).replace(/^"|"$/g,'')];
 }));
const anon=entries.ANON_KEY,service=entries.SERVICE_ROLE_KEY;
if(!anon||!service||anon===service)issue('local distinct anon/service credentials missing');
if(entries.API_URL && entries.API_URL.replace(/\/+$/,'')!==host)issue('Supabase CLI target not expected loopback');
mkdirSync(local,{recursive:true});
const fixtureTag=randomBytes(5).toString('hex');
const state={marker,tag:fixtureTag,created_at:new Date().toISOString(),
  accounts:[],bookings:[],status:'BEGIN',cleanup:'PENDING'};
function save(){
  const t=manifest+'.new';
  writeFileSync(t,JSON.stringify(state,null,2)+'\n',{encoding:'utf8',mode:0o600});
  renameSync(t,manifest);
}
save();
const recorded=[];
const note=(name,ok=true)=>{recorded.push({name,pass:ok});};
async function api(path,{method='GET',jwt=anon,apiKey=anon,data,bodyText}={}){
  if(!path.startsWith('/auth/v1/')&&!path.startsWith('/rest/v1/'))
    issue('unexpected API path');
  const controller=new AbortController();
  const timeout=setTimeout(()=>controller.abort(),9000);
  try {
    const res=await fetch(host+path,{method,redirect:'error',signal:controller.signal,
      headers:{apikey:apiKey,authorization:'Bearer '+jwt,
        'content-type':'application/json',accept:'application/json',
        ...(data||bodyText?{'prefer':'return=representation'}:{})},
      body:data?JSON.stringify(data):bodyText
    });
    let parsed;
    try{parsed=await res.json();}catch{parsed=null;}
    return {code:res.status,ok:res.ok,data:parsed};
  }finally{clearTimeout(timeout);}
}
const admin=(path,o={})=>api('/auth/v1/admin/'+path,{...o,jwt:service,apiKey:service});
const rest=(path,o={})=>api('/rest/v1/'+path,o);
const isUuid=x=>/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(x||'');
function expectCode(r,want,name){
  if(r.code!==want)issue(name+' returned HTTP '+r.code+' instead of '+want);
  note(name);
}

const sessions=[];
async function createAccount(letter){
  const email='cx1s-'+letter.toLowerCase()+'-'+fixtureTag+'@example.invalid';
  const password=randomBytes(25).toString('base64url')+'!Cx1S';
  const response=await admin('users',{method:'POST',data:{
    email,password,email_confirm:true,
    user_metadata:{cx1s_fixture:marker,cx1s_tag:fixtureTag,role:'temporary_qa'}
  }});
  if(![200,201].includes(response.code)||!isUuid(response.data?.id))
    issue('could not create disposable GoTrue account '+letter+' (HTTP '+response.code+')');
  const userId=response.data.id;
  state.accounts.push({label:letter,email,id:userId,creation:'created',cleanup:'PENDING'});
  save(); // Ownership manifest before all further actions
  note('create_account_'+letter);
  const login=await api('/auth/v1/token?grant_type=password',{method:'POST',data:{email,password}});
  if(login.code!==200||!login.data?.access_token)
    issue('password login failed '+letter+' (HTTP '+login.code+')');
  const jwt=login.data.access_token;
  const who=await api('/auth/v1/user',{jwt});
  if(who.code!==200||who.data?.id!==userId)
    issue('authenticated actor mismatch '+letter);
  note('real_GoTrue_sign_in_'+letter);
  sessions.push({label:letter,id:userId,jwt});
}

async function createBooking(actor,cat){
  const response=await rest('service_bookings',{method:'POST',jwt:actor.jwt,data:{
    customer_id:actor.id,category_id:cat,
    notes:marker+' synthetic only - '+actor.label,
    metadata:{cx1s_fixture:marker,cx1s_tag:fixtureTag,label:actor.label}
  }});
  if(response.code!==201||!Array.isArray(response.data)||
     response.data.length!==1||!isUuid(response.data[0]?.id)||
     response.data[0].customer_id!==actor.id)
    issue('owner booking INSERT failed '+actor.label+' (HTTP '+response.code+')');
  const bookingId=response.data[0].id;
  state.bookings.push({label:actor.label,id:bookingId,customer_id:actor.id,
    creation:'created',cleanup:'PENDING'});
  save();
  note('RLS_owner_insert_'+actor.label);
}

async function runTests(){
  const cat=await rest('service_categories?select=id&is_active=eq.true&limit=1');
  if(cat.code!==200||!Array.isArray(cat.data)||cat.data.length!==1||
    !isUuid(cat.data[0]?.id))issue('active public category missing');
  const categoryId=cat.data[0].id;
  await createAccount('A');
  await createAccount('B');
  for(const actor of sessions)await createBooking(actor,categoryId);

  const a=sessions[0],b=sessions[1];
  const aBooking=state.bookings.find(x=>x.label==='A').id;
  const bBooking=state.bookings.find(x=>x.label==='B').id;
  const ids=[aBooking,bBooking];
  const target='service_bookings?select=id,customer_id&id=in.('+ids.join(',')+')';
  for(const actor of sessions){
    const res=await rest(target,{jwt:actor.jwt});
    if(res.code!==200||!Array.isArray(res.data)||
       res.data.length!==1||res.data[0].customer_id!==actor.id||
       res.data[0].id!==state.bookings.find(x=>x.label===actor.label)?.id)
       issue('installed RLS did not enforce customer '+actor.label+' ownership (HTTP '+res.code+')');
    note('real_PostgREST_RLS_owner_'+actor.label);
  }
  for(const [actor,foreign] of [[a,bBooking],[b,aBooking]]){
    const query='service_bookings?select=id,customer_id&id=eq.'+foreign;
    const res=await rest(query,{jwt:actor.jwt});
    if(res.code!==200||!Array.isArray(res.data)||res.data.length!==0)
       issue('cross-account booking read succeeded for '+actor.label+' (HTTP '+res.code+')');
    note('real_PostgREST_cross_account_DENY_'+actor.label);
  }
  const expired=await rest(target,{jwt:'definitely.invalid.token'});
  if(expired.code!==401)issue('malformed JWT not refused (HTTP '+expired.code+')');
  note('real_PostgREST_malformed_JWT_DENY');

  const untrusted=await rest(target);
  if(![401,403].includes(untrusted.code))
    issue('anonymous raw bookings path not refused (HTTP '+untrusted.code+')');
  note('real_PostgREST_anonymous_DENY');

  // Current Flutter query, rather than inventing new endpoint behaviour.
  const repository=readFileSync(resolve(worktree,
    'packages/wantok_api/lib/src/reservation_repository.dart'),'utf8');
  const body=repository.match(/loadMyReservations\(\) async \{([\s\S]*?)\n  \}/)?.[1];
  const projection=body?.match(/\.select\(\s*'([^']+)'/s)?.[1];
  if(!projection||!projection.includes('service_reviews('))
     issue('source repository Track select changed');
  let responded=0;
  for(const actor of sessions){
    const query='service_bookings?select='+encodeURIComponent(projection.replace(/\s+/g,''))+
      '&customer_id=eq.'+actor.id+'&order=created_at.desc.nullslast&limit=100';
    const r=await rest(query,{jwt:actor.jwt});
    if(r.code===200&&Array.isArray(r.data)&&
        r.data.some(x=>state.bookings.find(b=>b.customer_id===actor.id)?.id===x.id))
      responded++;
    else recorded.push({name:'existing_Flutter_nested_query_'+actor.label,
      pass:false,http:r.code});
  }
  note('nested_query_matches_customer_'+responded+'_of_2',responded===2);
  if(responded!==2)issue('existing Flutter nested Track query not accepted for both customers');
  state.status='WITNESSED';
  save();
}

async function cleanup(){
  state.status='CLEANING';
  save();
  const problems=[];
  for(const booking of [...state.bookings].reverse()){
    try{
      if(booking.cleanup==='DONE')continue;
      const path='service_bookings?id=eq.'+booking.id+'&customer_id=eq.'+booking.customer_id;
      const r=await rest(path,{method:'DELETE',jwt:service,apiKey:service});
      if(![200,204].includes(r.code))throw Error('HTTP '+r.code);
      const verify=await rest('service_bookings?select=id&id=eq.'+booking.id,
        {jwt:service,apiKey:service});
      if(verify.code!==200||!Array.isArray(verify.data)||verify.data.length!==0)
        throw Error('booking still present');
      booking.cleanup='DONE';
      save();
    }catch{problems.push('booking '+booking.label);}
  }
  for(const account of [...state.accounts].reverse()){
    try{
      if(account.cleanup==='DONE')continue;
      if(!account.email.startsWith('cx1s-')||
        !account.email.endsWith('@example.invalid')||!isUuid(account.id))
        throw Error('account not owned by fixture');
      const r=await admin('users/'+account.id,{method:'DELETE'});
      if(![200,204].includes(r.code))throw Error('HTTP '+r.code);
      // Other user accounts, including protected administrator, never targeted.
      account.cleanup='DONE';
      save();
    }catch{problems.push('account '+account.label);}
  }
  state.cleanup=problems.length?'INCOMPLETE':'DONE';
  state.status=problems.length?'MANUAL_RECOVERY_REQUIRED':'FINISHED';
  save();
  return problems;
}

let failure=null;
try{await runTests();}
catch(e){failure=e;state.status='FAILED_TEST';save();}
let cleanupProblems=[];
try{cleanupProblems=await cleanup();}
catch(e){cleanupProblems=['cleanup failure'];failure??=e;}
const passed=recorded.filter(r=>r.pass).length;
const failed=recorded.filter(r=>!r.pass);
const summary={
  checkpoint:'CX1S',local_only:true,
  pre_test_backup_confirmed:true,
  protected_existing_accounts_modified:false,
  original_booking_modified:false,
  created_users:state.accounts.length,
  created_bookings:state.bookings.length,
  tests_passed:passed,
  tests_failed:failed,
  cleanup:state.cleanup,
  account_cleanup_done:state.accounts.filter(x=>x.cleanup==='DONE').length,
  booking_cleanup_done:state.bookings.filter(x=>x.cleanup==='DONE').length,
  categories_unchanged:true,
  real_GoTrue_signin:recorded.filter(x=>x.name.startsWith('real_GoTrue')&&x.pass).length,
  real_owner_RLS_read:recorded.filter(x=>x.name.startsWith('real_PostgREST_RLS_owner')&&x.pass).length,
  real_cross_user_negative:recorded.filter(x=>x.name.startsWith('real_PostgREST_cross_account_DENY')&&x.pass).length,
  existing_nested_query:recorded.filter(x=>x.name.startsWith('nested_query_matches')).map(x=>x.name),
  next:'No Tailnet private REST route; local development QA only',
  result:failure?'FAILED':'COMPLETED'
};
const report=join(local,'sanitised-results.json');
writeFileSync(report,JSON.stringify(summary,null,2)+'\n');
console.log(JSON.stringify(summary,null,2));
if(cleanupProblems.length)issue('clean-up incomplete; inspect local ignored owner manifest');
if(failure)issue(failure.message);
