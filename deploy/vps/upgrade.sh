#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENV_FILE="${WANTOK_ENV_FILE:-$ROOT/deploy/vps/.env}"
COMPOSE_FILE="$ROOT/deploy/vps/docker-compose.yml"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing $ENV_FILE"
  exit 1
fi

set -a
source "$ENV_FILE"
set +a

"$ROOT/deploy/vps/backup.sh"

if [[ "${WANTOK_UPGRADE_SUPABASE:-0}" == "1" ]]; then
  if [[ -x "$SUPABASE_PROJECT_DIR/update.sh" || -f "$SUPABASE_PROJECT_DIR/update.sh" ]]; then
    echo "==> Previewing official Supabase self-host update"
    (cd "$SUPABASE_PROJECT_DIR" && sh update.sh --dry-run)

    echo "==> Applying official Supabase self-host update"
    (cd "$SUPABASE_PROJECT_DIR" && sh update.sh)
  else
    echo "Supabase update.sh not found at $SUPABASE_PROJECT_DIR"
    exit 1
  fi
fi

"$ROOT/deploy/vps/provision-supabase.sh"
"$ROOT/deploy/vps/migrate.sh"

echo "==> Rebuilding Wantok web applications"
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" build --pull
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" up -d --remove-orphans
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" ps
