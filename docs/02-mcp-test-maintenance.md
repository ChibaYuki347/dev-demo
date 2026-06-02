# ② MCP for continuous test maintenance / MCP によるテスト継続保守

> If a live Copilot connection is not available in the demo VM, the **self-healing transcript** below stands on its own and can be walked through in 3 minutes.

## What is configured

`.vscode/mcp.json`:
```jsonc
{
  "servers": {
    "playwright": { "command": "npx", "args": ["@playwright/mcp@latest", "--caps=testing"] },
    "github":     { "type": "http", "url": "https://api.githubcopilot.com/mcp/" }
  }
}
```

`@playwright/mcp` returns the page's **ARIA accessibility tree** (not pixel coordinates), so the LLM picks elements deterministically by `role` + `name` — the same way our Playwright locator policy (`getByRole`, `getByLabel`) works.

The `--caps=testing` flag opts into the assertion / locator-generation tools (`browser_generate_locator`, `browser_verify_*`). Without it only the core navigation/click/type/snapshot tools are exposed.

For Copilot CLI users, the equivalent config goes in `~/.copilot/mcp-config.json`:
```jsonc
{
  "mcpServers": {
    "playwright": {
      "type": "local",
      "command": "npx",
      "tools": ["*"],
      "args": ["@playwright/mcp@latest"]
    }
  }
}
```

## Scenario: self-healing a broken selector / セレクタの自己修復

### Setup (the breakage)

The frontend designer renames the submit button text from **"Sign in"** to **"Log in"**. The Playwright test still asserts:

```ts
// app/frontend/tests/e2e/login.spec.ts (BEFORE)
await page.getByRole('button', { name: 'Sign in' }).click();
```

CI fails:
```
Error: locator.click: Test ended.
Locator: getByRole('button', { name: 'Sign in' })
Expected: visible
Received: <element(s) not found>
```

### Step 1 — Ask Copilot Chat with both MCP servers enabled

Prompt (paste verbatim into Copilot Chat):
```
The Playwright test app/frontend/tests/e2e/login.spec.ts is failing on
"AC-001: valid credentials redirect to dashboard". Use the playwright MCP to
open http://127.0.0.1:5173 and find the current accessible name of the
submit button. Then update the test to use the current name, keeping the
getByRole pattern. Show me a unified diff first.
```

### Step 2 — Expected MCP tool sequence

| # | Tool call | Returns |
|---|---|---|
| 1 | `browser_navigate({ url: "http://127.0.0.1:5173" })` | Page load OK |
| 2 | `browser_snapshot()` | ARIA tree: <br/>`- form "Sign in" [ref=e3]`<br/>`  - textbox "Email" [ref=e4]`<br/>`  - textbox "Password" [ref=e6]`<br/>`  - button "Log in" [ref=e8]`  ← **note the new name** |
| 3 | `browser_generate_locator({ target: "e8" })` | `getByRole('button', { name: 'Log in' })` |
| 4 | (Copilot reads `login.spec.ts` with the `view` tool) | source diff |

### Step 3 — Unified diff Copilot proposes

```diff
--- a/app/frontend/tests/e2e/login.spec.ts
+++ b/app/frontend/tests/e2e/login.spec.ts
@@ -8,7 +8,7 @@ test.describe('Login feature (specs/001-login-feature/spec.md)', () => {
   test('AC-001: valid credentials redirect to dashboard', async ({ page }) => {
     await page.getByLabel('Email').fill('valid@example.com');
     await page.getByLabel('Password').fill('correct-horse-battery-staple');
-    await page.getByRole('button', { name: 'Sign in' }).click();
+    await page.getByRole('button', { name: 'Log in' }).click();
     await page.waitForURL('**/dashboard');
     await expect(page.getByRole('heading', { name: 'Welcome back' })).toBeVisible();
   });
```

### Step 4 — Re-run

```bash
./scripts/run-playwright.sh
# 4 passed (3.2s)
```

### Step 5 — Bonus: file a PR via GitHub MCP

Same chat session, follow-up prompt:
```
Now create a PR titled "fix: update locator after UI rename" with
"Fixes AB#1042" in the body. Branch name: fix/1042-login-button-rename.
```

The GitHub MCP server handles the `git` plumbing and PR creation via the API — no `gh` CLI needed.

## Why this matters / なぜ重要か

- **EN**: The old way was "the UI changed → the QA chases selectors". The new way is "the UI changed → Copilot sees the new UI → 30 seconds, one PR." The ARIA-based MCP means there's no brittle pixel-matching to maintain.
- **JP**: 従来「UI 変更 → QA がセレクタを追いかける」だったものが「UI 変更 → Copilot が新 UI を見て → 30 秒で PR」になる。ARIA ベースなのでピクセル一致のような壊れやすい仕組みもない。

## When this fails

- Pages behind authentication: configure `--storage-state=./playwright/.auth/user.json` so MCP starts from a logged-in session. See `microsoft/playwright-mcp` README "Storage state".
- Pages with canvas/charts: switch to `--caps=vision` for the coordinate-based tools (`browser_mouse_click_xy` etc.).
- Sensitive credentials in prompts: use the `secrets` mapping in `playwright-mcp.config.json` so plain-text values never enter the LLM context.

## Live-demo fallback

If Copilot is unavailable in the demo VM, walk through this file's "Step 1 → Step 4" verbatim — the transcript is concrete enough to make the pattern click without any live execution.
