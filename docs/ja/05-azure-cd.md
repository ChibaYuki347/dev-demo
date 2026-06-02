# ⑤ Azure CD (Functions + Service Bus + OIDC)

> 🇬🇧 English version: [`docs/en/05-azure-cd.md`](../en/05-azure-cd.md)

## このデモで証明する内容

1. **OIDC + Federated Credential** チェーン — クライアントシークレットを一切保存しない
2. **Reusable workflow** (`workflow_call`) + caller (`workflow_dispatch`) によって、同じデプロイロジックを多数の polyrepo で共有できる
3. **Managed Identity** での Service Bus 接続 — `ServiceBusConnection__fullyQualifiedNamespace`、接続文字列は決して使わない
4. **Bicep IaC** をローカル `az bicep build` で検証 (構文チェックにテナントアクセス不要)
5. Service Bus namespace の **`disableLocalAuth: true`** — RBAC 専用、SAS キーが存在し得ない
6. 既定 dry-run — 秘密情報未設定で "Run workflow" を押しても綺麗に short-circuit

## ファイル

| ファイル | 役割 |
|---|---|
| `infra/bicep/main.bicep` | サブスクリプションスコープのオーケストレータ; RG を作って各モジュールを呼ぶ |
| `infra/bicep/modules/servicebus.bicep` | Namespace + topic + subscription + 任意で `Azure Service Bus Data Receiver` を GitHub デプロイ SP に付与 |
| `infra/bicep/modules/functionapp.bicep` | Linux Consumption Python Function App + System-Assigned Managed Identity |
| `infra/bicep/modules/sb-role-runtime.bicep` | Function App ランタイム MI に Service Bus Data Receiver を付与 |
| `app/functions/function_app.py` | 薄いトリガーラッパー (`processing.process_message` に委譲) |
| `app/functions/processing.py` | Pure なビジネスロジック — Functions host なしで単体テスト可 |
| `.github/workflows/deploy-function-app.yml` | Reusable workflow (`workflow_call` のみ) |
| `.github/workflows/deploy-caller.yml` | Caller (`workflow_dispatch` のみ、既定 dry-run) |
| `scripts/setup-oidc.sh` | Entra ID app + Federated Credential 配線のための参考スクリプト |

## OIDC 信頼関係

[`architecture.md`](architecture.md) のシーケンス図を参照。要約:

1. GitHub Actions ランナーが GitHub OIDC issuer (`token.actions.githubusercontent.com`) から JWT を要求。
2. JWT の `sub` クレームは `repo:<org>/<repo>:environment:<env>`。
3. `azure/login@v2` が JWT を Microsoft Entra と交換し、実 Azure AD トークン (~1h 寿命) を得る。
4. `Azure/functions-action@v1` がそのトークンでデプロイ。
5. デプロイされた Function App の **System-Assigned Managed Identity** が、ランタイムで Service Bus メッセージを実際に読む — これはデプロイで使う ID とは別の ID。

つまり **クライアントシークレットはどこにも存在しない** — GitHub にも Azure Key Vault にも環境変数にも。

## ローカル検証

```bash
# Pure ビジネスロジックの単体テスト (Functions host 不要)
cd app/functions && pip install -r requirements.txt && pytest -q

# Bicep 構文検証
./scripts/validate-bicep.sh
```

> ⚠️ `az bicep build` は **構文 / モジュール解決 / 型エラー** しか検出しない。以下は検証しない:
>
> - 選択リージョンで SKU が利用可能か
> - サブスクリプションにクォータが残っているか
> - そのロール定義がテナントに存在するか
> - 実際にデプロイが成功するか
>
> これらのチェックには実サブスクリプションへの `az deployment sub what-if --location <loc> --template-file ...` が必要で、このデモの CI ではあえてスコープ外にしている。

## 実デプロイを有効化する手順

実デプロイしたい運用者向け:

1. `./scripts/setup-oidc.sh <github-org/repo> development` (および `staging`, `production`) を実行。
2. スクリプトの指示通り、`AZURE_CLIENT_ID` / `AZURE_TENANT_ID` / `AZURE_SUBSCRIPTION_ID` を GitHub の **Environment** secrets として追加 (repo secrets ではない — environment secrets は環境ごとにスコープされる)。
3. SP に `Contributor` (または Function App スコープの `Website Contributor`) と storage account 上の `Storage Blob Data Contributor` を付与。(Function App ランタイム MI は `sb-role-runtime.bicep` が `Service Bus Data Receiver` を自動付与する。)
4. Actions タブから `deploy-caller.yml` を `dry_run: false` でトリガー。

Polyrepo 採用時は、`deploy-function-app.yml` reusable workflow を他リポから `uses: <org>/dev-demo/.github/workflows/deploy-function-app.yml@<sha>` で呼べる (共有 `.github` リポに発行するか vendoring した後)。

## Reusable workflow + caller パターンのまとめ

```
共有リポ:
  .github/workflows/deploy-function-app.yml     ← (workflow_call、他にトリガー無し)

各アプリリポ:
  .github/workflows/deploy.yml                  ← (workflow_dispatch + caller)
    └── uses: org/shared/.github/workflows/deploy-function-app.yml@<sha>
```

GitHub ネイティブ、bash 接着剤なし。各アプリリポの CD は委譲だけの 30 行 `deploy.yml` になる。

## アンチパターン

| ❌ ダメ | ✅ 推奨 |
|---|---|
| `azure/login@v2` を `creds: ${{ secrets.AZURE_CREDENTIALS }}` で使う | OIDC (`client-id` + `tenant-id` + `subscription-id`、`client-secret` なし) |
| Service Bus の `connection-string` 設定 | `__fullyQualifiedNamespace` + `__credential: managedidentity` |
| アップロードステップに `if: always()` | `if: ${{ !cancelled() }}` |
| `main` への全 push でデプロイ | `workflow_dispatch` + Environment Required Reviewers |
| Caller workflow に `permissions: id-token: write` 無し | Caller も called workflow と同じ OIDC 権限を job-level で付与する必要あり (無いと startup_failure) |
| 誤って commit した `local.settings.json` に `Endpoint=sb://...;SharedAccessKey=...` | `local.settings.json` は `.gitignore` 済み; `local.settings.json.example` のみ commit |
