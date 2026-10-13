# CX1A — Read-Only Acceptance Readiness and Release-Guard Reliability

**Date:** 13 October 2026 PNG | **Authorised host:** EAGLT02 | **Commit baseline:** `5bb7c7482ba56d08dc817ecc9c45347a8d410858` | **Branch:** `feature/flutter-platform-v1`

**Disposition:** **SOURCE/QA CONTINUATION ONLY; LIVE CX1 ACCEPTANCE STILL OPEN.** E-series G1–G10 remains 0/10 signed; T2.4 remains PAUSED, E7+/payments/provider activation/production blocked.

## Why this checkpoint matters

The integrated programme plan allows non-mutating CX1 acceptance work after E6 safe engineering preparation. Historic documents contain genuine signed-in browser observations from 11 October, but later reports explicitly state that fresh Saved, Inbox and Track **Refresh centre-click acceptance was not completed**. The earlier Saved click unexpectedly navigated towards vendor onboarding without any submission; root cause has not been established. Previous Flutter widget success and served JavaScript hashes do **not** prove actual browser focus, pointer target, cached bundle or GoTrue session acceptance.

This 13 October pass checks source and local release readiness without opening user Chrome profiles, reading browser cookies, mutating accounts, starting/stopping pre-existing services, writing Supabase, deploying Web/Android or changing Technical source.

## New local runtime preflight — BLOCKED, not a Flutter test failure

- At the time of this run, the existing **five local Web app ports 3000/3100/3200/3300/3400 did not return reachable HTTP shells** from EAGLT02. A read-only `verify-cx1-local.ps1 -CheckAndroid` attempt reported all five unavailable; the expected `emulator-5554` was also **not connected**.
- A focused repeat without Android returned **`CX1_RELEASE_QA_FAIL count=17`**, covering 5 missing shells, 4 JS bundles and 8 shared image requests. This is the correct environmental failure: the application was not served for the test, so no live app content parity, cached browser state or authenticated click evidence was generated. **Do not reuse old HTTP 200 or Android 4010 evidence as a new success.**
- Neither disconnected servers nor an absent emulator is proof that production failed or a source defect exists. No service restart, sign-in, process termination, port claim, Chrome interaction or emulator installation was attempted.

## Reliability fix: prevent misleading parity PASS when a request fails

`scripts/qa/verify-cx1-local.ps1` previously used a helper that wrote `Record FAIL` strings to the output pipeline inside a function returning asset objects. In PowerShell, the emitted error string was then treated as a non-null result, which could produce incorrect `PASS JS :port bytes= sha256=` and main/staging parity PASS lines after a failed HTTP request. This **test-harness** defect did **not** change the Flutter Client app.

The guard now emits diagnostic failures separately from asset-object return values, returns `$null` for failed assets, and catches missing ADB/emulator metadata as an explicit recorded failure rather than an uncaught native-command exception. A synthetic test suite `scripts/qa/cx1-release-guard-offline.test.mjs` shadows PowerShell `Invoke-WebRequest` in a dedicated subprocess and never uses the network:

| Synthetic test | Required condition |
| --- | --- |
| Mock all five shells, four Client/Technical bundles and shared images as available | Guard returns `CX1_RELEASE_QA_PASS` with normal hash parity checks |
| Mock every HTTP request unavailable | Guard returns nonzero `CX1_RELEASE_QA_FAIL`; **no asset-parity PASS** |
| Mock only Client `:3000/main.dart.js` unavailable | Guard returns nonzero; **no fabricated JS :3000 or Client 3000/3300 parity PASS** |

The guard remains a **release-integrity preflight only**. It is not an authenticated browser, payment, booking, provider or human acceptance test.

## Acceptance matrix and distinction between historic and new evidence

| CX1 section | Historical evidence already in existing docs | Newly checked on 13 October | Gate |
| --- | --- | --- | --- |
| **CX-01 category-first real provider browse** | 11 Oct historic signed-in Chrome Services → blank search → Specialist Services → Morobe → Lae → existing QA plumbing provider/detail, 5.0(1), no data mutation | No new signed-in browser because Client :3000 unavailable | **Previously witnessed; fresh pass NOT claimed** |
| **CX-02 Saved / Inbox / Track centre-click** | 11 Oct source/widget 320/390/1440px centred Refresh and NavigatorObserver no-push; earlier live click may have targeted Vendor Onboarding; independent cause unknown | Preflight blocked; no current Chrome session/window visual or actual click | **OPEN: signed-in live Chrome and focus witness** |
| **CX-02 Wallet / Agent / Account** | 11 Oct historic Wallet K0.00 planned-only, Wantok Agent model disconnected, Account/Privacy and existing Inbox data | No real session data read | **Historical only; new verification OPEN** |
| **CX-03 category photos/editor** | Six inactive draft categories; selection/Cancel/Save source and widget-tested, but no live reviewed images approved | No storage upload, editorial signoff, Technical action or category activation | **OPEN; requires separate authorised editor/witness** |
| **CX-04 Android/HONOR** | Old offline-demo emulator versionCode 4010 installed in-place on 11 Oct; not a signed-in Android/HONOR test | Emulator `emulator-5554` absent now; no physical HONOR evidence | **OPEN; device-specific witness** |
| **CX-05 final client gate** | Existing partial historic evidence and several passing isolated Flutter suites | No CX1 final human sign-off; E6 security independent gates also remain unresolved | **NOT APPROVED** |

## Next safe CX1A test when app is available

1. Confirm EAGLT02 local Client Web `:3000` and staging `:3300` listener identity and repeat corrected read-only static integrity guard; compare actual hashes and visible cache version without modifying the servers.
2. In a verified, **unambiguously focused** existing authorised Chrome Client window, separately witness centre-tapping **Refresh** for Saved, Inbox and Track on narrow and desktop viewports. Before/after route, displayed item count, and absence of unexpected vendor onboarding must be documented. Do not infer that the old wrong-route defect is fixed from widget code alone.
3. Maintain screenshots, session details, non-public provider IDs and acceptance evidence only under restricted local `.wantok/` paths or an independently approved evidence store. Never commit authentication artefacts or customer records.
4. Verify device releases and six distinct inactive-category photos under licensing, editorial approval and separately authorised upload operations. Avoid category activation or unauthorised Technical administration.
5. Seek explicit **CX1-only** owner acceptance if all applicable live actions are witnessed; do not treat it as E6 G8 security acceptance or permission for T2.4/production.

## Cross-stream regression evidence

Fresh EAGLT02 validation of **new release guard:** **3/3** synthetic mocked-no-network test cases PASS, including full positive parity, all assets missing, and only Client JS missing. A real read-only localhost release probe correctly returned `CX1_RELEASE_QA_FAIL count=17` because no Web shells/JS/images responded; that result is an **environmental BLOCK**, not a product QA PASS. Prior Android emulator `emulator-5554` also absent.

Fresh detached checkout from exact unchanged E6Z Flutter source commit `5bb7c74`, at `D:\Wantok_CX1_Acceptance_QA_20261013`: **7 clean analyses**, Client **132/132**, Operations **43/43**, Technical **38/38** widget tests PASS (exit 0). E6 source+local privilege preflight validators PASS; seven-pending-migration disconnected SQL suite **301/301** assertions in **16** suites PASS, fixtures rolled back, disposable container removed, shared persistent database unchanged. Synthetic signed-JWT HTTP negatives **23/23**, independence/rollback cases **106/106**, E6S privacy source/local checks PASS, evidence scanner **101/101**. The combined persistent `npm run db:test` is **not claimed green** with unapplied migrations. No Flutter application source or deployed Web/Android code changed in CX1A.

## Verification label

The synthetic guard tests and read-only runtime report are **fresh 13 October evidence**; earlier Web/app screenshots, asset hashes, Android version and approved QA provider interaction are **historical 11 October evidence** and should not be reported as newly tested. Pending migrations remain unapplied; combined shared `npm run db:test` must not be described as green merely because disconnected 301/301 integration passed.
