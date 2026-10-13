import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {auditSource,auditServe,allowedHandlers,host,blockedClientOperations} from './cx1k-tailnet-api-boundary.mjs';

function fixture(){
  return {
    TCP:{'443':{HTTPS:true},'8443':{HTTPS:true}},
    Web:Object.fromEntries(Object.entries(allowedHandlers).map(([hostname,paths])=>[
      hostname,{Handlers:Object.fromEntries(Object.entries(paths).map(([p,proxy])=>[p,{Proxy:proxy}]))}
    ]))
  };
}
const cloned=()=>structuredClone(fixture());
test('exact active local private Serve routes PASS without security approval',()=>{
 const result=auditServe(cloned());
 assert.equal(result.status,'CX1K_SERVE_ROUTE_SCOPE_MATCH');
 assert.equal(result.checked_paths,5);
 assert.equal(result.productionApproved,false);
 assert.equal(result.real_GoTrue_tested,false);
});
test('source private and published reads can be inventoried but never approved',()=>{
 const result=auditSource();
 assert.equal(result.mapped_public_or_auth_operations,3);
 assert.equal(result.gated_private_or_unreviewed_operations,11);
 assert.equal(result.route_or_data_approval,false);
});
const mutations=[
 ['broad REST prefix',c=>{c.Web[host+':443'].Handlers['/rest/v1']={Proxy:'http://127.0.0.1:54321/rest/v1'};}],
 ['privileged audit writer',c=>{c.Web[host+':443'].Handlers['/rest/v1/rpc/write_audit_event']={Proxy:'http://127.0.0.1:54321/rest/v1/rpc/write_audit_event'};}],
 ['private booking records',c=>{c.Web[host+':443'].Handlers['/rest/v1/service_bookings']={Proxy:'http://127.0.0.1:54321/rest/v1/service_bookings'};}],
 ['anonymous write RPC',c=>{c.Web[host+':443'].Handlers['/rest/v1/rpc/send_conversation_message']={Proxy:'http://127.0.0.1:54321/rest/v1/rpc/send_conversation_message'};}],
 ['root shifted to unrestricted Supabase',c=>{c.Web[host+':443'].Handlers['/'].Proxy='http://127.0.0.1:54321';}],
 ['branding backed by unrestricted REST path',c=>{c.Web[host+':443'].Handlers['/rest/v1/rpc/get_published_wantok_branding'].Proxy='http://127.0.0.1:54321/rest/v1';}],
 ['changed category upstream bypassing field allowlist',c=>{c.Web[host+':443'].Handlers['/rest/v1/service_categories'].Proxy='http://127.0.0.1:54321/rest/v1/service_categories';}],
 ['missing category route',c=>{delete c.Web[host+':443'].Handlers['/rest/v1/service_categories'];}],
 ['unexpected host or port',c=>{c.Web[host+':8080']={Handlers:{'/':{Proxy:'http://127.0.0.1:3000'}}};}],
 ['extra handler metadata',c=>{c.Web[host+':443'].Handlers['/auth/v1'].ExtraProperty='unexpected';}],
 ['public internet Funnel',c=>{c.AllowFunnel=true;}],
 ['Funnel enabled for 443',c=>{c.TCP['443'].AllowFunnel=true;}],
 ['HTTPS disabled',c=>{c.TCP['8443'].HTTPS=false;}],
 ['unexpected raw TCP exposure',c=>{c.TCP['54321']={TCPForward:'127.0.0.1:54321'};}],
 ['unknown remote target',c=>{c.Web[host+':443'].Handlers['/'].Proxy='http://10.0.0.1:3000';}]
];
for(const [name,mutate] of mutations){
 test('reject unsafe live route drift: '+name,()=>{
  const obj=cloned();mutate(obj);
  assert.throws(()=>auditServe(obj));
 });
}
test('missing scoped account-private repository marker blocks audit',()=>{
 const problem=blockedClientOperations.find(x=>x.id==='conversation-list');
 const read=(p)=>{
  const str=readFileSync(p,'utf8');
  return p===problem.file?str.replace(problem.marker,'unknown_method_placeholder'):str;
 };
 assert.throws(()=>auditSource(read),/conversation-list/);
});
test('changed active-only category filter blocks source audit',()=>{
 const p='packages/wantok_api/lib/src/catalog_repository.dart';
 const read=(name)=>{
  const str=readFileSync(name,'utf8');
  return name===p?str.replace(".eq('is_active', true)",".eq('is_active', false)"):str;
 };
 assert.throws(()=>auditSource(read),/filter changed/);
});
