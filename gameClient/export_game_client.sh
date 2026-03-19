#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_DIR="${ROOT_DIR}/gameClient"
PROJECT_FILE="${PROJECT_DIR}/project.godot"
EXPORT_PRESETS_FILE="${PROJECT_DIR}/export_presets.cfg"

if [[ $# -gt 2 ]]; then
  echo "Usage: $0 [preset-name] [output-path]" >&2
  exit 1
fi

if [[ ! -f "${PROJECT_FILE}" ]]; then
  echo "Error: project.godot not found in ${PROJECT_DIR}" >&2
  exit 1
fi

if [[ ! -f "${EXPORT_PRESETS_FILE}" ]]; then
  echo "Error: export_presets.cfg not found in ${PROJECT_DIR}" >&2
  exit 1
fi

PRESET_NAME="${1:-${EXPORT_PRESET:-}}"
OUTPUT_PATH_INPUT="${2:-${EXPORT_PATH:-}}"
OUTPUT_FROM_PRESET="false"

if [[ -z "${PRESET_NAME}" ]]; then
  PRESET_NAME="$(awk -F'"' '/^name="/ { print $2; exit }' "${EXPORT_PRESETS_FILE}")"
fi

if [[ -z "${PRESET_NAME}" ]]; then
  echo "Error: no export preset name provided and none found in ${EXPORT_PRESETS_FILE}" >&2
  exit 1
fi

if command -v godot >/dev/null 2>&1; then
  GODOT_BIN="godot"
elif command -v godot4 >/dev/null 2>&1; then
  GODOT_BIN="godot4"
else
  echo "Error: neither 'godot' nor 'godot4' found in PATH." >&2
  exit 1
fi

if [[ -z "${OUTPUT_PATH_INPUT}" ]]; then
  OUTPUT_PATH_INPUT="$(awk -F'"' -v target="${PRESET_NAME}" '
    /^\[preset\.[0-9]+\]/ {
      in_preset=1
      matched=0
      next
    }
    /^\[preset\.[0-9]+\.options\]/ {
      in_preset=0
      next
    }
    in_preset && /^name="/ {
      matched=($2 == target)
      next
    }
    in_preset && matched && /^export_path="/ {
      print $2
      exit
    }
  ' "${EXPORT_PRESETS_FILE}")"
  if [[ -n "${OUTPUT_PATH_INPUT}" ]]; then
    OUTPUT_FROM_PRESET="true"
  else
    OUTPUT_PATH_INPUT="${ROOT_DIR}/build/gameClient/gameClient"
  fi
fi

case "${OUTPUT_PATH_INPUT}" in
  /*) OUTPUT_PATH="${OUTPUT_PATH_INPUT}" ;;
  *)
    if [[ "${OUTPUT_FROM_PRESET}" == "true" ]]; then
      OUTPUT_PATH="${PROJECT_DIR}/${OUTPUT_PATH_INPUT}"
    else
      OUTPUT_PATH="${ROOT_DIR}/${OUTPUT_PATH_INPUT}"
    fi
    ;;
esac

mkdir -p "$(dirname "${OUTPUT_PATH}")"

echo "Exporting gameClient"
echo "Project: ${PROJECT_DIR}"
echo "Preset: ${PRESET_NAME}"
echo "Output: ${OUTPUT_PATH}"

exec "${GODOT_BIN}" \
  --headless \
  --path "${PROJECT_DIR}" \
  --export-release "${PRESET_NAME}" "${OUTPUT_PATH}"
