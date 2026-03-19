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

DEFAULT_BIND_HOST="$(default_from_config bind_host)"
DEFAULT_AUTH_PORT="$(default_from_config auth_port)"
DEFAULT_PUBLIC_AUTH_HOST="$(default_from_config public_auth_host)"

BIND_HOST="${BIND_HOST:-${DEFAULT_BIND_HOST:-0.0.0.0}}"
AUTH_PORT="${AUTH_PORT:-${DEFAULT_AUTH_PORT:-7001}}"
PUBLIC_AUTH_HOST="${PUBLIC_AUTH_HOST:-${DEFAULT_PUBLIC_AUTH_HOST:-127.0.0.1}}"

if command -v godot >/dev/null 2>&1; then
  GODOT_BIN="godot"
elif command -v godot4 >/dev/null 2>&1; then
  GODOT_BIN="godot4"
else
  echo "Error: neither 'godot' nor 'godot4' found in PATH." >&2
  exit 1
fi

exec env \
  BIND_HOST="${BIND_HOST}" \
  AUTH_PORT="${AUTH_PORT}" \
  PUBLIC_AUTH_HOST="${PUBLIC_AUTH_HOST}" \
  "${GODOT_BIN}" \
  --headless \
  --path "${ROOT_DIR}/authServer" \
  "res://AuthServerMain.tscn" \
  -- \
  --bind-host="${BIND_HOST}" \
  --auth-port="${AUTH_PORT}"
