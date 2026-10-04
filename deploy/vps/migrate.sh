#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENV_FILE="${WANTOK_ENV_FILE:-$ROOT/deploy/vps/.env}"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing $ENV_FILE"
  exit 1
fi

set -a
source "$ENV_FILE"
set +a

if [[ -z "${DATABASE_URL:-}" || "$DATABASE_URL" == "auto" ]]; then
  echo "DATABASE_URL has not been synchronised."
  exit 1
fi

echo "==> Applying Wantok database migrations"

if command -v npx >/dev/null; then
  (
    cd "$ROOT"
    npx supabase db push --db-url "$DATABASE_URL" --yes
  )
  exit 0
fi

command -v docker >/dev/null || {
  echo "Either npx or Docker is required to run Supabase migrations."
  exit 1
}

CLI_VERSION="${SUPABASE_CLI_VERSION:-2.119.0}"

docker run --rm \
  --network host \
  -e DATABASE_URL="$DATABASE_URL" \
  -v "$ROOT:/workspace" \
  -w /workspace \
  node:20-bookworm \
  bash -lc "npx --yes supabase@${CLI_VERSION} db push --db-url \"\$DATABASE_URL\" --yes"
