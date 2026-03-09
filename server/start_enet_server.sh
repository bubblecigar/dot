#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORT="${PORT:-7000}"
MAX_CLIENTS="${MAX_CLIENTS:-32}"

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
