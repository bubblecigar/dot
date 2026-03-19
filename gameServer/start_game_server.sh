#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOST_CONFIG="${ROOT_DIR}/shared/host.config"

default_from_config() {
  local key="$1"
  awk -F'=' -v target="${key}" '
    /^\[server\]/ { in_server=1; next }
    /^\[/ { in_server=0 }
    in_server && $1 ~ ("^" target "$") {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2)
      gsub(/"/, "", $2)
      print $2
      exit
    }
  ' "${HOST_CONFIG}"
}

DEFAULT_PORT="$(default_from_config game_port)"
DEFAULT_MAX_CLIENTS="$(default_from_config max_clients)"
DEFAULT_PUBLIC_GAME_HOST="$(default_from_config public_game_host)"
DEFAULT_PUBLIC_AUTH_HOST="$(default_from_config public_auth_host)"
DEFAULT_AUTH_UPSTREAM_HOST="$(default_from_config auth_upstream_host)"

PORT="${GAME_PORT:-${PORT:-${DEFAULT_PORT:-7000}}}"
MAX_CLIENTS="${MAX_CLIENTS:-${DEFAULT_MAX_CLIENTS:-32}}"
PUBLIC_GAME_HOST="${PUBLIC_GAME_HOST:-${DEFAULT_PUBLIC_GAME_HOST:-127.0.0.1}}"
PUBLIC_AUTH_HOST="${PUBLIC_AUTH_HOST:-${DEFAULT_PUBLIC_AUTH_HOST:-127.0.0.1}}"
AUTH_UPSTREAM_HOST="${AUTH_UPSTREAM_HOST:-${DEFAULT_AUTH_UPSTREAM_HOST:-127.0.0.1}}"

if command -v godot >/dev/null 2>&1; then
  GODOT_BIN="godot"
elif command -v godot4 >/dev/null 2>&1; then
  GODOT_BIN="godot4"
else
  echo "Error: neither 'godot' nor 'godot4' found in PATH." >&2
  exit 1
fi

exec env \
  PUBLIC_GAME_HOST="${PUBLIC_GAME_HOST}" \
  PUBLIC_AUTH_HOST="${PUBLIC_AUTH_HOST}" \
  AUTH_UPSTREAM_HOST="${AUTH_UPSTREAM_HOST}" \
  GAME_PORT="${PORT}" \
  MAX_CLIENTS="${MAX_CLIENTS}" \
  "${GODOT_BIN}" \
  --headless \
  --path "${ROOT_DIR}/gameServer" \
  "res://ServerMain.tscn" \
  -- \
  --port="${PORT}" \
  --max-clients="${MAX_CLIENTS}"
