#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENV_FILE="${WANTOK_ENV_FILE:-$ROOT/deploy/vps/.env}"
COMPOSE_FILE="$ROOT/deploy/vps/docker-compose.yml"

command -v docker >/dev/null || { echo "Docker is required."; exit 1; }
docker compose version >/dev/null

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing $ENV_FILE"
  echo "Copy deploy/vps/.env.example to deploy/vps/.env and configure it first."
  exit 1
fi

chmod 600 "$ENV_FILE"

echo "==> Provisioning/configuring production Supabase"
"$ROOT/deploy/vps/provision-supabase.sh"

echo "==> Applying Wantok migrations"
"$ROOT/deploy/vps/migrate.sh"

echo "==> Building Wantok web applications"
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" build --pull

echo "==> Starting Wantok edge/web stack"
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" up -d --remove-orphans

echo "==> Deployment status"
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" ps
