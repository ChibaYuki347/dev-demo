#!/usr/bin/env bash
# start-frontend.sh — start the Vite dev server (used outside Playwright).
set -euo pipefail
cd "$(dirname "$0")/../app/frontend"
[ -d node_modules ] || npm ci
npm run dev
