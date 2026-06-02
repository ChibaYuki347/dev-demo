# 片付け — デモ後の後始末

> 🇬🇧 English version: [`docs/en/99-teardown.md`](../en/99-teardown.md)
>
> End-to-end デモは実 Azure + Entra ID + ADO のリソースをプロビジョニングした。
> このページは課金やアクセスの残留を防ぐため、すべてを削除するコマンドを列挙する。

## 何ができたか — クイックチェック

| レイヤ | 内容 | 場所 |
|---|---|---|
| GitHub リポ | `ChibaYuki347/dev-demo` (public) | https://github.com/ChibaYuki347/dev-demo |
| GitHub Environment | `development` (Environment secrets 3 つ付き) | リポ Settings → Environments |
| GitHub リポ secrets | `ENTRA_APP_CLIENT_ID`, `ENTRA_APP_TENANT_ID`, `GH_PERSONAL_ACCESS_TOKEN` | リポ Settings → Secrets |
| GitHub リポ variables | `ADO_ORGANIZATION`, `ADO_PROJECT` | リポ Settings → Variables |
| Entra ID app | `github-dev-demo-development` (Federated Credentials 2 つ付き) | Entra ID → App registrations |
| Azure RBAC | SP に `Contributor`, `User Access Administrator`, `Storage Blob Data Contributor` | サブスクリプション・ストレージスコープ |
| Azure リソース | リソースグループ `devdemo-rg-dev` (Service Bus, Function App, Storage, Plan, ロール割り当て) | Azure ポータル → `devdemo-rg-dev` |
| Azure DevOps | SmartHotelDemo の Work Item #340 + SP を Contributors として追加 | `https://dev.azure.com/contosodemo42425/SmartHotelDemo` |

## 片付けコマンド (推奨順)

### 1. Azure リソースグループ — 課金の最大要因

```bash
az group delete --name devdemo-rg-dev --yes --no-wait
```

これで Service Bus, Function App, Storage, Plan, RG スコープの全ロール割り当て、テレメトリーがまとめて消える。

### 2. SP に付与したサブスクリプションスコープのロール

```bash
SP_OBJ_ID="6b742665-c316-4769-8454-60e432eb3dec"   # github-dev-demo-development
SUB_ID="68575d55-f60d-4d89-a32b-ad90af38faa6"

az role assignment list --assignee "$SP_OBJ_ID" --scope "/subscriptions/$SUB_ID" \
  --query '[].{role:roleDefinitionName, scope:scope, id:id}' -o table
# 削除
az role assignment delete --assignee "$SP_OBJ_ID" --scope "/subscriptions/$SUB_ID" \
  --role "Contributor"
az role assignment delete --assignee "$SP_OBJ_ID" --scope "/subscriptions/$SUB_ID" \
  --role "User Access Administrator"
```

### 3. 自分のユーザーに付与した Service Bus Data Sender

```bash
MY_OID=$(az ad signed-in-user show --query id -o tsv)
# RG を先に消していればスコープごと無くなる。コスメティック対応。
echo "Sender role at namespace scope was removed with the RG."
```

### 4. Entra ID app + Federated Credentials

```bash
APP_ID="1083012f-7c5d-4400-b9fa-edeca36df98b"
az ad app delete --id "$APP_ID"
```

これで App Registration、Federated Credentials 2 つ、Service Principal がまとめて消える。

### 5. Azure DevOps — SP ユーザー削除

```bash
ADO_TOKEN=$(az account get-access-token --resource 499b84ac-1321-427f-aa17-267ca6975798 --query accessToken -o tsv)
SP_ENTITLEMENT_ID="8cc62fd2-8458-662c-8f1a-cc0601368db8"   # add-user 応答に含まれた ID

curl -sS -X DELETE \
  -H "Authorization: Bearer $ADO_TOKEN" \
  "https://vsaex.dev.azure.com/contosodemo42425/_apis/serviceprincipalentitlements/${SP_ENTITLEMENT_ID}?api-version=7.1-preview.1"
```

その後 ADO ポータルで: SmartHotelDemo → Boards → Work Items → Work Item #340 (デモ用 PBI) を削除。

### 6. GitHub — secrets, variables, environment, labels, issue

```bash
REPO="ChibaYuki347/dev-demo"

# Environment secrets と Environment 自体
gh api --method DELETE "repos/$REPO/environments/development"

# リポ secrets
gh secret delete ENTRA_APP_CLIENT_ID       --repo "$REPO"
gh secret delete ENTRA_APP_TENANT_ID       --repo "$REPO"
gh secret delete GH_PERSONAL_ACCESS_TOKEN  --repo "$REPO"

# リポ variables
gh variable delete ADO_ORGANIZATION --repo "$REPO"
gh variable delete ADO_PROJECT      --repo "$REPO"

# (任意) 追加したラベル
gh label delete user-story      --repo "$REPO" --yes
gh label delete spec-driven     --repo "$REPO" --yes
gh label delete sync-requested  --repo "$REPO" --yes

# (任意) テスト用 issue
gh issue close 10 --repo "$REPO" --reason "not planned"
```

### 7. GitHub リポ自体 (リポごと消したい場合)

```bash
# これは取り返しがつかない。トークンに 'delete_repo' スコープが必要。
gh repo delete ChibaYuki347/dev-demo --yes
```

## `GH_PERSONAL_ACCESS_TOKEN` として保存した PAT の rotate

デモでは現在の `gh` セッショントークンを流用した。ベストプラクティスとして **デモ後に必ず rotate** する:

1. https://github.com/settings/tokens → `gh auth token | shasum` のハッシュと一致するトークンを revoke。
2. 新しいトークンを発行し、ローカル `gh` を `gh auth refresh` で更新。

## 検証 — 何も残っていないか確認

```bash
az group exists --name devdemo-rg-dev               # → false
az ad app show --id 1083012f-7c5d-4400-b9fa-edeca36df98b 2>&1 | head -2   # → "Resource ... not found"
gh secret list --env development --repo ChibaYuki347/dev-demo 2>&1        # → 404 (env 削除済)
```
