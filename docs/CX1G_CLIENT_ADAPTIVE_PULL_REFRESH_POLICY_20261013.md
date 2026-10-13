# CX1G — Consistent mobile/tablet pull-to-refresh; desktop Web buttons

**13 October 2026 (PNG)** · Source checkout: detached from CX1F commit `3e92a4a7a98a3d0b524a747ca853feb98bc96c44`. EAGLT02 only. **Local Client UX, not production, not E6 or Technical T2.4 approval.**

## Owner direction

The owner reviewed signed-in Client Inbox at Chrome Responsive **320 × 811** and requested: **remove dedicated Refresh buttons from mobile and tablet layouts, use the familiar pull-down-to-refresh gesture across refreshable screens; keep visible Refresh controls on desktop Web where space permits**. This supersedes the earlier short-lived CX1E/F approach of repositioning mobile Refresh buttons. No new message, booking, payment or account mutation is authorised by a refresh gesture.

### Shared responsive rule

`apps/wantok_app/lib/src/home/client_refresh_policy.dart` defines the policy:

- **Flutter logical viewport width below 1200px** (phones, common tablets, compact browser windows): **no normal refresh button** in the seven reviewed Client/Vendor data surfaces; scroll down from the top to activate each page's existing read-only `RefreshIndicator`.
- **Width 1200px and above** (desktop Web layouts): keep explicit Refresh controls, preserving original desktop placement/functionality. Existing pull-to-refresh remains harmlessly supported.
- The width-based presentation also works in Chrome DevTools Responsive; no user-agent strings or device-brand detection.
- **Exceptions:** On initial-load failures, an explicit **Retry** may remain so users can recover even if an error prevents a normal drag. Transactional buttons (Submit, Acknowledge, Withdraw, Pay, Save, Book, Upload, etc.) are NOT refresh controls.
- Purely static presentation pages (e.g. Explore illustration grid, Public Services directory, inactive Wallet preview) have **no remote data to reload**; do not implement deceptive no-op spinners. Forms/checkout and onboarding editors must preserve unsent input and never replay writes on drag.
- Scope is the **Wantok Client/Vendor Flutter application** only. Separate Operations and Technical consoles are not modified or resumed.

### Explicit controls hidden on phone/tablet

| Source | Desktop action | Mobile/tablet action |
| --- | --- | --- |
| `home/messages_page.dart` | Inbox Refresh on header | Hidden; `RefreshIndicator` reloads threads & support |
| `home/activity_page.dart` | Track Refresh | Hidden; `RefreshIndicator` reloads bookings |
| `home/client_account_tools.dart` | Saved AppBar Refresh | Hidden; `RefreshIndicator` reloads bookmarks |
| `home/services_hub_page.dart` | Services catalogue Refresh, incl. empty-state action | Hidden; `RefreshIndicator` reloads catalogue |
| `services/commerce_browse_page.dart` | Food/Shop Refresh | Hidden; `RefreshIndicator` reloads approved vendors |
| `home/wantok_agent_page.dart` | Agent status Refresh | Hidden; newly wired `RefreshIndicator` for capabilities, not chat submissions |
| `vendor/vendor_evidence_inbox_page.dart` | Evidence requirements Refresh | Hidden; newly wired `RefreshIndicator` for owner-private **metadata reads** only |

Other scrollable, data-backed screens already have a `RefreshIndicator`: Home catalogue, Account, Provider discovery, Trusted people, Reviews, commerce orders, events and registrations, reservation browse, water transport and trip bookings; the Vendor listings, jobs, provider applications, commerce, events, water transport. No separate mobile Refresh action was introduced on these pages.

**Short-list and empty-state reliability:** Added `AlwaysScrollableScrollPhysics` to **34 existing vertical ListView/list-separated constructions across 16 Client/Vendor source files**, allowing a pull gesture even when content is shorter than the viewport. Existing semantic loaders, list selection and transaction boundaries remain intact.

### Tests / limits

Updated the four CX1 Saved/Inbox/Track widget suites to test actual `tester.drag` refresh and absence of the dedicated button on **320 / 390 / 800 / 1024 logical px**, while asserting desktop buttons and reload on **1240/1440px**. Preserved route-push safety against unexplained prior Saved→Vendor Onboarding navigation. New `test/adaptive_pull_refresh_policy_test.dart` validates breakpoint at 320, 390, 800, 1024, 1199, 1200 and 1440 and read-only vendor evidence refresh using an **injected mock metadata loader**. The test suite caught and fixed a Future-valued `setState` callback in the Vendor evidence loader; passing afterwards is real regression evidence.

**Focused acceptance QA:** **52/52 widget cases PASS**, zero failures. **Full Flutter QA:** seven clean analyses and all three Client, Operations, Technical widget suites PASS; the latter two are unchanged-source regression checks only. No SQL migrations, production release, worker, data/ACL changes or live security gate acceptance.

### Browser witness and remaining tests

Historical owner screenshots passed Saved/Desktop, Inbox/Desktop, Track/Desktop, and Track/Mobile under **previous** button-based interaction (**4 of six visual observations**). The owner's 320px Inbox screenshot after CX1F demonstrated good separated button placement, **not** a successful Inbox Mobile pull gesture. Because CX1G changes the mobile interaction, **new pull-to-refresh live witnesses are required for Track, Inbox and Saved mobile** before declaring the revised mobile UX accepted. Signed-in screenshots or witnessed browser interaction at `http://127.0.0.1:3000/` must show pull spinner/completion and stable counts/routes. Do not assert them from widget tests, static HTTP, or source only.

### Integration and release

Main feature checkout still contains **other session's** staged+unstaged `docs/BUSINESS_PLAN_V1_20261013.md` and `docs/COMMISSION_POLICY_V1_20261013.md`, plus untracked `supabase/snippets/`. Preserve them; **no stash/reset/cherry-pick** over these shared edits. Use detached CX1G worktree, publish an **independent CX1G feature branch**, then merge only after coordinating shared writers. Local compiled Web :3000 replacement is separately verified against the existing 96-file CX1F release and Supabase `127.0.0.1:54321`, with a full verified rollback. Port 3300 remains unchanged. **productionApproved:false**. E6 G1–G10 0/10, G7 31/31 unexecuted; T2.4 PAUSED.

## Verified local delivery on EAGLT02

**13 October local :3000 PASS:** Created a 96-file Flutter Web release with the existing ignored publishable Supabase loopback build configuration. Compiled and served `main.dart.js` SHA-256 `40071C243E2F3E88A55F4A7611AA4C95EFC6AE95FE067C9455D932F1D13A6558`; HTML HTTP 200, shared local Supabase Auth health HTTP 200, running loopback Python static Client PID **36028** at verification. Backed up **96/96 files** from prior, working CX1F bundle SHA `E1537C931423DFF62AC6AF7EEAD078CE44586C99FA33D049FC69945F5F461A82` at `D:\Wantok_Project_Backups\wantok-client-3000-pre-cx1g-20261013`; rollback directory also retained. Port 3300 unchanged. Does not prove user has hard-reloaded Chrome or signed-in pull gesture; local CX1 mobile tests remain OPEN. No production rollout.
