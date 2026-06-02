# AGENTS.md — instructions for non-Copilot AI agents

This file is read by **Codex CLI**, **Claude Code**, **Cursor**, and any agent that follows the `AGENTS.md` convention.
GitHub Copilot reads `.github/copilot-instructions.md` separately; the intent of both files is identical — see that file for full project conventions.

## TL;DR — what this repo is

A **30-minute demo monorepo** showcasing:
1. Playwright E2E + GitHub Actions (sharded + merged + PR comment)
2. Playwright MCP for continuous test maintenance
3. Azure DevOps Boards × GitHub Issues × `github/spec-kit` (spec-driven development)
4. AI context files (this file + `.github/copilot-instructions.md` + `.github/instructions/`)
5. Azure CD for Functions + Service Bus + OIDC (Bicep + reusable workflow)

Do not introduce Salesforce or Power Platform — they are out of demo scope.

## Hard rules

- TypeScript: `strict` mode; Playwright locators are `getByRole` / `getByLabel` first, `getByTestId` last resort, raw selectors never.
- Python: `from __future__ import annotations`; trigger functions are wrappers only and delegate to a pure `process_message(payload: dict) -> dict`.
- Bicep: subscription-scope `main.bicep` + `modules/`; pass `environment`, `location`, `namePrefix`.
- Workflows: OIDC (`azure/login@v3` + `permissions: { id-token: write }`); cloud workflows are `workflow_dispatch`-only and gated on `vars.AZURE_CLIENT_ID != ''`.
- Acceptance Criteria are Gherkin (`Given / When / Then`); test titles start with the AC ID (e.g. `AC-001: ...`).
- Service Bus uses Managed Identity (`ServiceBusConnection__fullyQualifiedNamespace`); connection strings are banned.
- Commits & PRs link to Azure Boards with `Fixes AB#<id>`.

## Files to read first when joining the repo

1. `README.md` — entrypoint (English; Japanese mirror at `README.ja.md`)
2. `docs/en/00-tour-30min.md` — what the demo flow looks like (Japanese: `docs/ja/00-tour-30min.md`)
3. `docs/en/architecture.md` — Mermaid diagrams (Japanese: `docs/ja/architecture.md`)
4. `specs/001-login-feature/spec.md` — example of spec-driven artifacts (Gherkin)
5. `.github/copilot-instructions.md` — full conventions (this is the source of truth; English-only because read by AI)
6. `.github/workflows/ci.yml` — how the always-green CI is wired

## Documentation language convention

Narrative docs in `docs/` are split into `docs/en/` (English) and `docs/ja/` (Japanese). Keep each language pure inside its directory. AI context files (`AGENTS.md`, `.github/copilot-instructions.md`, `.github/instructions/*.instructions.md`) are English-only.
