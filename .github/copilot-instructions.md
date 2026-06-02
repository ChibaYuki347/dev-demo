# Copilot Instructions — dev-demo

> Repository-wide instructions for GitHub Copilot (Chat, Coding Agent, CLI).
> Path-scoped overrides live under `.github/instructions/*.instructions.md`.
> Codex / Claude / Cursor read `AGENTS.md` for the same intent.

## Mission

This repository is a **30-minute demo** of how to combine:

1. Playwright E2E with GitHub Actions (sharded + merged reports + PR comments)
2. Playwright MCP for continuous test maintenance
3. Azure DevOps Boards × GitHub Issues × `github/spec-kit` for spec-driven development
4. AI context files (this file, `AGENTS.md`, path-scoped instructions)
5. Azure CD for Azure Functions + Service Bus over OIDC

Demos that walk a client through this repo should match `docs/en/00-tour-30min.md` (Japanese mirror: `docs/ja/00-tour-30min.md`).

## Architecture (one-line per component)

- `app/frontend/` — Vite + vanilla TypeScript app with `/login` and `/dashboard` pages so Playwright has something concrete to drive.
- `app/functions/` — Python Azure Functions v2 model with a Service Bus topic trigger that delegates to a pure `process_message(payload)` function for testability.
- `infra/bicep/` — Subscription-scope Bicep that creates a Service Bus namespace + queue + topic and a Function App with **Managed Identity** (no connection strings).
- `.github/workflows/` — `ci.yml` is always green (no cloud creds). Cloud / ADO workflows are `workflow_dispatch`-only and gated on `vars.AZURE_CLIENT_ID != ''`.
- `specs/` — Hand-crafted `github/spec-kit` artifacts (`spec.md` / `plan.md` / `tasks.md`).

## Coding conventions

### TypeScript (frontend + Playwright)
- `strict` mode always on (`tsconfig.json`).
- Playwright locators **must** use `getByRole`, `getByLabel`, `getByText` over `data-testid` or CSS selectors. `data-testid` is the last-resort escape hatch.
- 1 `test.describe` per page / feature, 1 `test` per Acceptance Criterion (AC-001 etc).
- Map each `test` to a Work Item AC-id in the test title: `'AC-001: valid credentials redirect to dashboard'`.

### Python (Azure Functions)
- Python 3.11, type hints everywhere, `from __future__ import annotations` at the top of every module.
- Trigger functions in `function_app.py` are **wrappers only** — all business logic lives in pure functions (e.g. `process_message(payload: dict) -> dict`) that can be `import`-ed in tests without spinning up the Functions host.
- Never use Service Bus connection strings. Use Managed Identity by setting `ServiceBusConnection__fullyQualifiedNamespace`.

### Bicep
- Subscription-scope `main.bicep` + `modules/`.
- Parameters: `environment` (`dev|stg|prod`), `location`, `namePrefix`.
- Use `guid()` for `roleAssignments` names.
- Validate locally with `scripts/validate-bicep.sh` (= `az bicep build`).

### Workflows
- Use OIDC (`azure/login@v3` + `permissions: { id-token: write }`); never check in client secrets.
- All cloud-touching workflows are `workflow_dispatch`-only and gated.
- Always pin `actions/*` to a major version (`@v4`, `@v5`); pin third-party actions to a SHA when possible.
- Set `permissions:` explicitly per workflow (least privilege).

## Test conventions

- New features require both unit tests (`pytest` / `vitest`) and a Playwright E2E test mapped to the Gherkin AC.
- Playwright is configured with `webServer:` so `npx playwright test` is fully self-contained.
- Tests for `process_message()` use plain `dict` payloads — do **not** import `azure.functions` types inside business logic.

## Azure Boards × GitHub Issues conventions

- Commit messages: `feat: <summary> AB#<work-item-id>`
- PR titles / bodies: `Fixes AB#<id>` (and `Fixes #<gh-issue>` if both exist).
- Branch names (from Azure Boards "New GitHub branch"): `feat/<id>-<slug>`.
- The merge to `main` is what flips the ADO Work Item to Resolved / Closed.

## Spec-driven flow

- Each significant feature lives under `specs/{NNN}-{slug}/` (`spec.md` + `plan.md` + `tasks.md`).
- Acceptance Criteria are written in **Gherkin** (`Given / When / Then`) so Copilot can translate them 1:1 into Playwright `test()` blocks.
- `[NEEDS CLARIFICATION]` markers must be resolved before implementation begins.

## Documentation language convention

- Narrative docs in `docs/` are split into **`docs/en/`** (English) and **`docs/ja/`** (Japanese). Keep each language pure — do not mix EN/JA inside one file. Add a top-of-file cross-link to the other language.
- `README.md` is English; `README.ja.md` is its Japanese mirror.
- This file (`.github/copilot-instructions.md`), `AGENTS.md`, and `.github/instructions/*.instructions.md` are **English-only** because they are consumed by AI tools rather than read on a tour.

## Things Copilot should NOT do here

- Do not introduce Salesforce or Power Platform code into this demo (separate research scope).
- Do not add Azure deployment steps to `ci.yml` (must stay tenant-free and always green).
- Do not embed real `AZURE_CLIENT_ID`, tenant IDs, or any secret values in YAML / scripts.
- Do not switch Service Bus to connection-string auth.
- Do not use `if: always()` where `if: ${{ !cancelled() }}` is the safer Playwright pattern.

## Useful local commands

```bash
# Frontend + Playwright
cd app/frontend && npm ci && npx playwright install --with-deps && npx playwright test

# Python Functions unit tests (no Functions host required)
cd app/functions && pip install -r requirements.txt && pytest -q

# Bicep syntax validation
./scripts/validate-bicep.sh

# Workflow lint (Docker-based actionlint)
./scripts/lint-workflows.sh
```
