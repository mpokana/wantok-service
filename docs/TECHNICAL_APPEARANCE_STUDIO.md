# Wantok Services: responsive web parity and Technical Appearance Studio
Date: 11 October 2026

## Scope and current deployment
- Flutter CLIENT is the shared source for desktop browser, tablet browser,
  mobile browser and Android. The category mapping fix (commit 6508781) remains
  the default in all clients. No category, taxi, order or payment workflow was
  changed by this task.
- EAGLT02 local browser client: http://127.0.0.1:3000/
- EAGLT02 local Technical Control Panel: http://127.0.0.1:3100/
- Operations/Admin web: http://127.0.0.1:3200/ is unchanged.
- Release web builds also have verified staging at ports 3300/3400.
- These are local development URLs only. **No public production domain was
  deployed, and no production data was touched.**

## Access
Technical Platform Administrators have a **Theme & Media** link in the Technical
Control Panel sidebar (on smaller screens the sidebar is a drawer), and a
palette icon in the panel toolbar. Lower-level technicians cannot access the
editor. The backend verifies the same role on every draft, publish and restore
operation, even if a client attempts a direct API call.

## Appearance editor workflow
1. Choose light, dark or system mode, primary and secondary hex colours, and
   card corner radius.
2. In Media & Icons choose a category and one of three distinct upload slots:
   Home tile icon, Services card picture or module banner. Public Services
   includes all four subcategories. JPEG, PNG, WebP only, maximum 3 MiB. Images
   are checked for recognisable content signatures.
3. Use **Save draft**. Customers continue using the last published version.
4. Use **Preview devices** and inspect mobile/tablet/desktop widths against the
   draft. A draft must have been previewed after its last edit to enable Publish.
5. Use **Publish** and confirm. A new version is created; clients pick up the
   published theme/media on app/browser refresh or restart.
6. **Rollback version** creates a new published version from an earlier snapshot.
   **Restore defaults to draft** is non-destructive until saved, previewed and
   published.

## Technical design
- `public.wantok_branding_state`: singleton published/draft JSON and optimistic
  version/revision numbers. Direct user table access revoked; public read is
  published only through `get_published_wantok_branding()`.
- `public.wantok_branding_history`: version snapshots. PostgreSQL functions
  enforce `is_technical_platform_admin`, valid category/slot-specific paths,
  theme field constraints and optimistic version checks. Changes are audited.
- `wantok-branding` Supabase Storage bucket: technical-admin-only INSERT.
  Immutable images are intentionally not overwritten/deleted so previous
  published versions are recoverable. Public storage is suitable for published
  commercial/public image assets only: **do not upload confidential pictures**.
  An uploaded draft picture has a public URL but will not appear in the app
  until its path is published.
- `WantokBrandingScope`: client-wide published appearance snapshot. If local
  Supabase is unavailable, the app uses its existing bundled icons/pictures
  and original theme; existing services remain usable.
- Bundled default category images are NOT deleted or modified by overrides.
  No unrelated pictures are automatically reassigned to a different category.
- The settings currently cover Material colour scheme, dark/light/system mode,
  cards/buttons and the explicitly wired Home/Services/Public Services assets.
  Hard-coded decorative colours elsewhere are not yet theme-token driven.

## Development checklist / operator safety
- Do not reset local Supabase or replace production.
- Build from `D:\Project-M.2\wantok-service-recovery` rather than dated
  `D:\Wantok_Web_*_20261010` snapshots.
- After code edits, rebuild web releases and hard-refresh browsers.
- If using local static-server processes, they must be restarted after
  machine reboot; these are non-production development previews.
- The Technical Control Panel requires a real technical-platform-admin login
  to exercise live storage uploads and publish from the browser.
- Database contracts and device preview widget tests run automatically;
  an authorised human should also inspect uploads and visual previews before
  publishing to real customers.
