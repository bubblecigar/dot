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

DEFAULT_AUTH_PORT="$(default_from_config auth_port)"
AUTH_PORT="${AUTH_PORT:-${DEFAULT_AUTH_PORT:-7001}}"

if command -v godot >/dev/null 2>&1; then
  GODOT_BIN="godot"
elif command -v godot4 >/dev/null 2>&1; then
  GODOT_BIN="godot4"
else
  echo "Error: neither 'godot' nor 'godot4' found in PATH." >&2
  exit 1
fi

exec "${GODOT_BIN}" \
  --headless \
  --path "${ROOT_DIR}/authServer" \
  "res://AuthServerMain.tscn" \
  -- \
  --auth-port="${AUTH_PORT}"
