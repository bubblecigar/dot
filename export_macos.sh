#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRESET_NAME="macOS"
OUTPUT_PATH="${1:-export/Blank2DGames.dmg}"
EXPORT_DIR="${PROJECT_DIR}/export"

if command -v godot >/dev/null 2>&1; then
  GODOT_BIN="godot"
elif command -v godot4 >/dev/null 2>&1; then
  GODOT_BIN="godot4"
else
  echo "Error: neither 'godot' nor 'godot4' found in PATH." >&2
  exit 1
fi

rm -rf "${EXPORT_DIR}"
mkdir -p "${PROJECT_DIR}/$(dirname "$OUTPUT_PATH")"

echo "Using: ${GODOT_BIN}"
echo "Preset: ${PRESET_NAME}"
echo "Output: ${OUTPUT_PATH}"

"${GODOT_BIN}" --headless --path "${PROJECT_DIR}" --export-release "${PRESET_NAME}" "${OUTPUT_PATH}"

echo "Export completed: ${PROJECT_DIR}/${OUTPUT_PATH}"

if [[ "${OUTPUT_PATH}" == *.dmg ]]; then
  DMG_ABS="${PROJECT_DIR}/${OUTPUT_PATH}"
  MOUNT_POINT="$(hdiutil attach "${DMG_ABS}" -nobrowse -readonly | awk '/\/Volumes\// {print $3}' | tail -n1)"

  APP_NAME="$(basename "${OUTPUT_PATH}" .dmg).app"
  DEST_APP_PATH="${PROJECT_DIR}/export/${APP_NAME}"

  rm -rf "${DEST_APP_PATH}"
  cp -R "${MOUNT_POINT}/${APP_NAME}" "${DEST_APP_PATH}"

  hdiutil detach "${MOUNT_POINT}" >/dev/null
  rm -f "${DMG_ABS}"
  echo "App copied to: ${DEST_APP_PATH}"
  echo "Removed DMG: ${DMG_ABS}"
fi
