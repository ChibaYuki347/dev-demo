#!/usr/bin/env bash
# validate-bicep.sh — syntax-only validation (az bicep build).
# Tenant-aware checks (what-if) require credentials and are out of scope.
set -euo pipefail
cd "$(dirname "$0")/.."

OUT=/tmp/dev-demo-main.compiled.json

if ! command -v az >/dev/null; then
  echo "ERROR: az CLI not found. Install: https://learn.microsoft.com/cli/azure/install-azure-cli"
  exit 1
fi

az bicep build --file infra/bicep/main.bicep --outfile "$OUT"
echo "✅ Bicep built → $(wc -c < "$OUT") bytes of ARM JSON at $OUT"
