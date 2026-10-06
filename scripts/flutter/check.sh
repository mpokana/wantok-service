#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

for target in \
  packages/wantok_core \
  packages/wantok_api \
  packages/wantok_auth \
  packages/wantok_ui \
  apps/wantok_app \
  apps/wantok_admin \
  apps/wantok_tech
do
  echo "==> flutter analyze: $target"
  (cd "$ROOT/$target" && flutter analyze)
done

(cd "$ROOT/apps/wantok_app" && flutter test)
(cd "$ROOT/apps/wantok_admin" && flutter test)
(cd "$ROOT/apps/wantok_tech" && flutter test)
