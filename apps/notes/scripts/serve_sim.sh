#!/usr/bin/env bash
set -euo pipefail

SIM="${1:?Usage: scripts/serve_sim.sh <simulator-udid>}"
export npm_config_cache="${npm_config_cache:-${TMPDIR:-/tmp}/notes-six-npm-cache}"
cleanup_serve_sim() {
  npx --yes serve-sim@latest --kill "$SIM" >/dev/null 2>&1 || true
}
trap cleanup_serve_sim EXIT INT TERM HUP
cleanup_serve_sim
npx --yes serve-sim@latest "$SIM"
