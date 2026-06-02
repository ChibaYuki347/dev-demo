# 30-Minute Demo Tour / 30 分デモ脚本

> Audience: client development lead. Goal: communicate that the 5 topics work together as a coherent engineering pattern. Time-boxed and rehearsed.
> 対象: 先方開発リーダー。目的: 5 領域が 1 つの開発スタイルとしてまとまっていることを伝える。時間厳守。

## Cheat sheet — what to show where / どこで何を見せるかの一覧

| Min | Section | Live? | File / Command |
|---|---|---|---|
| 0:00–0:04 | Repo overview + architecture | 🟢 live | `README.md`, `docs/architecture.md` (Mermaid) |
| 0:04–0:10 | ① Playwright E2E + GHA | 🟢 live | `./scripts/run-playwright.sh`, `.github/workflows/playwright.yml` |
| 0:10–0:15 | ④ AI context files | 🟢 live | `.github/copilot-instructions.md`, `AGENTS.md`, `.github/instructions/` |
| 0:15–0:21 | ③ Boards × spec-kit | 🟢 live | `specs/001-login-feature/spec.md`, `.github/ISSUE_TEMPLATE/user-story.yml`, `.github/workflows/sync-issues-to-ado.yml` |
| 0:21–0:26 | ⑤ Azure CD (dry-run) | 🟢 live | `./scripts/validate-bicep.sh`, `.github/workflows/deploy-{function-app,caller}.yml` |
| 0:26–0:30 | ② MCP test maintenance (walkthrough) | 📖 walkthrough | `.vscode/mcp.json`, `docs/02-mcp-test-maintenance.md` |

> Tip: rehearse once with a stopwatch. The MCP slot is intentionally last so a live demo failure does not derail the rest.

---

## 0:00–0:04 — Repo overview / リポジトリ概観

**EN**: "This is a single monorepo that demonstrates 5 patterns. Here is the directory tree" → open `README.md`, scroll to the "Topic map" table → open `docs/architecture.md` and show the Mermaid diagrams.

**JP**: 「5 領域のパターンを 1 つの monorepo で示しています。まずディレクトリ構成と全体図を」→ `README.md` のトピック表 → `docs/architecture.md` の Mermaid 図を表示。

Key talking point / 要点:
- Hybrid: CI actually runs and is always green; cloud workflows are `workflow_dispatch`-only and dry-run by default → no risk of accidentally hitting a real tenant.
- ハイブリッド構成: CI は常時グリーン、クラウド系ワークフローは `workflow_dispatch` 限定 + デフォルト dry-run。

---

## 0:04–0:10 — ① Playwright E2E + GitHub Actions

**Live (terminal)**:
```bash
./scripts/run-playwright.sh
```
Expected: Vite starts automatically (thanks to `webServer:` in `playwright.config.ts`), Chromium runs 4 tests (AC-001/002/003 + dashboard), HTML report is written to `app/frontend/playwright-report/` (open with `npx playwright show-report` from that directory).

**Then open `.github/workflows/playwright.yml`** and call out:
- `strategy.matrix.shardIndex: [1, 2]` — shard parallelism
- `reporter: blob` in `playwright.config.ts` (CI branch) + `merge-reports --reporter html,github` job → single HTML report
- `if: ${{ !cancelled() }}` instead of `if: always()` — safer pattern (artifacts upload even on test failure, but not on manual cancel)
- `permissions:` set to least-privilege (`contents: read` + `checks: write`)

**Talking point**: this is the exact pattern from the research report — official `microsoft/playwright-github-action` is deprecated; `npx playwright install --with-deps` is the only sanctioned approach now.

---

## 0:10–0:15 — ④ AI context files

Open in order:
1. `.github/copilot-instructions.md` — repo-wide rules; show the "Hard rules" and "Things Copilot should NOT do" sections.
2. `.github/instructions/playwright-tests.instructions.md` — path-scoped: locator policy (`getByRole` first, raw selector never), test title format (`AC-NNN:`).
3. `.github/instructions/azure-functions.instructions.md` — path-scoped: trigger wrapper / pure function separation; Managed Identity only.
4. `AGENTS.md` — same intent, served to Codex/Claude/Cursor.

**Talking point / 要点**:
- These files are how a human team's conventions become AI's conventions.
- Path-scoped `.instructions.md` lets you give different rules to different parts of the codebase without bloating one giant file.
- 人間チームの規約を AI の規約に変える仕組み。パス指定でファイル単位に異なる規約を与えられる。

---

## 0:15–0:21 — ③ Spec-driven dev (Boards × spec-kit)

Open in order:
1. `specs/001-login-feature/spec.md` — show the Gherkin Acceptance Criteria (AC-001/002/003) and `[NEEDS CLARIFICATION]` marker.
2. `app/frontend/tests/e2e/login.spec.ts` — show each `test()` title matches an AC ID.
3. `.github/ISSUE_TEMPLATE/user-story.yml` — issue template that mirrors the spec format and prompts for `AB#<id>`.
4. `.github/workflows/sync-issues-to-ado.yml` — show the `preflight` job that skips cleanly when `ENTRA_APP_CLIENT_ID` is unset.
5. `docs/03-spec-driven-dev.md` — the 7-step flow PdM → ADO → Issue → Copilot → PR → CI → Done.

**Talking point**: in real adoption, PdM authors AC in Gherkin in the Work Item; Copilot Coding Agent reads it and writes both the implementation and the matching Playwright tests in one shot.

---

## 0:21–0:26 — ⑤ Azure CD (dry-run)

**Live (terminal)**:
```bash
./scripts/validate-bicep.sh
```
Expected: `az bicep build` produces a compiled ARM JSON without warnings.

**Then open**:
1. `infra/bicep/main.bicep` + `modules/servicebus.bicep` — point at `disableLocalAuth: true` (no connection strings ever) and the `roleAssignments` for `Azure Service Bus Data Receiver`.
2. `infra/bicep/modules/functionapp.bicep` — `ServiceBusConnection__fullyQualifiedNamespace` + `__credential: managedidentity`.
3. `.github/workflows/deploy-function-app.yml` — reusable workflow (`on: workflow_call`); has no other trigger so it cannot run accidentally.
4. `.github/workflows/deploy-caller.yml` — `workflow_dispatch` only, defaults to `dry_run: true`, `preflight` short-circuits if `AZURE_CLIENT_ID` is unset.
5. `scripts/setup-oidc.sh` — reference script; do **not** execute during the demo.
6. `docs/architecture.md` — show the OIDC trust-chain sequence diagram.

**Talking point**: client secrets are gone. The Federated Credential's `subject` matches `repo:<org>/<repo>:environment:<env>` exactly — that string is the new bearer token.

---

## 0:26–0:30 — ② MCP test maintenance (walkthrough)

Open in order:
1. `.vscode/mcp.json` — the 2-server config: Playwright MCP + GitHub MCP.
2. `docs/02-mcp-test-maintenance.md` — walk through the **prepared self-healing transcript**: a CSS rename breaks `login.spec.ts` → Copilot Chat is asked to fix it → MCP tool sequence (`browser_navigate` → `browser_snapshot` → `browser_generate_locator`) → unified diff applied → tests pass.

If real Copilot is available in the demo VM, run the same prompt live. If not, the transcript stands on its own.

**Talking point**: this turns "selector maintenance" from a manual chore into a 30-second Copilot ask.

---

## Q & A buffer / 質疑応答

If short on time, drop the AI context section (0:10–0:15) — it is the most self-evident from reading the files. If extra time, run `cd app/functions && pytest -q` to show the pure-function test pattern.
