# CX1 local release parity guard — 11 October 2026

**Purpose:** A repeatable, strictly read-only gate for the existing Wantok Services local Client, Technical and Operations Web endpoints and installed Android emulator. This is a **CX1 release acceptance aid**, not the deferred T2.4 diagnostics/logging/jobs milestone.

## Run

From `D:\Project-M.2\wantok-service-recovery` on EAGLT02:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\qa\verify-cx1-local.ps1 -CheckAndroid
```

The script checks:
- Local Web shells on **3000 Client**, **3100 Technical Control**, **3200 Operations**, **3300 Client staging**, and **3400 Technical staging** return HTTP 200.
- Client main/staging bundle SHA-256 parity (3000 = 3300), Technical main/staging parity (3100 = 3400).
- Main Client compiled JavaScript contains **Refresh saved items**, **Refresh Inbox**, and **Refresh activity**.
- Real shared **Taxi** and **Public Services** image files respond and have identical SHA-256 across Client/Technical main/staging.
- With `-CheckAndroid`, ADB reads the installed `io.wantok.service` version from the existing emulator and requires at least build 4009 by default. It **does not install, clear, reset or launch** the app.

**PASS evidence on 11 October 2026:** all five HTTP shells 200; Client JS SHA-256 `AB18B9EB8F0733482B396E3C122EB0B726AB9CF2823A79458B0F34AB9178C51D` equal at 3000 and 3300; Technical JS SHA-256 `1D0E6DE096EC54D7D189A798B756A23EAE4F4B7CD32C4AAFE4E30DB905AD67A1` equal at 3100 and 3400; three refresh labels present in actual served Client JavaScript; two reference photo assets exactly match all four app endpoints; Android existing build `4009`; final `CX1_RELEASE_QA_PASS`.

**Fail-closed test PASS:** running with an intentionally impossible minimum Android build `999999` produced `CX1_RELEASE_QA_FAIL count=1` with exit code 1, without changing Android or Web state.

## Exact acceptance boundary

The presence of compiled refresh labels and correct HTTP assets **does not prove an individual Chrome tab downloaded or rendered the latest bundle**, nor that the UI buttons can be clicked safely. The actual previous signed-in browser screenshots for Inbox/Track did not visually demonstrate their new refresh buttons. A later attempted Saved refresh click unexpectedly navigated to vendor onboarding, with no form data entered; browser automation was stopped. Root cause **unverified**, no source/Chrome-profile patch made solely on speculation.

No authenticated endpoints, cookies, local storage, support payloads, vendor data, paid flows, PostgreSQL records, role grants, or production systems are touched by this script. Screenshot and customer evidence remain under ignored `.wantok/`, never Git.

## T2.4 definition and boundary

The authoritative `docs/ROADMAP.md` defines **T2.4 — Diagnostics, logs and jobs — AFTER CX1** with five work items: diagnostics adapters, central/module log adapters, background job/queue visibility, approved job actions, and richer technical audit views. It must **not be treated as completed or commenced** by this lightweight, read-only CX1 release-parity checker.

**Remaining CX1:** repeat real-browser refresh UI acceptance with controlled focus/cache, genuine sign-in after logout and signed-in Android only with user approval, physical HONOR checks, and distinct approved Pacific/PNG imagery plus browser editor upload verification for the six inactive categories. **CX1 IN PROGRESS, T2.4 DEFERRED.**
