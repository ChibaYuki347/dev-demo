# ⑤ Azure CD (Functions + Service Bus + OIDC)

> 🇯🇵 Japanese version: [`docs/ja/05-azure-cd.md`](../ja/05-azure-cd.md)

## What this demo proves

1. The **OIDC + Federated Credential** chain — no client secrets stored anywhere
2. **Reusable workflow** (`workflow_call`) + caller (`workflow_dispatch`) so the same deploy logic can be shared across many polyrepos
3. **Managed Identity** Service Bus connection — `ServiceBusConnection__fullyQualifiedNamespace`, never a connection string
4. **Bicep IaC** validates locally with `az bicep build` (no tenant access needed for syntax check)
5. **`disableLocalAuth: true`** on the Service Bus namespace — RBAC-only, SAS keys cannot exist
6. Dry-run by default — clicking "Run workflow" without secrets configured short-circuits cleanly

## Files

| File | Role |
|---|---|
| `infra/bicep/main.bicep` | Subscription-scope orchestrator; creates RG + calls modules |
| `infra/bicep/modules/servicebus.bicep` | Namespace + topic + subscription + optional `Azure Service Bus Data Receiver` role for the GitHub deploy SP |
| `infra/bicep/modules/functionapp.bicep` | Linux Consumption Python Function App with System-Assigned Managed Identity |
| `infra/bicep/modules/sb-role-runtime.bicep` | Grants Service Bus Data Receiver to the Function App's runtime MI |
| `app/functions/function_app.py` | Thin trigger wrapper (delegates to `processing.process_message`) |
| `app/functions/processing.py` | Pure business logic — unit-tested without the Functions host |
| `.github/workflows/deploy-function-app.yml` | Reusable workflow (`workflow_call` only) |
| `.github/workflows/deploy-caller.yml` | Caller (`workflow_dispatch` only, defaults to dry-run) |
| `scripts/setup-oidc.sh` | Reference script to wire up Entra ID app + Federated Credential |

## The OIDC trust chain

See the sequence diagram in [`architecture.md`](architecture.md). Summary:

1. The GitHub Actions runner asks GitHub's OIDC issuer (`token.actions.githubusercontent.com`) for a JWT.
2. The JWT's `sub` claim is `repo:<org>/<repo>:environment:<env>`.
3. `azure/login@v2` swaps the JWT with Microsoft Entra for a real Azure AD token (~1h lifetime).
4. `Azure/functions-action@v1` uses that token to deploy.
5. The deployed Function App's **System-Assigned Managed Identity** is what actually reads messages from Service Bus at runtime — that's a separate identity from the one used for deployment.

This means **no client secrets exist anywhere** — not in GitHub, not in Azure Key Vault, not in env vars.

## Local validation

```bash
# Unit-test the pure business logic (no Functions host needed)
cd app/functions && pip install -r requirements.txt && pytest -q

# Validate Bicep syntax
./scripts/validate-bicep.sh
```

> ⚠️ `az bicep build` only catches **syntax / module resolution / type errors**. It does NOT validate that:
>
> - the resource SKUs are available in the chosen region
> - your subscription has quota
> - the role definitions exist in your tenant
> - the deployment would actually succeed
>
> Those checks require `az deployment sub what-if --location <loc> --template-file ...` against a real subscription, which is intentionally out of scope for this demo's CI.

## Real-deploy enablement

For an operator who wants to make this actually deploy:

1. Run `./scripts/setup-oidc.sh <github-org/repo> development` (and `staging`, `production`).
2. Per the script's instructions, add `AZURE_CLIENT_ID` / `AZURE_TENANT_ID` / `AZURE_SUBSCRIPTION_ID` as **Environment** secrets in GitHub (not repo secrets — environment secrets are scoped to each environment).
3. Assign `Contributor` (or `Website Contributor` at the Function App scope) and `Storage Blob Data Contributor` on the storage account to the SP. (The Function App's runtime MI gets `Service Bus Data Receiver` automatically via `sb-role-runtime.bicep`.)
4. Trigger `deploy-caller.yml` from the Actions tab with `dry_run: false`.

For polyrepo adoption, the `deploy-function-app.yml` reusable workflow can be `uses: <org>/dev-demo/.github/workflows/deploy-function-app.yml@<sha>` from any other repo (after publishing it to a shared `.github` repo or vendoring it).

## Reusable workflow + caller pattern recap

```
shared repo:
  .github/workflows/deploy-function-app.yml     ← (workflow_call, no other trigger)

per-app repo:
  .github/workflows/deploy.yml                  ← (workflow_dispatch + caller)
    └── uses: org/shared/.github/workflows/deploy-function-app.yml@<sha>
```

GitHub-native, no Bash glue. Each app repo's CD becomes a 30-line `deploy.yml` that delegates entirely.

## Anti-patterns called out

| ❌ Don't | ✅ Do |
|---|---|
| `azure/login@v2` with `creds: ${{ secrets.AZURE_CREDENTIALS }}` | OIDC (`client-id` + `tenant-id` + `subscription-id`, no `client-secret`) |
| Service Bus `connection-string` setting | `__fullyQualifiedNamespace` + `__credential: managedidentity` |
| `if: always()` for upload steps | `if: ${{ !cancelled() }}` |
| Deploy on every `push` to `main` | `workflow_dispatch` + Environment Required Reviewers |
| Caller workflow without `permissions: id-token: write` | Caller must grant the same OIDC permission as the called workflow's job, otherwise the workflow fails at startup |
| `Endpoint=sb://...;SharedAccessKey=...` lurking in `local.settings.json` committed by mistake | `local.settings.json` is `.gitignored`; only `local.settings.json.example` is committed |
