#!/usr/bin/env bash
# Run first-time OpenClaw setup before gateway:watch. Concurrent setup + watch
# both write dist-runtime (extension symlinks, staged npm deps for Telegram, etc.)
# and cause EEXIST / "npm install failed" races.
set -euo pipefail
cd /app/openclaw

MARKER=/home/openclaw/.openclaw/.docker-initial-setup-done
if [[ ! -f "$MARKER" ]]; then
  echo "[openclaw-docker] First run: pnpm openclaw setup (then starting gateway)..."
  mkdir -p "$(dirname "$MARKER")"
  pnpm openclaw setup
  touch "$MARKER"
fi

exec "$@"
