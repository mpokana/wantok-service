/**
 * CX1R — TEST ONLY: HTTP transport for CX1Q synthetic actor contract.
 * Never installed in Flutter, Supabase, Tailscale or a production runtime.
 * A test harness may bind ephemeral 127.0.0.1 only; it must close the server.
 */
import {createServer} from 'node:http';
import {simulateTrackRead,route} from './cx1q-offline-track-jwt-contract.mjs';

const jsonHeaders=Object.freeze({'cache-control':'no-store','content-type':'application/json'});
const denial=(status)=>({status,headers:jsonHeaders,body:{error:'Not permitted'}});
const send=(res,result)=>{
  res.writeHead(result.status,{...jsonHeaders,...result.headers,'x-content-type-options':'nosniff'});
  res.end(JSON.stringify(result.body));
};
const has=(headers,name)=>Object.prototype.hasOwnProperty.call(headers,name);
const allowedHeaderSet=new Set(['authorization','accept']);
const requestedHeaders=(raw)=>{
  if(typeof raw!=='string'||raw.length>100) return null;
  const items=raw.split(',').map(x=>x.trim().toLowerCase());
  if(!items.length || items.some(x=>!allowedHeaderSet.has(x))) return null;
  if(new Set(items).size!==items.length) return null;
  return items;
};

export function makeTestOnlyLoopbackServer(config) {
  if(!config || !config.publicKey || !Array.isArray(config.rows) ||
     typeof config.allowedOrigin!=='string') throw Error('Missing synthetic test configuration');
  return createServer((req,res)=>{
    // No request body, no authentication header echo and no request logging.
    req.resume();
    if(req.method!=='GET' && req.method!=='OPTIONS') return send(res,denial(405));
    if(req.headers['transfer-encoding'] || req.headers['content-length'] ||
       (req.rawHeaders.filter((v,i)=>i%2===0&&v.toLowerCase()==='authorization').length>1)){
      return send(res,denial(400));
    }
    let url;
    try {url=new URL(req.url,'http://127.0.0.1');}
    catch {return send(res,denial(404));}
    if(req.method==='OPTIONS') {
      if(url.pathname!==route || url.search || req.headers.origin!==config.allowedOrigin ||
         req.headers['access-control-request-method']!=='GET' ||
         !requestedHeaders(req.headers['access-control-request-headers'])) {
        return send(res,denial(403));
      }
      res.writeHead(204,{
        'cache-control':'no-store',
        'access-control-allow-origin':config.allowedOrigin,
        'access-control-allow-methods':'GET',
        'access-control-allow-headers':'authorization,accept',
        'access-control-max-age':'0',
        'vary':'Origin'
      });
      return res.end();
    }
    const mappedHeaders={};
    for(const name of ['authorization','accept','apikey','x-client-info']){
      if(has(req.headers,name))mappedHeaders[name]=req.headers[name];
    }
    const result=simulateTrackRead({
      method:req.method,
      path:url.pathname,
      query:url.search ? Object.fromEntries(url.searchParams) : undefined,
      origin:req.headers.origin ?? null,
      headers:mappedHeaders
    },config);
    return send(res,result);
  });
}
