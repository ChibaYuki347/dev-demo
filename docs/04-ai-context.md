# ④ AI context files / AI コンテキスト記述

## Three-layer model / 3 階層モデル

| File | Scope | Read by |
|---|---|---|
| `.github/copilot-instructions.md` | Repository-wide | GitHub Copilot (Chat, Coding Agent, CLI) |
| `.github/instructions/*.instructions.md` | Path-scoped (`applyTo:` frontmatter) | GitHub Copilot |
| `AGENTS.md` | Repository-wide | Codex CLI, Claude Code, Cursor, OpenCode, … (the `AGENTS.md` convention) |

`CLAUDE.md` / `GEMINI.md` work the same way for those specific tools — we keep things to `AGENTS.md` here for brevity.

## Path-scoped instruction example

`.github/instructions/playwright-tests.instructions.md`:
```yaml
---
applyTo: "app/frontend/tests/**/*.spec.ts"
---
```

This file only loads when the active file matches the glob — keeping the global `.github/copilot-instructions.md` short and the per-area rules close to the code they govern.

## What goes in each file

### `.github/copilot-instructions.md` (repo-wide)
- Mission (1 paragraph)
- Architecture summary (1 line per component)
- Universal coding conventions (TS strict, Python hints, Bicep targetScope, etc.)
- Cross-cutting prohibitions (`"Do not introduce Salesforce code"`, `"No connection-string Service Bus"`, ...)
- Quick local commands cheat sheet

### `.github/instructions/<area>.instructions.md` (path-scoped)
- Locator policies, naming conventions
- Test patterns specific to that area
- Code structure rules that only apply in that directory

### `AGENTS.md`
- Same intent as the Copilot file but compressed — minimal duplication
- "Files to read first when joining the repo" — gives non-Copilot agents a starting map

## How to verify it's actually loading

In VS Code with Copilot:
1. `settings.json` must have `"github.copilot.chat.codeGeneration.useInstructionFiles": true` (we set this in `.vscode/settings.json`).
2. Open Copilot Chat, run `/help` → look for a list of loaded instructions.
3. Edit a `.spec.ts` file → Copilot Chat should reference the `playwright-tests` rules when suggesting locators.

For Copilot CLI:
```bash
copilot --print-instructions
```

## Anti-patterns / 避けるべき書き方

| ❌ Don't | ✅ Do |
|---|---|
| Stuff everything into `.github/copilot-instructions.md` | Push file-type-specific rules into `.github/instructions/<area>.instructions.md` |
| Repeat the same rules in `copilot-instructions.md` and `AGENTS.md` | Keep `AGENTS.md` short; point readers at `copilot-instructions.md` for full detail |
| Write `"Be concise and helpful"` | Write specific, verifiable rules (`"All Playwright test titles MUST start with AC-NNN:"`) |
| Inline secrets / tenant IDs / sample creds | Refer to settings keys; never paste real values |
| Set rules with no examples | Pair every rule with a `before/after` or code snippet |

## Why this matters for spec-driven development (Topic ③)

When Copilot Coding Agent picks up an Azure Boards Work Item and starts a PR, **the only context it has is**:
1. The Work Item's Title / Description / Acceptance Criteria
2. The repo's `.github/copilot-instructions.md` + `AGENTS.md` + path-scoped rules
3. Whatever it can find via repo search / RAG

(1) is the spec. (2) is the contract for *how* it should be implemented. Together they fully determine the PR's quality. Without (2), Copilot would invent conventions every time.
