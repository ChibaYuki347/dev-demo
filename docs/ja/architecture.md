# アーキテクチャ

> 🇬🇧 English version: [`docs/en/architecture.md`](../en/architecture.md)

## End-to-end フロー

> このフローは 5 領域を 1 本につなぐ: PdM が仕様を書く → AI がコンテキストファイルを参照しつつ実装 → CI で Playwright E2E → OIDC で Azure に deploy → `AB#` で Work Item クローズ。

```mermaid
flowchart TB
    PdM[👤 PdM<br/>Azure Boards Work Item<br/>受け入れ基準<br/>Given/When/Then]
    GH[GitHub Issue<br/>テンプレートから作成<br/>AB#XXX を含む]
    SPEC[specs/NNN-feature/<br/>spec.md / plan.md / tasks.md]
    INST[".github/copilot-instructions.md<br/>+ AGENTS.md<br/>+ .github/instructions/*"]
    CA[Copilot Coding Agent<br/>または ローカル Copilot Chat]
    MCPpw[Playwright MCP<br/>browser_snapshot<br/>browser_generate_locator]
    REPO[(リポジトリ<br/>コード + テスト + ワークフロー)]
    CI[GitHub Actions<br/>ci.yml + playwright.yml]
    PRC[PR コメント・Job Summary<br/>HTML レポート artifact]
    OIDC[Federated Credential<br/>repo:org/repo:environment:&lt;env&gt;]
    AZ[Azure<br/>Functions + Service Bus<br/>Managed Identity]
    DONE[Work Item Done<br/>fixes AB#XXX 経由]

    PdM --> GH
    PdM --> SPEC
    SPEC --> CA
    INST --> CA
    GH --> CA
    CA <--> MCPpw
    CA --> REPO
    REPO --> CI
    CI --> PRC
    CI -.->|workflow_dispatch のみ| OIDC
    OIDC -.-> AZ
    REPO -->|merge fixes AB#| DONE
```

## リポジトリ構成

```
dev-demo/
├── README.md (英語) + README.ja.md (日本語)
├── AGENTS.md
├── LICENSE, CODEOWNERS, .editorconfig, .gitignore
├── .github/
│   ├── copilot-instructions.md          # 領域 ④
│   ├── instructions/                    # パス指定の上書き
│   ├── ISSUE_TEMPLATE/user-story.yml    # 領域 ③
│   ├── dependabot.yml, pull_request_template.md
│   └── workflows/
│       ├── ci.yml                       # 常時グリーン: pytest + bicep build
│       ├── playwright.yml               # 領域 ① シャード + merge-reports
│       ├── deploy-function-app.yml      # 領域 ⑤ reusable (workflow_call のみ)
│       ├── deploy-caller.yml            # 領域 ⑤ caller (workflow_dispatch + dry-run 既定)
│       └── sync-issues-to-ado.yml       # 領域 ③ Boards 同期 (on: issues:)
├── .vscode/
│   ├── mcp.json                         # 領域 ② Playwright + GitHub MCP
│   └── settings.json
├── specs/001-login-feature/             # 領域 ③ spec-kit 成果物
│   ├── spec.md (Gherkin)
│   ├── plan.md
│   └── tasks.md
├── app/
│   ├── frontend/                        # 領域 ① Vite + vanilla TS の対象アプリ
│   │   ├── src/{main.ts, auth.ts, style.css}
│   │   ├── tests/e2e/{login,dashboard}.spec.ts
│   │   └── playwright.config.ts (webServer: 付き)
│   └── functions/                       # 領域 ⑤ Python Functions v2
│       ├── function_app.py (薄いラッパー)
│       ├── processing.py (pure ロジック)
│       └── tests/test_processing.py
├── infra/bicep/                         # 領域 ⑤ IaC
│   ├── main.bicep
│   └── modules/{servicebus, functionapp, sb-role-runtime}.bicep
├── scripts/                             # setup-oidc, run-playwright, validate-bicep, …
└── docs/
    ├── en/  (各章 + ツアー台本の英語版)
    └── ja/  (同じ内容の日本語版)
```

## 領域 ↔ ファイル対応

| 領域 | 主要ファイル |
|---|---|
| ① Playwright E2E | `app/frontend/playwright.config.ts`, `tests/e2e/*.spec.ts`, `.github/workflows/playwright.yml` |
| ② MCP テスト保守 | `.vscode/mcp.json`, `docs/ja/02-mcp-test-maintenance.md` |
| ③ Boards × spec-kit | `specs/001-login-feature/*`, `.github/ISSUE_TEMPLATE/user-story.yml`, `.github/workflows/sync-issues-to-ado.yml` |
| ④ AI コンテキスト | `.github/copilot-instructions.md`, `AGENTS.md`, `.github/instructions/*.instructions.md` |
| ⑤ Azure CD | `infra/bicep/*.bicep`, `.github/workflows/deploy-{function-app,caller}.yml`, `scripts/setup-oidc.sh`, `app/functions/*` |

## 領域 ⑤ — OIDC 信頼関係の詳細

```mermaid
sequenceDiagram
    participant GH as GitHub Actions ランナー
    participant GHJWT as GitHub OIDC issuer<br/>token.actions.githubusercontent.com
    participant Entra as Microsoft Entra ID<br/>App Registration + Federated Credential
    participant Az as Azure (Function App + Service Bus)

    GH->>GHJWT: OIDC トークンを要求<br/>(audience: api://AzureADTokenExchange)
    GHJWT-->>GH: 署名済 JWT<br/>(sub: repo:org/repo:environment:dev)
    GH->>Entra: azure/login@v2 が JWT を交換
    Entra-->>GH: 短命の Azure AD トークン (~1h)
    GH->>Az: Azure/functions-action@v1 経由でパッケージをデプロイ
    Az->>Az: Function host は System-Assigned Managed Identity を使って<br/>Service Bus を読む (接続文字列なし)
```
