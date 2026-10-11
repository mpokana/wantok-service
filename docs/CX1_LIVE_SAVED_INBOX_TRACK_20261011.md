# CX1 — Live Saved and Inbox/Track refresh
Date: 11 October 2026, PNG. Host: EAGLT02, Client Web 3000.

## Live authenticated browser acceptance
The earlier category-first Specialist Services → Morobe → Lae → approved QA provider-detail journey remains PASS. This turn, opened My Settings → Account and profile → Saved in the signed-in Client Web. The actual list displayed the previously saved Wantok QA Plumbing Services provider. No bookmark was created or removed, and no booking, payment, message, review or account update was submitted. Private image evidence remains in the ignored .wantok/cx1-live-saved-readonly-20261011.png; personal account details and screenshots must not enter Git.

A later hard browser reload returned the Flutter app to Home. Subsequent UI navigation was blocked by safety checks; do not claim post-reload or cross-session Saved persistence, or live visual confirmation of the Saved refresh button after reload. These remain separate gates.

## Inbox and Track work
MessagesPage now has an explicit Refresh Inbox control in its green header, reloading existing owner-scoped service conversations and support requests only. ActivityPage has Refresh activity in its header for populated, empty and error states, reloading current reservations only. Guards prevent overlapping refresh requests, and Track disables refresh while an existing booking/review operation is active. Existing pull-to-refresh, Retry, RLS and transactional controls remain unchanged. No backend schema changes.

Six focused injected-loader widget tests PASS for 390px and 1440px plus failed-read recovery; tests perform no writes. Isolated clean QA worktree D:\Wantok_CX1_Inbox_Track_QA_20261011. Full seven Flutter analyses and Client, Operations and Technical widget suites PASS after correcting a Dart brace lint.

## Web release and backups
Compiled Client main.dart.js SHA-256 AB18B9EB8F0733482B396E3C122EB0B726AB9CF2823A79458B0F34AB9178C51D. Deployed to Client main 3000 and staging 3300 with HTTP and photo integrity checks. Old full Web build backed up to D:\Wantok_Project_Backups\wantok-client-web-pre-inbox-track-refresh-20261011; verified candidate retained at D:\Wantok_Project_Backups\wantok-client-web-inbox-track-refresh-candidate-20261011. Technical Control 3100, Operations 3200 and Technical staging 3400 untouched.

Android offline-demo x64 APK **build 4009** compiled from the same isolated QA source, independently copied and hash verified at D:\Wantok_Project_Backups\wantok-client-cx1-inbox-track-android-preview-4009-20261011.apk (SHA-256 E6E529939F6F44D938BD98F94DDF5CA57C72288B7D63081B047576DBF08DB06F, 92,825,175 bytes). In-place adb install -r returned Success; versionCode 4009 confirmed, application launched, original firstInstallTime 2026-10-05 23:44:14 unchanged. Existing app/data retained. This is NOT physical HONOR or signed-in phone acceptance.

## Open CX1 gates
Post-reload Saved collection, actual live Inbox/Track/Wallet/Agent routes, physical HONOR, signed-in Android, individual PNG/Pacific-themed pictures for six inactive new categories and browser category media CRUD remain OPEN. CX1 IN PROGRESS; T2.4 DEFERRED.
