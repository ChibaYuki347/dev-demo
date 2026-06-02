#!/usr/bin/env bash
# run-playwright.sh — fully self-contained Playwright run.
# `webServer:` in playwright.config.ts starts/stops Vite automatically.
set -euo pipefail
cd "$(dirname "$0")/../app/frontend"
[ -d node_modules ] || npm ci
npx playwright install --with-deps chromium
npx playwright test "$@"
