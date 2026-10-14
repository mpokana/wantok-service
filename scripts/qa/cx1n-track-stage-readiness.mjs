/**
 * CX1N secure Track stage-preparation preflight.
 * SOURCE ONLY: no network, SQL, token, session, user records or config writes.
 * A PASS means the known risks are inventoried and deployment is sealed.
 */
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {fileURLToPath} from 'node:url';
import {resolve, dirname} from 'node:path';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const defaultRead = (name) => readFileSync(resolve(root, name), 'utf8');
export const decisionFile = 'docs/CX1N_TRACK_STAGE_DECISION_REGISTER_20261014.json';
export const sourcePaths = Object.freeze({
  repository: 'packages/wantok_api/lib/src/reservation_repository.dart',
  track: 'apps/wantok_app/lib/src/home/activity_page.dart',
  schema: 'supabase/migrations/20261005002000_marketplace_core.sql',
  reviews: 'supabase/migrations/20261006130000_cx1_client_experience_foundations.sql',
});

function required(value, regex, label) {
  assert.match(value, regex, 'CX1N source drift / missing evidence: ' + label);
}
export function inventory(read = defaultRead) {
  const repo = read(sourcePaths.repository);
  const match = repo.match(/Future<List<Map<String, dynamic>>> loadMyReservations\(\) async \{([\s\S]*?)\n  \}/);
  assert.ok(match, 'CX1N source drift: Track loading method missing');
  const query = match[1];
  required(query, /\.from\('service_bookings'\)/, 'booking table');
  required(query, /\.eq\('customer_id',\s*_userId\)/, 'customer filter present, but NOT sufficient authorization');
  required(query, /\.order\('created_at',\s*ascending:\s*false\)/, 'ordering');
  required(query, /\.limit\(100\)/, 'bounded client read');
  required(query, /service_quotes\(/, 'embedded service quotes');
  required(query, /service_reviews\(/, 'embedded reviews');
  required(query, /provider_profiles\(/, 'embedded provider profile');
  required(query, /provider_resources\(/, 'embedded resource');
  required(query, /beneficiary_phone/, 'PII in existing query needs privacy review');
  required(repo, /auth\.currentUser/, 'GoTrue caller retrieval');
  required(repo, /throw StateError\('Authentication required\.'\)/, 'no-anonymous guard');

  const track = read(sourcePaths.track);
  required(track, /_repository\.loadMyReservations/, 'Track repository binding');
  required(track, /Future<void> _refresh\(\) async/, 'Refresh handler');
  required(track, /_future = next;/, 'Refresh replaces original Future');
  required(track, /Could not load your activity/, 'backend failure, not empty-state');

  const sql = read(sourcePaths.schema);
  required(sql, /ALTER TABLE public\.service_bookings ENABLE ROW LEVEL SECURITY;/, 'source RLS');
  required(sql, /GRANT SELECT ON TABLE public\.service_bookings TO authenticated;/, 'historical source authenticated grant');
  required(sql, /CREATE POLICY service_bookings_read_participants[\s\S]*?USING\s*\(\s*customer_id = auth\.uid\(\)\s*OR provider_id = auth\.uid\(\)\s*OR public\.is_admin\(auth\.uid\(\)\)/, 'source customer/provider/admin row policy');
  required(sql, /CREATE POLICY service_bookings_read_open_for_qualified_providers[\s\S]*?provider_id IS NULL[\s\S]*?status IN \('requested', 'quoted'\)/, 'source provider open-request policy');
  required(sql, /CREATE POLICY service_quotes_read_participants[\s\S]*?provider_id = auth\.uid\(\)[\s\S]*?b\.customer_id = auth\.uid\(\)/, 'embedded quote row policy');
  const reviews = read(sourcePaths.reviews);
  required(reviews, /CREATE POLICY service_reviews_authenticated_read[\s\S]*?reviewer_id = auth\.uid\(\)[\s\S]*?visibility IN \('public', 'registered'\)/, 'review visibility is wider than Track');
  return {
    source_contract: 'CX1N_TRACK_SOURCE_RISKS_IDENTIFIED',
    booking_query: 'account-filtered GET with nested joins; RLS not certified',
    observed_policy_classes: ['customer', 'provider', 'admin', 'qualified provider open requests'],
    projection_privacy_decision: 'NOT APPROVED',
    live_grant_or_role_parity: 'NOT TESTED',
    source_only: true,
  };
}

const gateKeys = Object.freeze([
  'owner_stage_authority', 'isolated_role_equivalent_stage',
  'verified_database_and_asset_backup', 'authentic_gotrue_test_principals',
  'jwt_expiry_and_revocation', 'row_and_column_allowlist_privacy',
  'same_user_and_cross_user_http_negatives', 'embedded_relation_negative_tests',
  'direct_54321_host_port_denial', 'independent_e6_g7_g8_witnesses',
]);

export function validateDecision(data) {
  assert.equal(data?.checkpoint, 'CX1N', 'CX1N decision register identity changed');
  for (const [name, expected] of [
    ['sourceOnly', true], ['stageApproved', false],
    ['privateTrackApiPublished', false], ['productionApproved', false],
    ['broadRestAllowed', false], ['serviceRoleProxyAllowed', false],
    ['sharedDatabaseMutationAllowed', false], ['tailnetAclMutationAllowed', false],
  ]) {
    assert.equal(data[name], expected, 'CX1N hard stop: ' + name);
  }
  assert.deepEqual(Object.keys(data.gates || {}).sort(), [...gateKeys].sort(),
    'CX1N source gate list changed');
  for (const key of gateKeys) {
    assert.equal(data.gates[key].status, 'NOT WITNESSED', 'CX1N human gate not witnessed: ' + key);
    assert.equal(data.gates[key].approved, false, 'CX1N gate unexpectedly approved: ' + key);
  }
  return {disposition: 'SOURCE_PREPARED_STAGE_BLOCKED', open_gates: gateKeys.length,
    private_data_read_tested: false, endpoint_exposed: false, productionApproved: false};
}
export function preflight(read = defaultRead) {
  const details = inventory(read);
  const decision = validateDecision(JSON.parse(read(decisionFile)));
  return {checkpoint: 'CX1N', ...details, ...decision,
    note: 'Static source/preparation evidence only. Never a GoTrue, RLS, HTTP or staging approval.'};
}
if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  assert.deepEqual(process.argv.slice(2), ['--source-only'],
    'CX1N requires --source-only and never performs a live test');
  console.log(JSON.stringify(preflight(), null, 2));
}
