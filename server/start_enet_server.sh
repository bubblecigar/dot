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

DEFAULT_PORT="$(default_from_config port)"
DEFAULT_MAX_CLIENTS="$(default_from_config max_clients)"

PORT="${PORT:-${DEFAULT_PORT:-7000}}"
MAX_CLIENTS="${MAX_CLIENTS:-${DEFAULT_MAX_CLIENTS:-32}}"

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
  --path "${ROOT_DIR}" \
  "server/ServerMain.tscn" \
  -- \
  --port="${PORT}" \
  --max-clients="${MAX_CLIENTS}"
