import { EvidenceError } from './scan.mjs';

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const BEARER = /^Bearer ([A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+)$/;
const INVALID = 'EVIDENCE_ADMISSION_DENIED';

function deny() {
  throw new EvidenceError(INVALID, 'Authenticated evidence admission was denied');
}
function validId(value) {
  return typeof value === 'string' && UUID.test(value);
}
function localEndpoint(raw) {
  if (typeof raw !== 'string') deny();
  let url;
  try { url = new URL(raw); } catch { deny(); }
  if (url.protocol !== 'http:' ||
      !['127.0.0.1', '[::1]'].includes(url.hostname) ||
      (url.pathname !== '/' && url.pathname !== '') ||
      url.search || url.hash || url.username || url.password) deny();
  return url.origin;
}
async function checkedJson(response) {
  if (!response || response.ok !== true || response.status < 200 || response.status >= 300) deny();
  try { return await response.json(); } catch { deny(); }
}

/**
 * OFFLINE DEVELOPMENT BUILDING BLOCK; NOT an upload or internet listener.
 *
 * Only an EAGLT02 loopback Supabase origin is accepted. Auth identity is
 * obtained through GoTrue's /auth/v1/user verification using the supplied JWT.
 * The account UUID is NOT taken from a request body or decoded token claims.
 * The privileged RPC requires a server-held service-role key (never in Flutter).
 * The optional fetchImpl is for isolated deterministic testing only.
 *
 * An atomic claim is NOT consent, secure file custody or upload authorisation.
 */
export function createLocalEvidenceClaimService({
  supabaseUrl, publishableKey, serviceRoleKey, fetchImpl = fetch,
}) {
  const origin = localEndpoint(supabaseUrl);
  if (![publishableKey, serviceRoleKey].every(
    k => typeof k === 'string' && k.length >= 16
  ) || publishableKey === serviceRoleKey || typeof fetchImpl !== 'function') deny();

  async function request(path, options) {
    try {
      return await fetchImpl(origin + path, {
        ...options,
        cache: 'no-store',
        redirect: 'error',
        signal: AbortSignal.timeout(5000),
      });
    } catch {
      deny(); // No URLs, credentials, tokens or backend response bodies in errors.
    }
  }
  return Object.freeze({
    async claimForAuthenticatedRequest({authorization, intentId, checkId, applicationId}) {
      if (!validId(intentId) || !validId(checkId) || !validId(applicationId) ||
          typeof authorization !== 'string' || authorization.length > 8192) deny();
      const token = BEARER.exec(authorization)?.[1];
      if (!token) deny();

      const authResponse = await request('/auth/v1/user', {
        method: 'GET',
        headers: {apikey: publishableKey, Authorization: 'Bearer ' + token},
      });
      const identity = await checkedJson(authResponse);
      if (!validId(identity?.id) ||
          identity.role !== 'authenticated' ||
          identity.aud !== 'authenticated' || identity.is_anonymous === true ||
          (identity.banned_until != null &&
           (!Number.isFinite(Date.parse(identity.banned_until)) ||
            Date.parse(identity.banned_until) > Date.now()))) deny();

      // Exactly one database RPC per verified call. SQL enforces the account,
      // application, check, plan and ACTIVE state in an atomic UPDATE.
      const claimed = await request('/rest/v1/rpc/claim_staged_evidence_intake', {
        method: 'POST',
        headers: {
          apikey: serviceRoleKey,
          Authorization: 'Bearer ' + serviceRoleKey,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          p_intent_id: intentId,
          p_applicant_id: identity.id,
          p_application_id: applicationId,
          p_check_id: checkId,
        }),
      });
      const claimId = await checkedJson(claimed);
      if (!validId(claimId)) deny();
      return Object.freeze({
        intentId, claimId, subjectId: identity.id, applicationId, checkId,
        state: 'claimed_for_quarantine',
        storagePermitted: false,
        reviewerAccessPermitted: false,
        approved: false,
        uploadedToSupabase: false,
      });
    },
  });
}
