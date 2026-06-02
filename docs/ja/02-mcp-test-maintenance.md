# ② MCP による継続的テスト保守

> 🇬🇧 English version: [`docs/en/02-mcp-test-maintenance.md`](../en/02-mcp-test-maintenance.md)
>
> デモ VM で実 Copilot 接続が無い場合でも、以下の **self-healing 台本** だけで 3 分間ウォークスルーできる。

## 設定内容

`.vscode/mcp.json`:

```jsonc
{
  "servers": {
    "playwright": { "command": "npx", "args": ["@playwright/mcp@latest", "--caps=testing"] },
    "github":     { "type": "http", "url": "https://api.githubcopilot.com/mcp/" }
  }
}
```

`@playwright/mcp` はページの **ARIA アクセシビリティツリー** (ピクセル座標ではない) を返すため、LLM は `role` + `name` で要素を決定論的に選択できる — これは Playwright のロケーター方針 (`getByRole`, `getByLabel`) と同じ発想。

`--caps=testing` フラグでアサーション / ロケーター生成ツール (`browser_generate_locator`, `browser_verify_*`) を opt-in する。付けないとコアの navigation/click/type/snapshot ツールしか公開されない。

Copilot CLI ユーザー向けの等価な設定は `~/.copilot/mcp-config.json`:

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

## シナリオ: セレクタ破損の self-healing

### セットアップ (破損)

フロントエンドデザイナーが submit ボタンの文言を **"Sign in"** → **"Log in"** にリネーム。Playwright テストはまだ:

```ts
// app/frontend/tests/e2e/login.spec.ts (修正前)
await page.getByRole('button', { name: 'Sign in' }).click();
```

CI が失敗:

```
Error: locator.click: Test ended.
Locator: getByRole('button', { name: 'Sign in' })
Expected: visible
Received: <element(s) not found>
```

### Step 1 — 2 つの MCP サーバーを有効にした Copilot Chat に依頼

プロンプト (Copilot Chat にそのまま貼り付け):

```
Playwright テスト app/frontend/tests/e2e/login.spec.ts が
"AC-001: valid credentials redirect to dashboard" で失敗しています。
playwright MCP を使って http://127.0.0.1:5173 を開き、
submit ボタンの現在の accessible name を取得してください。
そのうえで、getByRole パターンを保ったまま現在の名前に
テストを更新してください。まず unified diff を見せて。
```

### Step 2 — 期待される MCP ツール呼び出し列

| # | ツール呼び出し | 戻り値 |
|---|---|---|
| 1 | `browser_navigate({ url: "http://127.0.0.1:5173" })` | ページロード OK |
| 2 | `browser_snapshot()` | ARIA ツリー: <br/>`- form "Sign in" [ref=e3]`<br/>`  - textbox "Email" [ref=e4]`<br/>`  - textbox "Password" [ref=e6]`<br/>`  - button "Log in" [ref=e8]`  ← **新しい名前に注目** |
| 3 | `browser_generate_locator({ target: "e8" })` (`--caps=testing` が必要) | `getByRole('button', { name: 'Log in' })` |
| 4 | (Copilot が `view` ツールで `login.spec.ts` を読む) | ソース diff |

### Step 3 — Copilot が提案する unified diff

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

### Step 4 — 再実行

```bash
./scripts/run-playwright.sh
# 4 passed (3.2s)
```

### Step 5 — ボーナス: GitHub MCP で PR まで作る

同じチャットセッションで続けてプロンプト:

```
"fix: update locator after UI rename" というタイトルで PR を作って。
本文に "Fixes AB#1042"、ブランチ名は fix/1042-login-button-rename。
```

GitHub MCP サーバーが `git` 操作と API 経由の PR 作成を処理する — `gh` CLI 不要。

## なぜ重要か

従来は「UI 変更 → QA がセレクタを追いかける」。新しいやり方は「UI 変更 → Copilot が新 UI を見る → 30 秒で PR 1 本」。ARIA ベースの MCP なので、壊れやすいピクセル一致のような仕組みも保守不要。

## 失敗するケース

- **認証後のページ**: `--storage-state=./playwright/.auth/user.json` を設定して、MCP がログイン済みセッションから始まるようにする。`microsoft/playwright-mcp` README の "Storage state" を参照。
- **canvas / チャートを含むページ**: 座標ベースツール (`browser_mouse_click_xy` 等) のため `--caps=vision` に切り替える。
- **プロンプト内の機密情報**: `playwright-mcp.config.json` の `secrets` マッピングを使い、平文の値が LLM コンテキストに乗らないようにする。

## ライブデモのフォールバック

デモ VM で Copilot が使えない場合は、このファイルの "Step 1 → Step 4" をそのまま辿るだけで十分。実行なしでもパターンは伝わる。
