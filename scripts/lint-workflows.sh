#!/usr/bin/env bash
# lint-workflows.sh — actionlint via Docker (no global install required).
set -euo pipefail
cd "$(dirname "$0")/.."

if ! command -v docker >/dev/null; then
  echo "ERROR: docker not found. Install Docker or run actionlint another way."
  exit 1
fi

docker run --rm -v "$(pwd)":/repo -w /repo \
  rhysd/actionlint:latest -color
