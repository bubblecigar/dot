#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

REMOTE_HOST="${REMOTE_HOST:-198.13.54.180}"
REMOTE_USER="${REMOTE_USER:-root}"
REMOTE_DIR="${REMOTE_DIR:-/root/dot}"
PM2_ENV="${PM2_ENV:-prod}"
SSH_OPTS="${SSH_OPTS:-}"

if ! command -v ssh >/dev/null 2>&1; then
  echo "Error: ssh is required." >&2
  exit 1
fi

if ! command -v tar >/dev/null 2>&1; then
  echo "Error: tar is required." >&2
  exit 1
fi

ssh_cmd=(ssh)
if [[ -n "${SSH_OPTS}" ]]; then
  # shellcheck disable=SC2206
  ssh_opts_array=(${SSH_OPTS})
  ssh_cmd+=("${ssh_opts_array[@]}")
fi
ssh_cmd+=("${REMOTE_USER}@${REMOTE_HOST}")

echo "Deploying to ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}"
echo "PM2 environment: ${PM2_ENV}"

echo "[1/4] Preparing remote directory"
"${ssh_cmd[@]}" "mkdir -p '${REMOTE_DIR}' && rm -rf '${REMOTE_DIR}/gameClient/shared'"
echo "[1/4] Remote directory ready"

echo "[2/4] Uploading project files"
tar \
  --exclude='.git' \
  --exclude='.DS_Store' \
  --exclude='.vscode' \
  --exclude='.godot' \
  --exclude='build' \
  --exclude='gameClient/export' \
  --exclude='*.tmp' \
  -C "${ROOT_DIR}" \
  -czf - . | "${ssh_cmd[@]}" "tar -xzf - -C '${REMOTE_DIR}'"
echo "[2/4] Upload complete"

echo "[3/4] Restarting PM2 services"
"${ssh_cmd[@]}" "cd '${REMOTE_DIR}' && chmod +x authServer/start_auth_server.sh gameServer/start_game_server.sh Godot_v4.6.1-stable_linux.x86_64 && pm2 delete authServer >/dev/null 2>&1 || true && pm2 delete gameServer >/dev/null 2>&1 || true && pm2 start ecosystem.config.cjs --env '${PM2_ENV}' && pm2 save"
echo "[3/4] PM2 services updated"

echo "[4/4] Deployment complete"
