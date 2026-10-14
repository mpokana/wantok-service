# CX1S — Real local GoTrue + booking ownership witness (development only)

**Date:** 15 October 2026 | **Machine:** EAGLT02 | **Git baseline:** CX1R `0a9cec6` | **Result:** **13/13 witnessed assertions PASS; temporary test users/bookings cleaned up.** Neither the real administrator nor other pre-existing records were used as test actors.

## Owner authorisation and scope

The owner confirmed this is a new development database containing temporary sample data and explicitly authorised creation of temporary test accounts and bookings in existing **local EAGLT02 Supabase**. Owner separately identified the real administrator account, which must never be reset, impersonated, deleted or mutated. This task used **two entirely new `cx1s-` fixture accounts** with generated passwords that were kept only in process memory. This approval is **not** a production launch, open private Tailnet route, broad database reset, or independent E6/G7/G8 acceptance.

### Pre-test protection

- Captured a PostgreSQL custom-format **full database backup** before any test-user/account write. Local-only file: `D:\Wantok_CX1S_Local_Backup_20261015\cx1s-pre-auth-bookings-20261015.dump`. SHA-256: `463DD649ECC37BCE8EECFB96FCD3F92963ABA487F09D4F9ECF6D56F0A03FEECD` (1,585,407 bytes). `pg_restore -l` confirmed both `auth.users` and `public.service_bookings` exist in its TOC. Directory ACL restricted to local Windows user and SYSTEM. **Restore was not attempted or required.** Never commit this dump to GitHub.
- Read-only baseline counts were **2 pre-existing accounts**, **1 pre-existing booking**, **20 active categories**, **0 existing CX1S test accounts**. Among the 2 accounts there is 1 known real administrator and 1 other existing account; **both are preserved**. Account identities and booking details are intentionally omitted from this GitHub document.
- Existing `docs/SMOKE_DATA.md` UI-only sample fixtures are unrelated and remain unchanged. CX1S real-database test accounts were uniquely labelled, with their ownership manifests and sanitised results retained **only** in ignored local `.wantok` directories for safe cleanup.

## Live test outcomes (real installed Supabase, no production)

The narrowly scoped `scripts/qa/cx1s-real-local-gotrue-booking-witness.mjs` performs localhost-only calls to the **existing development** API at `127.0.0.1:54321`. The Supabase CLI supplies the local `anon` and `service_role` keys **in memory**; the script does not print, publish or persist tokens/passwords. Service-role access is used only to create/delete **owned temporary GoTrue accounts and test bookings**, not to grant privileges or front account-private reads. The two test customers sign in using **real GoTrue password flows** and make all read/insert attempts with their own validated access tokens.

| Scenario | Actual result |
| --- | --- |
| Create two new synthetic accounts | PASS |
| Real GoTrue password login and `/auth/v1/user` identity for each account | 2/2 PASS |
| Authenticated `service_bookings` insert under installed column privileges and RLS | 2/2 PASS |
| Fetch only known A/B booking IDs **without any frontend customer filter**, using each user's JWT | 2/2 owner-only PASS |
| A's request for B's booking ID and B's request for A's booking ID | 2/2 denied (HTTP 200, zero matching rows) |
| Invalid JWT and unauthenticated raw bookings access | PASS (rejected) |
| Exact Flutter `ReservationRepository.loadMyReservations()` **nested select** on owner-filtered bookings | 2/2 PASS |
| Tagged cleanup of owned bookings followed by test-user deletion | PASS |

**Total:** 13/13 recorded live checks PASS, including the aggregate existing nested query witness.

### Important first-run failure and correction

The initial test attempted to write the explicit `status = 'requested'` column. The installed authenticated role has **column-specific INSERT privileges**, not an INSERT grant on `status`. The request correctly failed with HTTP **403**. All **2** first-run temporary accounts were deleted; no booking was inserted. The corrected script **omits `status`** and lets the database apply the schema's existing default. The second uniquely tagged run then completed with 13 passing checks and deleted its 2 test accounts and 2 bookings. This is a fixture request correction, **not** a production permission change.

### Independent read-only postflight

After cleanup, a new PostgreSQL read-only verification returned:

- **1 known real administrator account preserved**
- **1 other pre-existing account preserved**
- **0 CX1S temporary accounts**
- **1 pre-existing booking**
- **0 CX1S temporary bookings**

Thus final account and booking counts match baseline **2 accounts / 1 booking**. The original booking, identities, grants, schemas, source migration history and active categories were not altered. The test's only persistent side effects are possible permitted audit/history events from legitimate temporary record lifecycle; we do not claim to have rolled back any audit triggers automatically. Test manifests and a sanitised summary remain local and out of Git.

## What this proves and does not

**Proven:** GoTrue issues usable test-account sessions; the installed PostgREST/RLS denies cross-customer fixture reads in both directions; the exact existing nested Flutter Track SELECT can retrieve those owner-specific bookings **when executed against local 54321 with the user token**.

**Not proven:** a narrow HTTP gateway that works on HONOR, account-private routes restricted against raw direct Tailnet host port 54321, exhaustive provider/admin/open-request RLS, signed token revocation/expiry, delegated beneficiary joins, or G7/G8 independent witnesses. The **published HTTPS Tailnet Serve routes were not modified**. The HONOR Track error will remain until an appropriately authorised secure gateway pathway is implemented.

## Re-running and cleanup controls

The local script is **one-shot and fail-closed**: requires exact flag `--create-and-test-local-only`, Windows host, existing verified backup and project config. It refuses when its owned fixture manifest already exists. This particular test run has already completed; do **not rerun blindly or delete the manifests to bypass the guard**. All fixture passwords and JWTs were ephemeral and never logged. Sensitive local files are under ignored `.wantok\cx1s-real-dev-20261015*`. The SQL backup is not a Git artefact.

### Source and Flutter regression verification

- Real local GoTrue/PostgREST witness: **13/13 checks PASS**, with final fixture cleanup independently confirmed.
- New CX1S source fail-closed tests **8/8 PASS**; unchanged prior CX1K–CX1R tests (with one deterministic CX1R signature-negative test correction) **150/150 PASS**, totalling **158/158 source/contract tests**.
- Full Flutter script completed with a saved local **PASS** status and log: **7/7 analyses clean**, Client **135/135**, Operations **43/43**, Technical **38/38** (**216/216** widget tests). No Flutter source/build modified.
- The shared-database `npm run db:test` suite was **not** run in CX1S because it can exercise additional migrations/writes beyond this user-authorised fixture test. The real GoTrue/PostgREST witness and read-only postflight replace neither the full security sign-off nor that suite.
- Verified that Tailnet Serve still does not publish account-private REST; no new route was applied. `git diff --check` passes before checkpoint.

The original E6O-01 risk, G7 31/31 unresolved, G1–G10 0/10 and production NOT APPROVED remain unchanged. The testing workflow has not authorised raw `/rest/v1` exposure, a service-role proxy, firewall changes, or live booking-data release to other Tailnet peers.
