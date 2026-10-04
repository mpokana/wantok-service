#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

for target in   packages/wantok_core   packages/wantok_api   packages/wantok_auth   packages/wantok_ui   apps/wantok_app   apps/wantok_admin
do
  echo "==> flutter pub get: $target"
  (cd "$ROOT/$target" && flutter pub get)
done
