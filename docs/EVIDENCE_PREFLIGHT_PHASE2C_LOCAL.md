# Wantok Services — Phase 2C: Local identity-bound evidence preflight

**11 October 2026 · EAGLT02 local development only · NOT an upload service**

## Goal
Connect an authenticated GoTrue session to an applicant's specific
vendor evidence request for a **read-only, fail-closed preflight**. This
does not create a public file upload gateway or certify identity.

## Database
Migration `20261011194000_vendor_evidence_preflight_gate.sql` adds
`vendor_evidence_preflight(request_id)`, a SECURITY DEFINER,
authenticated-only status function. It matches `auth.uid()` to the
applicant who owns the given request, validates that the request exists,
and returns only restricted status metadata. It never returns a storage
URL, access token, document, clearance, full identity number, or
permission to upload. It always returns:
- `upload_allowed=false`
- `reviewer_access_allowed=false`
- `identity_verified=false`
- `reason=secure_gateway_and_approved_notice_required`.

There is no consent recording or upload-intent claiming in this new
function. Anonymous execution is denied, and a foreign applicant's
request produces the same unavailable error as a nonexistent one.

## Server-side development adapter
Source: `packages/evidence_scanner/src/preflight.mjs`.
`createLocalEvidencePreflight()` accepts a strictly loopback-local
Supabase origin, validates an externally supplied Bearer JWT with
GoTrue `GET /auth/v1/user`, then calls the new RPC **under the same
applicant JWT**, not using `service_role`. This makes PostgreSQL RLS
and the RPC account-ownership check independent of a client-submitted
user ID.

The optional `startLocalEvidencePreflightServer()` is an explicit,
loopback-only Node HTTP developer facade, **not started by default**.
It binds to `127.0.0.1`, accepts only a tiny JSON preflight request,
blocks browser Origin/Cookie requests, has no CORS allowances and **does
not implement an upload route**. A legitimate authenticated caller gets
HTTP 423 with `uploadAllowed=false`; forged or unauthorised attempts
fail without credential/identity disclosure. The `/health` route
returns only disabled capability flags. No files, tokens or evidence
are written to disk, no privileged service key is required, and
personal evidence cannot be submitted through this facade.

## Applicant interface
On Wantok Services Web, open **Become a Wantok vendor → shield icon →
My evidence requirements → Check secure upload status**. The Flutter
client calls the restricted RPC under the current signed-in account.
The control displays a clear refusal, not a file selector or an
upload button. The UI also rejects any unexpected positive upload or
identity-verified flags.

## Evidence of testing
- `npm run db:test` includes
  `046_vendor_evidence_preflight_gate.test.sql` for owner-only access,
  anonymous denial and never-allow-upload state.
- `npm run test:evidence` includes
  `packages/evidence_scanner/test/preflight.test.mjs` for forged IDs,
  denied authentication, disallowed backend URLs, RLS denials,
  rejected positive flags, real local HTTP requests, and blocked
  upload routes. Mock GoTrue/REST responses in this suite do **not**
  demonstrate a live database JWT-to-Gateway integration.
- Flutter widget tests exercise narrow and wide layouts and the
  blocked-readiness dialog.
- Everything here remains local. The existing scanner/quarantine
  prototype and Storage bucket are unchanged.

## Explicit blockers for any true document upload
1. Approved, country-specific privacy notice and consent receipt.
2. Dedicated network gateway authentication, audit/abuse monitoring,
   size/rate limits and isolated document decoder/sandbox.
3. Current and independently verified AV signatures, quarantine,
   storage ACLs, object integrity/atomic custody and KMS.
4. Durable crash-safe manifest reconciliation, key rotation/recovery,
   retention, deletion/holds and off-host audit.
5. Independent least-privilege reviewer access and true final
   verification/clearance issuance.
6. Local real-JWT integration against GoTrue and database requests,
   red-team negative tests, restore drills and explicit production
   release approval.

**Do not open a WAN/LAN port or handle real NID, passport, driver's
licence, tax or insurance documents using this module.**
