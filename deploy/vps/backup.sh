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

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
BACKUP_ROOT="${WANTOK_BACKUP_DIR:-/opt/wantok-service/backups}"
DEST="$BACKUP_ROOT/$STAMP"
mkdir -p "$DEST"

if [[ -f "$SUPABASE_PROJECT_DIR/docker-compose.yml" ]]; then
  echo "==> Backing up PostgreSQL"
  (
    cd "$SUPABASE_PROJECT_DIR"
    docker compose exec -T db pg_dump -U postgres -d postgres -Fc
  ) > "$DEST/postgres.dump"

  if [[ -d "$SUPABASE_PROJECT_DIR/volumes/storage" ]]; then
    echo "==> Backing up Storage volume files"
    tar -C "$SUPABASE_PROJECT_DIR/volumes" -czf "$DEST/storage.tgz" storage
  fi

  if [[ -f "$SUPABASE_PROJECT_DIR/.env" ]]; then
    cp "$SUPABASE_PROJECT_DIR/.env" "$DEST/supabase.env"
    chmod 600 "$DEST/supabase.env"
  fi

  if [[ -f "$SUPABASE_PROJECT_DIR/.supabase-version" ]]; then
    cp "$SUPABASE_PROJECT_DIR/.supabase-version" "$DEST/.supabase-version"
  fi
else
  echo "NOTICE: Supabase runtime not found; backend backup skipped."
fi

if [[ -f "$ROOT/VERSION" ]]; then
  cp "$ROOT/VERSION" "$DEST/wantok-version.txt"
fi

echo "Backup written to $DEST"
