# Tasks — Login Feature

> Mirrors `/speckit.tasks`. `[P]` means parallel-safe with the prior task.

| # | Task | File(s) | AC covered |
|---|---|---|---|
| T-001 | Render login form (email + password + submit) | `app/frontend/index.html`, `app/frontend/src/main.ts` | AC-001/002/003 |
| T-002 `[P]` | Render dashboard heading `Welcome back` | `app/frontend/src/main.ts` | AC-001 |
| T-003 | Extract `authenticate(email, password)` pure function | `app/frontend/src/auth.ts` | AC-001/002 |
| T-004 | Wire form submit handler — call `authenticate`, push history, render alert | `app/frontend/src/main.ts` | AC-001/002/003 |
| T-005 `[P]` | Add Playwright `webServer:` config | `app/frontend/playwright.config.ts` | infra |
| T-006 | Write Playwright tests `AC-001`, `AC-002`, `AC-003` | `app/frontend/tests/e2e/login.spec.ts` | AC-001/002/003 |
| T-007 `[P]` | Wire unit tests for `authenticate()` (optional vitest) | `app/frontend/src/auth.test.ts` | AC-001/002 |
| T-008 | Update `.github/copilot-instructions.md` if new conventions introduced | `.github/copilot-instructions.md` | — |
| T-009 | Link PR to AB# / GitHub Issue | (commit msg + PR body) | — |
