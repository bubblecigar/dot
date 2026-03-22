#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_ENV="${CONFIG_ENV:-local}"
INIT_USERNAME="${INIT_USERNAME:-}"
INIT_PASSWORD="${INIT_PASSWORD:-}"
EXTRA_ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --init-username=*)
      INIT_USERNAME="${1#*=}"
      shift
      ;;
    --init-username)
      INIT_USERNAME="${2:-}"
      shift 2
      ;;
    --init-password=*)
      INIT_PASSWORD="${1#*=}"
      shift
      ;;
    --init-password)
      INIT_PASSWORD="${2:-}"
      shift 2
      ;;
    --)
      shift
      while [[ $# -gt 0 ]]; do
        EXTRA_ARGS+=("$1")
        shift
      done
      ;;
    *)
      EXTRA_ARGS+=("$1")
      shift
      ;;
  esac
done

if [[ -n "${GODOT_BIN:-}" ]]; then
  :
elif command -v godot >/dev/null 2>&1; then
  GODOT_BIN="godot"
elif command -v godot4 >/dev/null 2>&1; then
  GODOT_BIN="godot4"
else
  echo "Error: neither 'godot' nor 'godot4' found in PATH." >&2
  exit 1
fi

if [[ -n "${INIT_USERNAME}" ]]; then
  EXTRA_ARGS+=("--init-username=${INIT_USERNAME}")
fi

if [[ -n "${INIT_PASSWORD}" ]]; then
  EXTRA_ARGS+=("--init-password=${INIT_PASSWORD}")
fi

exec env \
  CONFIG_ENV="${CONFIG_ENV}" \
  "${GODOT_BIN}" \
  --path "${ROOT_DIR}/gameClient" \
  -- \
  "${EXTRA_ARGS[@]}"
