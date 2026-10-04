#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENV_FILE="${WANTOK_ENV_FILE:-$ROOT/deploy/vps/.env}"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing $ENV_FILE"
  echo "Copy deploy/vps/.env.example to deploy/vps/.env and configure it first."
  exit 1
fi

set -a
source "$ENV_FILE"
set +a

: "${SUPABASE_PROJECT_DIR:?SUPABASE_PROJECT_DIR is required}"
: "${SUPABASE_SELF_HOST_REF:?SUPABASE_SELF_HOST_REF is required}"
: "${WANTOK_DOMAIN:?WANTOK_DOMAIN is required}"

command -v git >/dev/null || { echo "git is required."; exit 1; }
command -v openssl >/dev/null || { echo "openssl is required."; exit 1; }
command -v jq >/dev/null || { echo "jq is required."; exit 1; }
command -v docker >/dev/null || { echo "Docker is required."; exit 1; }
docker compose version >/dev/null

set_env() {
  local file="$1"
  local key="$2"
  local value="$3"

  if grep -q "^${key}=" "$file"; then
    sed -i "s|^${key}=.*|${key}=${value}|" "$file"
  else
    printf '\n%s=%s\n' "$key" "$value" >> "$file"
  fi
}

if [[ ! -f "$SUPABASE_PROJECT_DIR/docker-compose.yml" ]]; then
  echo "==> Provisioning official Supabase self-host runtime ($SUPABASE_SELF_HOST_REF)"
  mkdir -p "$(dirname "$SUPABASE_PROJECT_DIR")"

  TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "$TMP_DIR"' EXIT

  git clone --depth 1 --branch "$SUPABASE_SELF_HOST_REF" \
    https://github.com/supabase/supabase.git "$TMP_DIR/supabase"

  mkdir -p "$SUPABASE_PROJECT_DIR"
  cp -rf "$TMP_DIR/supabase/docker/." "$SUPABASE_PROJECT_DIR/"
  cp "$SUPABASE_PROJECT_DIR/.env.example" "$SUPABASE_PROJECT_DIR/.env"
  printf 'ref=%s\n' "$SUPABASE_SELF_HOST_REF" > "$SUPABASE_PROJECT_DIR/.supabase-version"

  (
    cd "$SUPABASE_PROJECT_DIR"
    sh utils/generate-keys.sh --update-env
    sh utils/add-new-auth-keys.sh --update-env
  )
else
  echo "==> Existing Supabase runtime found at $SUPABASE_PROJECT_DIR"
fi

SUPABASE_ENV="$SUPABASE_PROJECT_DIR/.env"
if [[ ! -f "$SUPABASE_ENV" ]]; then
  echo "Supabase runtime is missing .env"
  exit 1
fi

POSTGRES_PASSWORD="$(grep '^POSTGRES_PASSWORD=' "$SUPABASE_ENV" | cut -d= -f2-)"
if [[ -z "$POSTGRES_PASSWORD" || "$POSTGRES_PASSWORD" == "your-super-secret-and-long-postgres-password" ]]; then
  POSTGRES_PASSWORD="$(openssl rand -hex 24)"
  set_env "$SUPABASE_ENV" POSTGRES_PASSWORD "$POSTGRES_PASSWORD"
fi

set_env "$SUPABASE_ENV" SUPABASE_PUBLIC_URL "https://api.${WANTOK_DOMAIN}"
set_env "$SUPABASE_ENV" API_EXTERNAL_URL "https://api.${WANTOK_DOMAIN}/auth/v1"
set_env "$SUPABASE_ENV" SITE_URL "https://${WANTOK_DOMAIN}"
set_env "$SUPABASE_ENV" PROXY_DOMAIN "api.${WANTOK_DOMAIN}"
set_env "$SUPABASE_ENV" WANTOK_DB_PORT "${WANTOK_DB_PORT:-54322}"

cp "$ROOT/deploy/vps/supabase.wantok.override.yml" \
  "$SUPABASE_PROJECT_DIR/docker-compose.wantok.yml"
set_env "$SUPABASE_ENV" COMPOSE_FILE "docker-compose.yml:docker-compose.wantok.yml"

chmod 600 "$SUPABASE_ENV"

echo "==> Pulling and starting Supabase"
(
  cd "$SUPABASE_PROJECT_DIR"
  sh run.sh pull
  sh run.sh start
)

PUBLISHABLE_KEY="$(grep '^SUPABASE_PUBLISHABLE_KEY=' "$SUPABASE_ENV" | cut -d= -f2-)"
POSTGRES_PASSWORD="$(grep '^POSTGRES_PASSWORD=' "$SUPABASE_ENV" | cut -d= -f2-)"
POSTGRES_PASSWORD_URL="$(printf '%s' "$POSTGRES_PASSWORD" | jq -sRr @uri)"

if [[ -z "$PUBLISHABLE_KEY" ]]; then
  echo "Supabase did not generate SUPABASE_PUBLISHABLE_KEY."
  exit 1
fi

set_env "$ENV_FILE" SUPABASE_PUBLISHABLE_KEY "$PUBLISHABLE_KEY"
set_env "$ENV_FILE" DATABASE_URL \
  "postgresql://postgres:${POSTGRES_PASSWORD_URL}@127.0.0.1:${WANTOK_DB_PORT:-54322}/postgres"

chmod 600 "$ENV_FILE"

echo "==> Supabase is provisioned and Wantok deployment configuration is synchronised."
echo "    Studio/API gateway host ports are not publicly published by the Wantok override."
