// TRUSTED LOCAL RECONCILIATION LAB ONLY. No uploads or reviewer access.
// No listener, file writes, manifest mutation, key storage or reactivation.
import {EvidenceError} from './scan.mjs';
import {reconcileOfflineCustodySnapshot} from './custody-reconcile.mjs';

const UUID=/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const HASH=/^[0-9a-f]{64}$/;
const KEY_ID=/^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$/;
const LAB_MODE='OFFLINE_SYNTHETIC_FIXTURE_ONLY';
function refuse(){
  throw new EvidenceError('CUSTODY_NOT_READY','Trusted local reconciliation unavailable');
}
function originOf(raw){
  if(typeof raw!=='string')refuse();
  let url;
  try {url=new URL(raw);}catch{refuse();}
  if(url.protocol!=='http:' ||
    !['127.0.0.1','[::1]'].includes(url.hostname) ||
    !['','/'].includes(url.pathname) ||
    url.search || url.hash || url.username || url.password)refuse();
  return url.origin;
}
function checkSnapshot(snapshot,claimId) {
  if(snapshot===null)return null;
  if(!snapshot || typeof snapshot!=='object'||Array.isArray(snapshot) ||
    snapshot.claim_id!==claimId ||
    snapshot.state!=='pending_independent_reconciliation' ||
    snapshot.envelope_version!==2 ||
    !['application/pdf','image/jpeg','image/png'].includes(snapshot.mime) ||
    !KEY_ID.test(snapshot.key_id) ||
    !Number.isSafeInteger(snapshot.plain_bytes) ||
    snapshot.plain_bytes<12 || snapshot.plain_bytes>5242880 ||
    !Number.isSafeInteger(snapshot.sealed_bytes) ||
    snapshot.sealed_bytes<=snapshot.plain_bytes ||
    snapshot.sealed_bytes>snapshot.plain_bytes+8192 ||
    !HASH.test(snapshot.plain_sha256) ||
    !HASH.test(snapshot.sealed_sha256) ||
    ['intent_id','applicant_id','application_id','check_id']
      .some(k=>!UUID.test(snapshot[k])))refuse();
  return snapshot;
}

/**
 * INTERNAL service-role read of CURRENT database claim and manifest.
 * Never supply the service key to Flutter or pass this object across a
 * network boundary. Server-side role permission is separately enforced.
 */
export function createLocalTrustedCustodyReader({
  supabaseUrl,serviceRoleKey,fetchImpl=fetch,
}){
  const origin=originOf(supabaseUrl);
  if(typeof serviceRoleKey!=='string' ||
    serviceRoleKey.length<24 || typeof fetchImpl!=='function')refuse();
  const read=async (claimId)=>{
    if(typeof claimId!=='string'||!UUID.test(claimId))refuse();
    let response;
    try{
      response=await fetchImpl(origin+'/rest/v1/rpc/read_staged_custody_reconciliation',{
        method:'POST',cache:'no-store',redirect:'error',
        signal:AbortSignal.timeout(5000),
        headers:{
          apikey:serviceRoleKey,
          Authorization:'Bearer '+serviceRoleKey,
          'Content-Type':'application/json',
        },
        body:JSON.stringify({p_claim_id:claimId}),
      });
    }catch{refuse();}
    if(!response?.ok || response.status<200 || response.status>=300)refuse();
    let row;
    try{row=await response.json();}catch{refuse();}
    if(!row || Array.isArray(row) || row.claim_id!==claimId ||
      !['claimed_for_quarantine','withdrawn'].includes(row.claim_state) ||
      (row.claim_state==='withdrawn' && !row.withdrawn_at) ||
      (row.claim_state==='claimed_for_quarantine' && row.withdrawn_at!==null)){
      refuse();
    }
    const snapshot=checkSnapshot(row.snapshot,claimId);
    return Object.freeze({
      claimId,state:row.claim_state,withdrawnAt:row.withdrawn_at,
      snapshot: snapshot ? Object.freeze({...snapshot}):null,
      approved:false,reviewerAccessPermitted:false,uploadAllowed:false,
    });
  };
  return Object.freeze({
    read,
    async reconcileSynthetic({mode,root,expected,keyId,key}){
      if(mode!==LAB_MODE || !expected ||
        typeof expected.claimId!=='string'||!UUID.test(expected.claimId))refuse();
      const live=await read(expected.claimId);
      const report=await reconcileOfflineCustodySnapshot({
        mode,root,expected,keyId,key,snapshot:live.snapshot,
        claimState:{state:live.state,withdrawnAt:live.withdrawnAt},
      });
      // A matching DB snapshot NEVER authorises release or activation.
      if(report.approved!==false || report.storagePermitted!==false ||
        report.reviewerAccessPermitted!==false)refuse();
      return report;
    },
  });
}
