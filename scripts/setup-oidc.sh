#!/usr/bin/env bash
# setup-oidc.sh — REFERENCE script. Do NOT run during the demo.
# Creates an Entra ID app registration + service principal + federated credentials
# for the GitHub → Azure OIDC flow described in docs/en/05-azure-cd.md (日本語版: docs/ja/05-azure-cd.md).
#
# Usage: ./scripts/setup-oidc.sh <github-org/repo> <env-name>

set -euo pipefail

REPO="${1:?Usage: $0 <github-org/repo> <env-name>}"
ENV_NAME="${2:?Usage: $0 <github-org/repo> <env-name>}"

APP_NAME="github-dev-demo-${ENV_NAME}"

echo "→ Creating Entra ID app: ${APP_NAME}"
APP_ID=$(az ad app create --display-name "${APP_NAME}" --query appId -o tsv)

echo "→ Creating service principal"
SP_OBJ_ID=$(az ad sp create --id "${APP_ID}" --query id -o tsv)

TENANT_ID=$(az account show --query tenantId -o tsv)
SUB_ID=$(az account show --query id -o tsv)

echo "→ Creating Federated Credential (subject: repo:${REPO}:environment:${ENV_NAME})"
cat > /tmp/credential.json <<EOF
{
    "name": "${APP_NAME}",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:${REPO}:environment:${ENV_NAME}",
    "description": "GitHub Actions OIDC for ${REPO} (${ENV_NAME})",
    "audiences": ["api://AzureADTokenExchange"]
}
EOF
az ad app federated-credential create --id "${APP_ID}" --parameters /tmp/credential.json

cat <<EOF

✅ Setup complete. Add these as GitHub Environment secrets for '${ENV_NAME}':

  AZURE_CLIENT_ID       = ${APP_ID}
  AZURE_TENANT_ID       = ${TENANT_ID}
  AZURE_SUBSCRIPTION_ID = ${SUB_ID}

Then assign RBAC roles, e.g.:

  az role assignment create --role 'Website Contributor' \\
    --assignee ${SP_OBJ_ID} --scope <function-app-resource-id>

  az role assignment create --role 'Azure Service Bus Data Receiver' \\
    --assignee ${SP_OBJ_ID} --scope <service-bus-namespace-resource-id>

EOF
