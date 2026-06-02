# Tear-down — how to clean up after the demo

> 🇯🇵 Japanese version: [`docs/ja/99-teardown.md`](../ja/99-teardown.md)
>
> The end-to-end demo provisioned real Azure + Entra ID + ADO resources.
> This page lists every command to remove them so nothing keeps billing or leaking access.

## Quick check — what was created

| Layer | What | Where |
|---|---|---|
| GitHub repo | `ChibaYuki347/dev-demo` (public) | https://github.com/ChibaYuki347/dev-demo |
| GitHub Environment | `development` (with 3 Environment secrets) | repo Settings → Environments |
| GitHub repo secrets | `ENTRA_APP_CLIENT_ID`, `ENTRA_APP_TENANT_ID`, `GH_PERSONAL_ACCESS_TOKEN` | repo Settings → Secrets |
| GitHub repo variables | `ADO_ORGANIZATION`, `ADO_PROJECT` | repo Settings → Variables |
| Entra ID app | `github-dev-demo-development` (with 2 Federated Credentials) | Entra ID → App registrations |
| Azure RBAC | `Contributor`, `User Access Administrator`, `Storage Blob Data Contributor` on the SP | Subscription and Storage scope |
| Azure resources | Resource group `devdemo-rg-dev` (Service Bus, Function App, Storage, Plan, Role assignments) | Azure portal → `devdemo-rg-dev` |
| Azure DevOps | Work Item #340 in SmartHotelDemo + SP added as ADO user with Contributors | `https://dev.azure.com/contosodemo42425/SmartHotelDemo` |

## Tear-down commands (ordered)

### 1. Azure resource group — biggest billing item

```bash
az group delete --name devdemo-rg-dev --yes --no-wait
```

This removes Service Bus, Function App, Storage, Plan, all role assignments scoped to the RG, and their telemetry.

### 2. Azure subscription-scope role assignments on the SP

```bash
SP_OBJ_ID="6b742665-c316-4769-8454-60e432eb3dec"   # github-dev-demo-development
SUB_ID="68575d55-f60d-4d89-a32b-ad90af38faa6"

az role assignment list --assignee "$SP_OBJ_ID" --scope "/subscriptions/$SUB_ID" \
  --query '[].{role:roleDefinitionName, scope:scope, id:id}' -o table
# Remove them
az role assignment delete --assignee "$SP_OBJ_ID" --scope "/subscriptions/$SUB_ID" \
  --role "Contributor"
az role assignment delete --assignee "$SP_OBJ_ID" --scope "/subscriptions/$SUB_ID" \
  --role "User Access Administrator"
```

### 3. Service Bus Data Sender granted to your interactive user

```bash
MY_OID=$(az ad signed-in-user show --query id -o tsv)
# Scope is gone if you've already deleted the RG; this is mostly cosmetic.
echo "Sender role at namespace scope was removed with the RG."
```

### 4. Entra ID app + Federated Credentials

```bash
APP_ID="1083012f-7c5d-4400-b9fa-edeca36df98b"
az ad app delete --id "$APP_ID"
```

This removes the App Registration AND both Federated Credentials AND the Service Principal.

### 5. Azure DevOps — remove the SP user

```bash
ADO_TOKEN=$(az account get-access-token --resource 499b84ac-1321-427f-aa17-267ca6975798 --query accessToken -o tsv)
SP_ENTITLEMENT_ID="8cc62fd2-8458-662c-8f1a-cc0601368db8"   # from the add-user response

curl -sS -X DELETE \
  -H "Authorization: Bearer $ADO_TOKEN" \
  "https://vsaex.dev.azure.com/contosodemo42425/_apis/serviceprincipalentitlements/${SP_ENTITLEMENT_ID}?api-version=7.1-preview.1"
```

Then in the ADO portal: SmartHotelDemo → Boards → Work Items → delete Work Item #340 (the demo PBI).

### 6. GitHub — secrets, variables, environment, labels, issue

```bash
REPO="ChibaYuki347/dev-demo"

# Environment secrets + the Environment itself
gh api --method DELETE "repos/$REPO/environments/development"

# Repo secrets
gh secret delete ENTRA_APP_CLIENT_ID       --repo "$REPO"
gh secret delete ENTRA_APP_TENANT_ID       --repo "$REPO"
gh secret delete GH_PERSONAL_ACCESS_TOKEN  --repo "$REPO"

# Repo variables
gh variable delete ADO_ORGANIZATION --repo "$REPO"
gh variable delete ADO_PROJECT      --repo "$REPO"

# (Optional) Labels we added
gh label delete user-story      --repo "$REPO" --yes
gh label delete spec-driven     --repo "$REPO" --yes
gh label delete sync-requested  --repo "$REPO" --yes

# (Optional) The test issue
gh issue close 10 --repo "$REPO" --reason "not planned"
```

### 7. GitHub repo itself (only if you want to delete the whole thing)

```bash
# This is irreversible. Requires the 'delete_repo' scope on the token.
gh repo delete ChibaYuki347/dev-demo --yes
```

## Rotate the PAT stored as `GH_PERSONAL_ACCESS_TOKEN`

The demo reused the current `gh` session's token. Best practice is to **rotate it after the demo**:

1. https://github.com/settings/tokens → revoke the token whose hash matches `gh auth token | shasum`.
2. Issue a new one and update local `gh` with `gh auth refresh`.

## Verification — confirm nothing was left behind

```bash
az group exists --name devdemo-rg-dev               # → false
az ad app show --id 1083012f-7c5d-4400-b9fa-edeca36df98b 2>&1 | head -2   # → "Resource ... not found"
gh secret list --env development --repo ChibaYuki347/dev-demo 2>&1        # → 404 (env removed)
```
