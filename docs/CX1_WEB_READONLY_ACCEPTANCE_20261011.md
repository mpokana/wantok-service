# CX1 — Authenticated Web read-only acceptance
Date: 11 October 2026, PNG
Environment: EAGLT02, Client Web 127.0.0.1:3000, existing signed-in session

## Verified screen outcomes (actual Chrome, not mock tests)
1. Track: live screen loaded the existing completed Specialist Services record, located Lae / Morobe, with existing provider and review controls. No message, cancellation, review or booking was changed. Evidence: .wantok/cx1-web-track-live-20261011.png.
2. Wallet: live K0.00 preview loaded, clearly stating that payment rails are not active. Planned card, wallet, bank and mobile-money methods are placeholders, not functional payment acceptance. No transaction. Evidence: .wantok/cx1-web-wallet-live-20261011.png.
3. Inbox: live Services (0) and Help & support (1) categories loaded. Services showed a legitimate empty conversation state. Help & support displayed one existing owner-private QA request with Open status; no request details were altered, no reply was sent, no new handoff was made. Evidence: .wantok/cx1-web-inbox-live-20261011.png and .wantok/cx1-web-inbox-support-live-20261011.png.
4. Wantok Agent: page opened from Client Home. Capability notice says no AI chat model provider has been connected yet; provider-search shortcuts and a human-handoff request option are visible. No model inference, chat submission or human request was attempted. Evidence: .wantok/cx1-web-agent-live-20261011.png.
5. Saved after a full Chrome hard reload: navigated from Home to the account/profile page and opened Saved again. The previously existing Wantok QA Plumbing Services entry was still listed after reload. This confirms same signed-in Web session post-reload visibility; it is not multi-device, logout/login or cross-account persistence. No bookmark toggle/remove was clicked. Evidence: .wantok/cx1-postreload-saved-list-20261011.png.

## Caution and incomplete checks
- After the post-reload Saved screenshot, the next attempted toolbar click unexpectedly navigated to the vendor-application form. No fields were entered or submitted. Further browser automation was halted to avoid clashing with parallel vendor development. Therefore do NOT mark live Saved refresh-button click behaviour as passed.
- Current source and earlier isolated Flutter widget tests passed for Inbox and Track refresh controls, but the actual live Inbox/Track browser screenshots in this round do not visibly establish their toolbar buttons. Mark browser toolbar interaction and current cache/visual parity as an open acceptance item. Do not infer a defect cause without a controlled reproduction.
- Current local Chrome remains signed in; never export screenshots, profile contact details, messages, session cookies, bearer tokens or passwords to Git. All screenshot files are under Git-ignored .wantok.
- No source, backend schema, category activation, financial rail, production support status or provider data was changed in this acceptance-only pass. Technical 3100 and Operations 3200 were not redeployed.

## Remaining CX1
Verify live read-only toolbar refresh in an isolated browser window with stable focus; optionally test Saved after genuine sign-out/sign-in only with user agreement; signed-in Android and physical HONOR; six inactive categories' individual PNG/Pacific realistic artwork and image-upload/editor verification. CX1 IN PROGRESS. T2.4 DEFERRED.
