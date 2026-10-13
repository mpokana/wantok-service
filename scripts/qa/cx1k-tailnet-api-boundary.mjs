/**
 * CX1K: strict source+Tailscale Serve exposure inventory.
 *
 * Read-only. No browser sessions, DB queries, token values, credential
 * inspection, account data, client requests, migrations, or server changes.
 * Matching route configuration does NOT certify handler implementation,
 * PostgREST/GoTrue authorization, browser acceptance or production safety.
 */
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import {resolve} from 'node:path';

export const host = 'eaglt02.tailfb0609.ts.net';
export const allowedHandlers = {
  [host + ':443']: {
    '/':'http://127.0.0.1:3000',
    '/auth/v1':'http://127.0.0.1:54321/auth/v1',
    '/rest/v1/service_categories':'http://127.0.0.1:3304/rest/v1/service_categories',
    '/rest/v1/rpc/get_published_wantok_branding':
      'http://127.0.0.1:3303/rest/v1/rpc/get_published_wantok_branding'
  },
  [host + ':8443']: {'/':'http://127.0.0.1:3302'}
};

// Source-marked account-private or write paths are NOT candidates for new
// network exposure without the separate E6/G7/G8 and product/security gates.
export const blockedClientOperations = [
  {id:'reservation-history',file:'packages/wantok_api/lib/src/reservation_repository.dart',
    marker:"from('service_bookings')",access:'account-private-read'},
  {id:'taxi-history',file:'packages/wantok_api/lib/src/taxi_repository.dart',
    marker:"from('rides')",access:'account-private-read'},
  {id:'commerce-orders',file:'packages/wantok_api/lib/src/commerce_repository.dart',
    marker:"from('commerce_orders')",access:'account-private-read-write'},
  {id:'events-registrations',file:'packages/wantok_api/lib/src/events_repository.dart',
    marker:"from('event_registrations')",access:'account-private-read-write'},
  {id:'conversation-list',file:'packages/wantok_api/lib/src/messaging_repository.dart',
    marker:"'list_my_booking_conversations'",access:'account-private-read'},
  {id:'message-feed',file:'packages/wantok_api/lib/src/messaging_repository.dart',
    marker:"from('conversation_messages')",access:'account-private-realtime'},
  {id:'conversation-mutations',file:'packages/wantok_api/lib/src/messaging_repository.dart',
    marker:"'send_conversation_message'",access:'account-private-write'},
  {id:'saved-items',file:'packages/wantok_api/lib/src/client_experience_repository.dart',
    marker:"'list_my_saved_items'",access:'account-private-read'},
  {id:'account-profile',file:'packages/wantok_api/lib/src/account_repository.dart',
    marker:"'get_my_account_profile_v2'",access:'account-private-read'},
  {id:'provider-search',file:'packages/wantok_api/lib/src/provider_discovery_repository.dart',
    marker:"'search_client_providers_international'",access:'public-candidate-unreviewed-fields'},
  {id:'provider-services',file:'packages/wantok_api/lib/src/provider_discovery_repository.dart',
    marker:"from('provider_services')",access:'public-candidate-unreviewed-fields'}
];

export const safeClientOperations = [
  {id:'authentication',file:'packages/wantok_api/lib/src/wantok_backend.dart',
    marker:'Supabase.initialize',access:'GoTrue-authentication-only'},
  {id:'published-branding',file:'packages/wantok_api/lib/src/branding_repository.dart',
    marker:"'get_published_wantok_branding'",access:'public-read-only'},
  {id:'active-service-categories',file:'packages/wantok_api/lib/src/catalog_repository.dart',
    marker:"from('service_categories')",access:'public-filtered-read-only'}
];

export function auditSource(read=(name)=>readFileSync(name,'utf8')) {
  for(const operation of [...safeClientOperations,...blockedClientOperations]){
    assert.ok(read(operation.file).includes(operation.marker),
      'Source contract changed: '+operation.id+' in '+operation.file);
  }
  const category=read('packages/wantok_api/lib/src/catalog_repository.dart');
  assert.match(category,/\.eq\('is_active',\s*true\)/,
    'Active-only category filter changed');
  const brand=read('packages/wantok_api/lib/src/branding_repository.dart');
  assert.match(brand,/Future<Map<String,\s*dynamic>>\s+getPublished\(\)/,
    'Published-branding read contract changed');
  return {
    source_contract:'EXACT_SOURCE_MARKERS_MATCH',
    mapped_public_or_auth_operations:safeClientOperations.length,
    gated_private_or_unreviewed_operations:blockedClientOperations.length,
    route_or_data_approval:false
  };
}

export function auditServe(config) {
  assert.ok(config && typeof config==='object', 'Missing local Tailscale Serve configuration');
  assert.deepEqual(Object.keys(config?.TCP||{}).sort(),['443','8443'],
    'Unknown Serve TCP port requires security review');
  assert.equal(config?.TCP?.['443']?.HTTPS,true,'HTTPS 443 required');
  assert.equal(config?.TCP?.['8443']?.HTTPS,true,'HTTPS 8443 required');
  const entries=Object.entries(config.Web||{});
  assert.deepEqual(entries.map(([k])=>k).sort(),Object.keys(allowedHandlers).sort(),
    'Unknown Serve hostname/port requires security review');
  for(const [hostname, paths] of Object.entries(allowedHandlers)){
    const route=config.Web[hostname]?.Handlers;
    assert.ok(route&&typeof route==='object','No Serve handlers for '+hostname);
    assert.deepEqual(Object.keys(route).sort(),Object.keys(paths).sort(),
      'Unknown, broad or missing handler on '+hostname);
    for(const [path, expectedProxy] of Object.entries(paths)){
      const h=route[path];
      assert.ok(h && Object.keys(h).length===1 && h.Proxy===expectedProxy,
        'Handler changed or new Serve capabilities exposed: '+hostname+path);
      assert.ok(h.Proxy.startsWith('http://127.0.0.1:'),
        'Unexpected non-loopback proxy');
    }
  }
  assert.ok(!config.AllowFunnel && !config.Funnel,
    'Internet/public Funnel settings require independent approval');
  for(const item of Object.values(config.TCP||{})){
    assert.ok(!item?.AllowFunnel && !item?.Funnel,
      'Public Funnel enabled: reject');
  }
  return {
    status:'CX1K_SERVE_ROUTE_SCOPE_MATCH',
    checked_hostnames:entries.length,
    checked_paths:Object.values(allowedHandlers).reduce((sum,one)=>sum+Object.keys(one).length,0),
    inspected_api_routes:[
      '/auth/v1',
      '/rest/v1/service_categories',
      '/rest/v1/rpc/get_published_wantok_branding'
    ],
    missing_private_user_api_routes:'INTENTIONALLY_NOT_EXPOSED',
    all_to_all_tailnet_policy_changed:false,
    handler_auth_authorization_tested:false,
    real_GoTrue_tested:false,
    database_permissions_changed:false,
    productionApproved:false
  };
}

function main(){
  assert.equal(process.argv[2],'--local','usage: node scripts/qa/cx1k-tailnet-api-boundary.mjs --local');
  const source=auditSource();
  const cmd=spawnSync('tailscale',['serve','status','--json'],{
    encoding:'utf8',timeout:12000,maxBuffer:300000,
    windowsHide:true
  });
  if(cmd.status!==0)throw Error('Could not read local Tailscale Serve status');
  const status=auditServe(JSON.parse(cmd.stdout));
  console.log(JSON.stringify({checkpoint:'CX1K',source,status,
    e6_writers_status:'OPEN',G1_G10_approved:0,G7_executed:0,
    T24_paused:true,cx1_human_acceptance:'PARTIAL',
    note:'Read-only route configuration audit, not independent security sign-off.'},null,2));
}

const invoked=process.argv[1]&&resolve(process.argv[1])===fileURLToPath(import.meta.url);
if(invoked)try{main()}catch(error){
  console.error('CX1K_BLOCKED '+error.message);
  process.exitCode=1;
}
