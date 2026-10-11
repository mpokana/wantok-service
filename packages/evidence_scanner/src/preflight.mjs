import {createServer} from 'node:http';
import {EvidenceError} from './scan.mjs';

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const BEARER = /^Bearer ([A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+)$/;
const DENIED = 'EVIDENCE_PREFLIGHT_DENIED';

function deny() {
  throw new EvidenceError(DENIED, 'Evidence request is unavailable');
}
function originOf(value) {
  if (typeof value !== 'string') deny();
  let url;
  try { url = new URL(value); } catch { deny(); }
  if (url.protocol !== 'http:' || !['127.0.0.1','[::1]'].includes(url.hostname) ||
      !['','/'].includes(url.pathname) || url.search || url.hash ||
      url.username || url.password) deny();
  return url.origin;
}
async function trustedJson(response) {
  if (!response || !response.ok || response.status < 200 || response.status >= 300) deny();
  try { return await response.json(); } catch { deny(); }
}

/**
 * PRIVATE DEVELOPMENT-ONLY preview. Verifies a real GoTrue session and then
 * queries PostgREST AS THAT USER (never service_role). SQL binds the request
 * to auth.uid(), expiry and draft notice status.
 *
 * This method can NEVER mint an upload URL, accept a file, verify identity,
 * record legal consent, claim an intake intent or grant a clearance.
 */
export function createLocalEvidencePreflight({supabaseUrl,publishableKey,fetchImpl=fetch}) {
  const origin = originOf(supabaseUrl);
  if(typeof publishableKey !== 'string' || publishableKey.length < 16 ||
     typeof fetchImpl !== 'function') deny();

  const request=async(path,options)=>{
    try {
      return await fetchImpl(origin+path,{
        ...options,redirect:'error',cache:'no-store',signal:AbortSignal.timeout(5000),
      });
    } catch { deny(); }
  };

  return Object.freeze({
    async check({authorization,requestId}) {
      if(typeof requestId !== 'string' || !UUID.test(requestId) ||
         typeof authorization !== 'string' || authorization.length > 8192) deny();
      const token=BEARER.exec(authorization)?.[1];
      if(!token) deny();
      const auth=await trustedJson(await request('/auth/v1/user',{
        method:'GET',
        headers:{apikey:publishableKey,Authorization:'Bearer '+token},
      }));
      if(typeof auth?.id!=='string' || !UUID.test(auth.id) ||
         auth.role!=='authenticated' || auth.aud!=='authenticated' ||
         auth.is_anonymous===true ||
         (auth.banned_until!=null && (!Number.isFinite(Date.parse(auth.banned_until)) ||
           Date.parse(auth.banned_until)>Date.now()))) deny();

      const details=await trustedJson(await request('/rest/v1/rpc/vendor_evidence_preflight',{
        method:'POST',
        headers:{
          apikey:publishableKey,
          Authorization:'Bearer '+token,
          'Content-Type':'application/json',
        },
        body:JSON.stringify({p_request_id:requestId}),
      }));
      if(details?.request_id!==requestId ||
        details.upload_allowed!==false ||
        details.reviewer_access_allowed!==false ||
        details.identity_verified!==false ||
        details.notice_version!=='WANTOK-EVIDENCE-NOTICE-DRAFT-2026-10' ||
        !['requested','acknowledged','withdrawn','cancelled'].includes(details.status) ||
        typeof details.expired!=='boolean' ||
        details.reason!=='secure_gateway_and_approved_notice_required') deny();
      return Object.freeze({
        state:'blocked_pending_secure_gateway',
        uploadAllowed:false,reviewerAccessAllowed:false,
        identityVerified:false,privacyConsentRecorded:false,
        requestStatus:details.status,expired:details.expired,
      });
    },
  });
}

const reply=(res,status,body)=>{
  res.writeHead(status,{
    'Content-Type':'application/json; charset=utf-8',
    'Cache-Control':'no-store, no-cache, max-age=0',
    'Pragma':'no-cache',
    'X-Content-Type-Options':'nosniff',
    'Referrer-Policy':'no-referrer',
    'Content-Security-Policy':"default-src 'none'; frame-ancestors 'none'",
  });
  res.end(JSON.stringify(body));
};

/**
 * Optional local-only developer HTTP facade (not started by default).
 * Upload methods/routes are deliberately absent and no request bytes are
 * persisted. Browser Origins and Cookies are rejected (no CORS exposure).
 */
export async function startLocalEvidencePreflightServer({
  supabaseUrl,publishableKey,fetchImpl=fetch,port=4318,
}) {
  if(!Number.isInteger(port) || port<0 || port>65535) deny();
  const service=createLocalEvidencePreflight({supabaseUrl,publishableKey,fetchImpl});
  const server=createServer(async(req,res)=>{
    if(req.socket.remoteAddress!=='127.0.0.1' &&
       req.socket.remoteAddress!=='::1') {
      reply(res,403,{status:'denied'});return;
    }
    if(req.headers.origin || req.headers.cookie || req.headers['transfer-encoding']) {
      reply(res,403,{status:'denied'});return;
    }
    if(req.method==='GET' && req.url==='/health') {
      reply(res,200,{state:'local_development_only',uploadsEnabled:false,
        reviewerAccessEnabled:false,identityApprovalEnabled:false});
      return;
    }
    if(req.method!=='POST' || req.url!=='/v1/preflight' ||
       req.headers['content-type']!=='application/json' ||
       req.headers['content-length']===undefined ||
       !/^\d+$/.test(String(req.headers['content-length'])) ||
       Number(req.headers['content-length'])>256 ||
       Number(req.headers['content-length'])===0) {
      reply(res,404,{state:'unavailable'});return;
    }
    // Node's maxHeadersCount does not alone prevent duplicate auth headers.
    const authCount=req.rawHeaders.filter((h)=>h.toLowerCase()==='authorization').length;
    if(authCount!==1){reply(res,403,{state:'denied'});return;}
    let bytes=0;
    const chunks=[];
    try {
      for await(const chunk of req) {
        bytes+=chunk.length;
        if(bytes>256) { reply(res,413,{state:'denied'});return; }
        chunks.push(chunk);
      }
      if(bytes!==Number(req.headers['content-length'])) deny();
      const body=JSON.parse(Buffer.concat(chunks).toString('utf8'));
      if(!body || typeof body!=='object' || Array.isArray(body) ||
         Object.keys(body).length!==1 ||
         !Object.hasOwn(body,'requestId')) deny();
      const result=await service.check({
        authorization:req.headers.authorization,requestId:body.requestId,
      });
      // Even an authenticated, pending request cannot initiate an upload.
      reply(res,423,result);
    } catch {
      if(!res.headersSent) reply(res,403,{state:'denied'});
    }
  });
  server.requestTimeout=6000;
  server.headersTimeout=5000;
  server.maxHeadersCount=24;
  await new Promise((resolve,reject)=>{
    server.once('error',reject);
    server.listen(port,'127.0.0.1',resolve);
  });
  return Object.freeze({
    port:server.address().port,
    address:'127.0.0.1',
    close:()=>new Promise((resolve,reject)=>server.close(e=>e?reject(e):resolve())),
  });
}
