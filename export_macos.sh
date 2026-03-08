#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRESET_NAME="macOS"
OUTPUT_PATH="${1:-export/Blank2DGames.dmg}"

if command -v godot >/dev/null 2>&1; then
  GODOT_BIN="godot"
elif command -v godot4 >/dev/null 2>&1; then
  GODOT_BIN="godot4"
else
  echo "Error: neither 'godot' nor 'godot4' found in PATH." >&2
  exit 1
fi

mkdir -p "${PROJECT_DIR}/$(dirname "$OUTPUT_PATH")"

echo "Using: ${GODOT_BIN}"
echo "Preset: ${PRESET_NAME}"
echo "Output: ${OUTPUT_PATH}"

"${GODOT_BIN}" --headless --path "${PROJECT_DIR}" --export-release "${PRESET_NAME}" "${OUTPUT_PATH}"

echo "Export completed: ${PROJECT_DIR}/${OUTPUT_PATH}"
