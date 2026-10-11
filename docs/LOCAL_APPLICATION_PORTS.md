# EAGLT02 — Wantok local applications and ports

**Updated:** 11 October 2026
**Environment:** EAGLT02 (local development only; NOT production)
**Technical Control navigation:** `http://127.0.0.1:3100/` → **Local applications & ports**. This link is visible only to authenticated Technical Platform Administrators, alongside Theme & Media. The page is read-only, contains no credentials or configuration toggles, and offers a manual **Open** link for each application.

| Port | Application | Address | Purpose | Serving environment |
| --- | --- | --- | --- | --- |
| 3000 | Wantok Services Client | http://127.0.0.1:3000/ | Customer-facing Client site, catalogue, provider discovery, Inbox, Track and Wallet preview | Main local Client |
| 3100 | Technical Control | http://127.0.0.1:3100/ | Technical modules, permissions, Theme & Media, application links | Main local Technical |
| 3200 | Operations Admin | http://127.0.0.1:3200/ | Operations management and Support & Inquiries | Main local Operations (previous `a69d366` Admin build) |
| 3300 | Client staging | http://127.0.0.1:3300/ | Independent Client preview for testing before deployment to 3000 | Staging snapshot |
| 3400 | Technical staging | http://127.0.0.1:3400/ | Independent Technical preview for testing before deployment to 3100 | Staging snapshot |

## Isolation and operational safety

- **127.0.0.1 means the device running the browser.** Links work against EAGLT02 only when opened in a browser on EAGLT02. They do not route to EAGLT02 from a mobile handset, another PC or the public internet.
- **Links are not health checks.** An Open button launches a browser address; it neither probes uptime nor reports an invented online/offline status. For live health, check the local HTTP response or monitored service process separately.
- Main Client files are served from `D:\Project-M.2\wantok-service-recovery\apps\wantok_app\build\web` on port 3000. Main Technical files are served from `...\apps\wantok_tech\build\web` on port 3100. The Admin on 3200 remains a separate Flutter web-server process, not a published release.
- **Staging separation corrected on 11 October 2026:** 3300 now serves `D:\Wantok_Staging_Builds_20261011\Client` and 3400 serves `D:\Wantok_Staging_Builds_20261011\Technical`, rather than both pointing at the corresponding main build directories. Each original main.dart.js staging copy was SHA-256 checked before re-binding. Staging files are static snapshots: rebuilding main does not automatically refresh them.
- The new Technical Control page was compiled with the existing `.wantok\local-web.json` backend definitions (no data reset, live payments or sample fixtures), verified by dedicated 390/1200 px and link-opening widget tests, and deployed to the local main Technical directory after a verified backup. Pre-deployment files remain at `D:\Wantok_Project_Backups\wantok-tech-web-preports-20261011`; the former main directory is also retained beside the updated build as `web-preports-preserved-20261011`.
- Existing **Public Services**, local PNG/JPG category pictures, Theme & Media and CX1 user/provider records are preserved. Port 3200's newer Public Services operations switch is still **source-only** until deliberately deployed and reviewed; do not imply activation.
- These port assignments and this document should be revised together if the local architecture changes. Do not open these development listeners to the public internet; plan authenticated HTTPS reverse-proxy endpoints for any future public rollout.

## CX1 acceptance boundary

The Technical port directory is a platform usability feature, **not** evidence that Client Web category-first discovery has been accepted. The signed-in Client Web `Services → Browse providers → Specialist Services → Morobe → Lae` journey (blank keyword), provider details, Saved read-only state, Account/Inbox/Track/Wallet/Wantok Agent, Android/HONOR parity and any authorised final production deployments remain independently gated. **CX1 IN PROGRESS; T2.4 DEFERRED.**
