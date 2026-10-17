#!/bin/zsh
# Scope mirror cleanup to the simulator used by this terminal.
set -eu
SIMULATOR_ID="${1:?Usage: serve_sim.sh <simulator-udid>}"
export npm_config_cache="${TMPDIR:-/private/tmp}/stocks-six-npm-cache"
cleanup_serve_sim() {
  npx --yes serve-sim@latest --kill "$SIMULATOR_ID" >/dev/null 2>&1 || true
}
trap cleanup_serve_sim EXIT INT TERM HUP
cleanup_serve_sim
npx --yes serve-sim@latest "$SIMULATOR_ID"
