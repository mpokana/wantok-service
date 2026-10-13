# CX1B — Restored Loopback Client Web and Live-Acceptance Boundary

**13 October 2026 (Papua New Guinea)** · **Authorised workstation:** EAGLT02 · **Prior Git checkpoint:** `91bd63074cb5ea43fc69944836d8d026a4a50306` · **Branch:** `feature/flutter-platform-v1`

**Disposition:** Local Client static/Web **readiness PASS**. Signed-in Chrome interaction and CX1 human acceptance are still **OPEN**. No migration, database write, live user operation, Chrome-profile inspection, Technical/Operations server restart, Android installation, production deployment or E7/T2.4 change occurred.

## Restored only the Client test pages

CX1A had correctly reported localhost ports 3000, 3100, 3200, 3300 and 3400 offline. CX1B verified that two *unchanged* Client static Web artefacts were present and matched the documented 11 October labelled-Refresh release. It started two read-only Python static HTTP server processes bound **only to 127.0.0.1**. It did not rebuild, overwrite, modify or serve the existing Operations/Technical code.

| Client service | Served local static directory | Read-only verification |
| --- | --- | --- |
| `http://127.0.0.1:3000` | `D:\Project-M.2\wantok-service-recovery\apps\wantok_app\build\web` | HTTP root 200, `main.dart.js` available, expected hash |
| `http://127.0.0.1:3300` | `D:\Wantok_Project_Backups\wantok-client-web-labeled-refresh-candidate-20261011` | HTTP root 200, independent on-disk copy, matching hash |

Both copies of `main.dart.js` have **SHA-256** `2207D8BBCCC5BE261B7C7A77498F4E801829E0D7B13378F56B61A06F3E3B2E66` and length **4,099,079 bytes**. This matches the previously documented labelled-Refresh artefact; it is **not** a new build or independently signed current source-to-binary attestation. The compiled main bundle contains `Refresh saved items`, `Refresh Inbox` and `Refresh activity`. Taxi and Public Services images have identical bytes across the two Client origins (not a claim that all six inactive category images are complete).

At the time of capture, the two isolated HTTP servers were Python processes **PID 35016** (:3000) and **PID 54280** (:3300); PIDs can change. Starting the servers was additive, not a Web deployment or operating-system startup configuration. They remain local-only for ongoing acceptance. Original Operations :3200, Technical :3100 and Technical staging :3400 were **not started or verified**. Do not treat these Client endpoints as externally published sites.

The local Supabase authentication HTTP health endpoint `http://127.0.0.1:54321/auth/v1/health` returned **HTTP 200** without any user/session credentials or database row read. This proves only that the anonymous health route responded, not that a specific user can log in or access private data.

### Read-only verification command

`powershell -NoProfile -ExecutionPolicy Bypass -File scripts/qa/verify-cx1-local.ps1 -ClientOnly`

**Result:** `CX1_CLIENT_RELEASE_QA_PASS` (exit 0). The guard checks Client-only HTTP shells and JavaScript at **3000/3300**, identical JS hashes, all three compiled Refresh captions, and both Client image hashes. Its distinct result label deliberately does **not** report full five-port application parity, browser rendering, route navigation, login or end-to-end acceptance.

To restore the same known local static servers if they stop, the EAGLT02-private `.wantok/cx1b-start-client-static.ps1` contains the previously executed start commands. Check current listener identity, separate static directories and expected binary hashes before any restart; do not overwrite a port held by an unrelated process. **This private operational file is not committed to GitHub.**

## Release guard enhancement and synthetic safety tests

Changed only `scripts/qa/verify-cx1-local.ps1` to add `-ClientOnly` while preserving the previous full five-port `-CheckAndroid` behaviour. In Client-only mode, no Technical or Operations endpoint is requested, and missing Client resources must yield `CX1_CLIENT_RELEASE_QA_FAIL`. The existing fake-PASS fix from CX1A remains enforced.

`node --test scripts/qa/cx1-release-guard-offline.test.mjs`: **6/6 synthetic/no-network tests PASS** — full mode success; all offline failure; missing main Client JS failure; Client-only success while non-Client ports reject requests; missing staging Client JS failure; staging photo byte-drift failure. The tests use a shadowed PowerShell `Invoke-WebRequest` in their own subprocess; they do not contact Chrome/Supabase or create client data.

## CX1 gate matrix — keep historical and new acceptance separate

| Experience | Previous evidence | Fresh CX1B evidence | Status |
| --- | --- | --- | --- |
| Client Web entry point | 11 October signed-in Client browse/provider-detail already witnessed | 3000 and 3300 restored static shells; same approved 11 Oct labelled JS and image bytes | **Static readiness PASS; fresh login/navigation NOT witnessed** |
| Saved Refresh | Widgets and source route-safety tests; earlier click unexpectedly went toward Vendor Onboarding, cause unknown | Compiled `Refresh saved items` on both static copies | **Real signed-in centre-click OPEN** |
| Inbox Refresh / Help | Historical user-scoped Inbox; read-only widget refresh tests | Compiled `Refresh Inbox` | **Real signed-in centre-click OPEN** |
| Track/Completed Refresh | Historical complete booking and widget navigation-safety tests | Compiled `Refresh activity` | **Real signed-in centre-click OPEN** |
| Account, Wallet, Wantok Agent | Historical Wallet `K0.00` planned-only and model disconnected | No personal/booking/payment data read | **Fresh on-screen verification OPEN** |
| Six inactive category photos / Technical editor | Source/widget staging passes, editorial/photo approval incomplete | Shared Taxi/Public Services static images match across two Client origins | **Six photo licences/approval and authorised editor testing OPEN** |
| Android/HONOR | Historical offline emulator 4010, physical HONOR not attested | No emulator start/install or handset inspection | **Separate signed-in device acceptance OPEN** |

### Next operator-assisted browser witness (not executed)

Use a **verified existing authorised user session** in an unambiguously focused Client Chrome window. Do not inspect stored credentials, cookies, remote debugging tokens or existing Chrome profiles. At narrow and desktop widths:

1. Confirm page origin, rendered build label and existing account context without changing roles.
2. Navigate via Account/Profile to Saved; note item count and route; click the **visible centre** of its labelled Refresh control once; check same route, count/state and **no Vendor Onboarding**.
3. Repeat for Inbox/Help and Track/Completed, recording before/after route, counts and any real error state. Do not open provider onboarding, change Saved records, submit service/support changes or transact.
4. If focus jumps, route changes unexpectedly or auth is missing, stop and record **BLOCKED/DEFECT REQUIRES REPRODUCTION**. Do not guess at cache, overlay, JS or coordinate causes; document the real observed browser conditions.
5. Preserve sensitive screenshots and identity evidence only in restricted ignored local evidence. Require separate human CX1 sign-off after the actual browser/device tests.

**This connected Desktop Commander surface provides a terminal and file operations, not witnessed graphical browser clicks.** No real signed-in click or Chrome screenshots were captured in CX1B.

## Programme constraints and regression

E6 safe engineering remains **not accepted**, G7 real cases **31/31 NOT EXECUTED**, G1–G10 **0/10 formal sign-offs**, E6S privacy D1–D5 unsupplied, E6O-01 existing privileged writers unresolved. T2.4 remains PAUSED; E7+, payments, provider activation and production blocked. Shared persistent Supabase unchanged. Source-only and isolated SQL/Flutter regression results are recorded independently; do not turn them into live browser approval.
