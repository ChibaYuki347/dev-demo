# dev-demo

> A **30-minute walk-through** demonstrating five engineering patterns from the [research report](../investigation/) wired together in one monorepo:
>
> 1. **Playwright E2E** with sharded GitHub Actions + merged reports
> 2. **Playwright MCP** for continuous test maintenance
> 3. **Azure DevOps Boards × GitHub Issues × spec-kit** for spec-driven development
> 4. **AI context files** (`.github/copilot-instructions.md`, `AGENTS.md`, path-scoped overrides)
> 5. **Azure CD** for Functions + Service Bus + OIDC + Managed Identity (dry-run-by-default)
>
> 5 つの領域を 1 つの monorepo にまとめた、開発リーダー向け 30 分デモ。

[![CI](../../actions/workflows/ci.yml/badge.svg)](../../actions/workflows/ci.yml)
[![Playwright E2E](../../actions/workflows/playwright.yml/badge.svg)](../../actions/workflows/playwright.yml)

## Demo at a glance / デモの見所

```
PdM writes Acceptance Criteria (Gherkin) in Azure Boards
   ↓ AB#1234 → GitHub Issue
   ↓
Copilot Coding Agent reads:
  - the Work Item (the spec)
  - .github/copilot-instructions.md + AGENTS.md (the conventions)
  - specs/001-login-feature/spec.md (the contract)
   ↓ implements code + Playwright E2E mapped 1:1 to AC-NNN
   ↓
Push → GitHub Actions
  - ci.yml         (pytest + bicep build, always green)
  - playwright.yml (sharded → merged HTML report)
   ↓
PR merged "Fixes AB#1234" → Work Item Done
   ↓
deploy-caller.yml (manual, dry-run by default)
  - OIDC via Federated Credential, no client secret
  - Azure/functions-action@v1
  - Service Bus uses Managed Identity (no connection string)
```

## Topic ↔ file map / 領域別ファイル

| Topic | Try this first |
|---|---|
| ① Playwright E2E | [`docs/01-playwright-e2e.md`](docs/01-playwright-e2e.md) → `./scripts/run-playwright.sh` |
| ② MCP test maintenance | [`docs/02-mcp-test-maintenance.md`](docs/02-mcp-test-maintenance.md) → `.vscode/mcp.json` |
| ③ Spec-driven dev | [`docs/03-spec-driven-dev.md`](docs/03-spec-driven-dev.md) → [`specs/001-login-feature/spec.md`](specs/001-login-feature/spec.md) |
| ④ AI context | [`docs/04-ai-context.md`](docs/04-ai-context.md) → [`.github/copilot-instructions.md`](.github/copilot-instructions.md) |
| ⑤ Azure CD | [`docs/05-azure-cd.md`](docs/05-azure-cd.md) → `./scripts/validate-bicep.sh` |
| 🎯 30-min tour | [`docs/00-tour-30min.md`](docs/00-tour-30min.md) |

For the big picture, open [`docs/architecture.md`](docs/architecture.md) (Mermaid diagrams).

## Quick start / クイックスタート

### Prerequisites / 前提

| Tool | Tested version | Required for |
|---|---|---|
| Node.js | 22.x | Frontend + Playwright |
| Python | 3.11+ | Azure Functions unit tests |
| Azure CLI (`az`) | 2.60+ | Bicep validation (`./scripts/validate-bicep.sh`) |
| Docker (optional) | any | `actionlint` via `./scripts/lint-workflows.sh` |
| `func` (Azure Functions Core Tools) | — | **NOT required** for the demo — handler logic is unit-tested directly |

### Run the Playwright demo / Playwright デモ実行

```bash
./scripts/run-playwright.sh
```

That's the entire demo for Topic ① — `webServer:` in `playwright.config.ts` starts Vite, runs the 4 tests, and tears down cleanly.

### Run the Python unit tests / Python 単体テスト

```bash
cd app/functions
pip install -r requirements.txt
pytest
```

### Validate Bicep / Bicep 検証

```bash
./scripts/validate-bicep.sh   # syntax-only, no Azure tenant needed
```

### Try the dry-run deploy workflow / dry-run デプロイ

Push the repo to GitHub, then from the **Actions** tab manually trigger **"Deploy Function App (manual)"**. With `dry_run: true` (default) the preflight job posts a Job Summary explaining what would happen and exits cleanly without touching Azure.

## What is NOT in this demo / デモに含まれないもの

- Real Azure resource creation (the `setup-oidc.sh` script is reference only).
- Real Azure DevOps integration (the `sync-issues-to-ado.yml` workflow is `workflow_dispatch`-only and gated).
- Salesforce CD / Power Platform CD / ETL migration playbooks (covered in the research report; intentionally out of scope to keep the demo to 30 minutes).
- Production-quality frontend (deliberately a minimal vanilla TS app so the focus stays on the patterns).

## Repository structure / 構成

See [`docs/architecture.md`](docs/architecture.md#repo-layout--リポジトリ構成) for the full tree, or:

```
.
├── README.md                            # you are here
├── AGENTS.md                            # AI context for non-Copilot agents
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
│   └── functions/  (Python Azure Functions v2 model)
├── infra/bicep/{main,modules/*}.bicep
├── scripts/{run-playwright,validate-bicep,setup-oidc,start-frontend,lint-workflows}.sh
└── docs/{00-tour-30min,01..05,architecture}.md
```

## License

MIT — see [LICENSE](LICENSE).
