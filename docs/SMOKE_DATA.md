# Wantok Services — smoke/sample data registry

**Introduced:** 8 October 2026
**Owner:** Wantok Services project
**Purpose:** Temporary, clearly identifiable visual QA fixtures matching the reference app theme. They are **not** legitimate accounts, vendor inventory, bookings, messages, payments, tracking events or provider approvals.

## Isolation and enabling

All records reside in `apps/wantok_app/lib/src/home/smoke_data.dart`, and are shown only when the Flutter compile-time flag `WANTOK_SMOKE_DATA=true` is set. The normal default is **false**. This is presentation-only code; it does not insert rows into Supabase, generate authorised booking IDs, invoke payment APIs, reserve inventory or send communications.

For a local emulator/Web development build, add `--dart-define=WANTOK_SMOKE_DATA=true` to the existing `flutter run` or `flutter build` command. Never enable the flag for production release builds. Production workflows continue to use real, permission-checked backend data.

Each record's identifier starts with **`SMOKE_20261008_`**, and each sample item visibly carries a small blue **s** icon. The icon has an accessibility label and tooltip identifying it as smoke/sample data. Tapping any sample row opens an informational preview with the **full ID** and a statement that no real transaction can occur. The section heading also explicitly says sample content.

## Registry of temporary records

| ID | Area | Purpose |
|---|---|---|
| `SMOKE_20261008_PROVIDER_001` | Home | Sample Waterfront restaurant |
| `SMOKE_20261008_PROVIDER_002` | Home | Sample local market vendor |
| `SMOKE_20261008_FOOD_001` | Food | Sample Waterfront menu |
| `SMOKE_20261008_FOOD_002` | Food | Sample Trukai Haus meal |
| `SMOKE_20261008_GROCERY_001` | Groceries | Sample Fresh Market Basket |
| `SMOKE_20261008_BOOKING_001` | Track | Sample taxi booking |
| `SMOKE_20261008_BOOKING_002` | Track | Sample food order |
| `SMOKE_20261008_BOOKING_003` | Track | Sample water trip |
| `SMOKE_20261008_WALLET_001` | Wallet | Sample food payment history |
| `SMOKE_20261008_WALLET_002` | Wallet | Sample taxi payment history |
| `SMOKE_20261008_INBOX_001` | Inbox | Sample conversation |
| `SMOKE_20261008_EVENT_001` | Preview catalogue | Sample community event |
| `SMOKE_20261008_TRAVEL_001` | Preview catalogue | Sample water/travel |
| `SMOKE_20261008_TRADES_001` | Services | Sample professional service |

## Cleanup when the project is ready

1. Ensure production and release builds omit `WANTOK_SMOKE_DATA=true`; the samples immediately disappear from compiled UI with **no database deletion needed**.
2. When the sample visuals are no longer useful, delete `lib/src/home/smoke_data.dart` and `test/smoke_data_test.dart`, remove the `SmokePreviewSection` branches and `smoke_data.dart` imports from Home, Services, Food/Groceries, Track, Inbox and Wallet.
3. Search for `SMOKE_20261008`, `WantokSmokeData`, `SmokeMarker` and `SmokePreviewSection` to confirm no fixture or call site remains.
4. Run `scripts/flutter/check.ps1`, `npm run db:test`, verify `git diff --check`, then commit and back up both locally and to GitHub.
5. Because the fixtures never enter Supabase, **do not run any SQL deletes** for these identifiers. Never delete legitimate records by matching display names such as The Waterfront.

## Emulator preservation / backup

On 8 October 2026, before modifying the emulator, a full offline copy was made:

`D:\Wantok_AVD_Backups\Medium_Phone_API_36.1_20261008_pre_resize`

It included 1,114 AVD files, about 10.425 GB, with Robocopy reporting zero failed files. The main QCOW2 userdata SHA-256 matched its original:

`8307F175E62E95FFE297BBF54139BA4D9A3BBE0DC13C10B267AFAE478974737C`

The original 6 GB AVD was restored and booted after a direct resize failed due to an internal QCOW2 snapshot. A separate flattened userdata conversion on `D:` also failed with an I/O error, so it was **not** installed or substituted. Existing local auth, Android app data, and Supabase records were not intentionally changed. Do not delete the verified backup without express approval.
