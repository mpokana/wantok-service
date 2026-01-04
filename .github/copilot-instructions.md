## Quick context

This is an Expo + TypeScript mobile/web app using the Expo Router (file-based routing) and Supabase for auth and backend data. Key folders:

- `app/` — file-based routes (see `app/(tabs)/_layout.tsx` and `app/_layout.tsx`).
- `lib/supabase.ts` — single Supabase client used across the app (contains the current anon key and URL).
- `contexts/` — React contexts (notably `AuthContext.tsx`) that wrap the top-level layout.
- `components/` and `components/ui/` — reusable UI primitives and patterns (themed components are preferred).

## What to know first (big picture)

- Routing: The project uses `expo-router` file-based routing. Creating a screen is done by adding files under `app/` (e.g. `app/(tabs)/services/hire.tsx` becomes the `services/hire` route). Layout files (`_layout.tsx`) define stacks/tabs for their subtree.
- Auth: `AuthProvider` from `contexts/AuthContext.tsx` wraps the app in `app/_layout.tsx`. Auth state is provided via `useAuth` and `useAuthProfile` (used in `app/(tabs)/_layout.tsx` to gate the Provider tab).
- Data: `lib/supabase.ts` exports a configured Supabase client. The app expects the client to handle session persistence and auth state changes.
- UI conventions: Use themed primitives (`themed-text.tsx`, `themed-view.tsx`) and the `components/ui` folder for shared controls. Small, focused components are preferred (see `parallax-scroll-view.tsx` and `haptic-tab.tsx`).

## Developer workflows (commands and tips)

- Install: `npm install`
- Start / development: `npm start` or `npx expo start` (also exposed as `npm run android`, `npm run ios`, `npm run web`).
- Reset starter scaffolding: `npm run reset-project` (this is provided by `scripts/reset-project.js`).
- Lint: `npm run lint` (uses Expo ESLint config).

Notes: `package.json` sets the `main` to `expo-router/entry` — rely on `expo start` / `expo-router` rather than a custom entry point.

## Project-specific patterns & gotchas

- Strict TypeScript: `tsconfig.json` enables `strict: true` and path alias `@/* -> ./*`. Use existing types and keep strictness in mind when returning `null` vs `undefined`.
- Provider gating: `app/(tabs)/_layout.tsx` conditionally renders the provider tab using `profile?.is_provider`. When adding provider-only screens, place them under the `provider` subtree so layout gating works automatically.
- Single Supabase client: All modules import `supabase` from `lib/supabase.ts`. That file currently contains a public anon key and URL — treat as sensitive when modifying; prefer using environment variables if adding CI or production secrets.
- Auth lifecycle: `AuthContext` reads `supabase.auth.getSession()` on init and subscribes to `onAuthStateChange`. Use this pattern for any new auth-aware code to avoid double-fetching.

## Examples to show typical tasks

- Add a new route visible in Tabs:
  1. Create `app/(tabs)/services/new-service.tsx`.
  2. The file path name maps to route `services/new-service`.
  3. If it should appear as a tab, add a `Tabs.Screen` entry in `app/(tabs)/_layout.tsx`.

- Use Supabase and current user id:
  ```ts
  import { supabase } from '../lib/supabase';
  import { useAuth } from '../contexts/AuthContext';

  const { user } = useAuth();
  // then use user.id when calling Supabase
  ```

## What the AI agent should not change

- Do not commit new secrets into `lib/supabase.ts` or any source file. If you need to add credentials, use environment variables and update docs / CI accordingly.
- Preserve the `expo-router` file-layout (don't refactor routing to programmatic route tables without updating layouts and tabs).

## Files to inspect for deeper changes

- `lib/supabase.ts` — supabase setup and auth options
- `contexts/AuthContext.tsx` and `hooks/useAuthProfile.ts` — auth and profile gating logic
- `app/(tabs)/_layout.tsx` and `app/_layout.tsx` — routing/layout composition
- `components/` and `components/ui/` — shared UI primitives & patterns
- `scripts/reset-project.js` — reset workflow for starter code

## If you need to run tests / build / CI

- There are no test scripts in `package.json`. The primary workflows are the Expo dev flow. For platform-specific builds use Expo docs and `expo build` / EAS if required.

---

If any of these sections are unclear or you'd like me to add CI/secret management instructions (or convert the inline Supabase key to env handling), tell me which area to expand and I will update the file.
