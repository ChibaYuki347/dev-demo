# dev-demo

> 5 つのエンジニアリングパターンを 1 つの monorepo にまとめて見せる **30 分ウォークスルー**:
>
> 1. シャード化 GitHub Actions + マージレポートによる **Playwright E2E**
> 2. 継続的テスト保守のための **Playwright MCP**
> 3. 仕様駆動開発のための **Azure DevOps Boards × GitHub Issues × spec-kit**
> 4. **AI コンテキストファイル** (`.github/copilot-instructions.md`, `AGENTS.md`, パス指定オーバーライド)
> 5. Functions + Service Bus + OIDC + Managed Identity の **Azure CD** (既定 dry-run)
>
> 🇬🇧 English version: [`README.md`](README.md)

[![CI](../../actions/workflows/ci.yml/badge.svg)](../../actions/workflows/ci.yml)
[![Playwright E2E](../../actions/workflows/playwright.yml/badge.svg)](../../actions/workflows/playwright.yml)

## デモの見所

```
PdM が Azure Boards に受け入れ基準 (Gherkin) を書く
   ↓ AB#1234 → GitHub Issue
   ↓
Copilot Coding Agent は次を読む:
  - Work Item (= 仕様)
  - .github/copilot-instructions.md + AGENTS.md (= 規約)
  - specs/001-login-feature/spec.md (= 契約)
   ↓ AC-NNN と 1:1 対応する実装コード + Playwright E2E を生成
   ↓
push → GitHub Actions
  - ci.yml         (pytest + bicep build、常時グリーン)
  - playwright.yml (シャード → マージ HTML レポート)
   ↓
PR を "Fixes AB#1234" でマージ → Work Item が Done
   ↓
deploy-caller.yml (手動、既定 dry-run)
  - Federated Credential 経由の OIDC、クライアントシークレット無し
  - Azure/functions-action@v1
  - Service Bus は Managed Identity 接続 (接続文字列無し)
```

## 領域 ↔ ファイル対応

| 領域 | 最初に開く |
|---|---|
| ① Playwright E2E | [`docs/ja/01-playwright-e2e.md`](docs/ja/01-playwright-e2e.md) → `./scripts/run-playwright.sh` |
| ② MCP テスト保守 | [`docs/ja/02-mcp-test-maintenance.md`](docs/ja/02-mcp-test-maintenance.md) → `.vscode/mcp.json` |
| ③ 仕様駆動開発 | [`docs/ja/03-spec-driven-dev.md`](docs/ja/03-spec-driven-dev.md) → [`specs/001-login-feature/spec.md`](specs/001-login-feature/spec.md) |
| ④ AI コンテキスト | [`docs/ja/04-ai-context.md`](docs/ja/04-ai-context.md) → [`.github/copilot-instructions.md`](.github/copilot-instructions.md) |
| ⑤ Azure CD | [`docs/ja/05-azure-cd.md`](docs/ja/05-azure-cd.md) → `./scripts/validate-bicep.sh` |
| 🎯 30 分ツアー | [`docs/ja/00-tour-30min.md`](docs/ja/00-tour-30min.md) |
| 🧹 片付け | [`docs/ja/99-teardown.md`](docs/ja/99-teardown.md) |

全体像は [`docs/ja/architecture.md`](docs/ja/architecture.md) の Mermaid 図を参照。

## クイックスタート

### 前提環境

| ツール | 検証済みバージョン | 用途 |
|---|---|---|
| Node.js | 22.x | Frontend + Playwright |
| Python | 3.11+ | Azure Functions 単体テスト |
| Azure CLI (`az`) | 2.60+ | Bicep 検証 (`./scripts/validate-bicep.sh`) |
| Docker (任意) | 任意 | `./scripts/lint-workflows.sh` 経由の `actionlint` |
| `func` (Azure Functions Core Tools) | — | デモには **不要** — ハンドラロジックは直接単体テスト可能 |

### Playwright デモを動かす

```bash
./scripts/run-playwright.sh
```

これで領域 ① のデモは全部 — `playwright.config.ts` の `webServer:` が Vite を起動し、4 テスト実行、片付けまで自動。

### Python 単体テストを動かす

```bash
cd app/functions
pip install -r requirements.txt
pytest
```

### Bicep を検証する

```bash
./scripts/validate-bicep.sh   # 構文のみ。Azure テナント不要
```

### dry-run デプロイワークフローを試す

リポジトリを GitHub に push して、**Actions** タブから **"Deploy Function App (manual)"** を手動トリガー。既定 `dry_run: true` で、preflight ジョブが「何が起きるはず」を Job Summary に書き、Azure に触れずクリーンに終了する。

## このデモに含まれないもの

- 実 Azure リソースの作成 (`setup-oidc.sh` スクリプトは参考用)。
- 実 Azure DevOps 連携 (`sync-issues-to-ado.yml` は `ENTRA_APP_CLIENT_ID` でゲート)。
- Salesforce CD / Power Platform CD / ETL 移行プレイブック (調査レポートでカバー済み; 30 分に収めるためあえて除外)。
- プロダクション品質のフロントエンド (パターンに焦点を当てるため意図的に最小限の vanilla TS アプリ)。

## リポジトリ構成

詳細は [`docs/ja/architecture.md`](docs/ja/architecture.md#リポジトリ構成) を参照:

```
.
├── README.md          ← 英語版
├── README.ja.md       ← ここ (日本語)
├── AGENTS.md          ← Copilot 以外のエージェント向け AI コンテキスト
├── .github/
│   ├── copilot-instructions.md
│   ├── instructions/*.instructions.md
│   ├── ISSUE_TEMPLATE/user-story.yml
│   ├── workflows/{ci,playwright,deploy-function-app,deploy-caller,sync-issues-to-ado}.yml
│   ├── dependabot.yml
│   └── pull_request_template.md
├── .vscode/{mcp.json,settings.json}
├── specs/001-login-feature/{spec,plan,tasks}.md
├── app/
│   ├── frontend/   (Vite + vanilla TS, Playwright E2E)
│   └── functions/  (Python Azure Functions v2 モデル)
├── infra/bicep/{main,modules/*}.bicep
├── scripts/{run-playwright,validate-bicep,setup-oidc,start-frontend,lint-workflows}.sh
└── docs/
    ├── en/{00-tour-30min,01..05,architecture,99-teardown}.md   ← 英語版
    └── ja/(同じ内容の日本語版)
```

## ドキュメント規約

- すべてのナラティブ文書は **英語版と日本語版を別ファイル**に分けている (`docs/en/` と `docs/ja/`); 各ファイルの冒頭で互いにクロスリンクする。
- `README.md` と `README.ja.md` は内容を相互に対応させる。
- AI コンテキストファイル (`.github/copilot-instructions.md`, `AGENTS.md`, `.github/instructions/*.instructions.md`) は **英語のみ** — 読み手は AI ツールであり、ツアー中の人間ではないため。

## ライセンス

MIT — [LICENSE](LICENSE) を参照。
