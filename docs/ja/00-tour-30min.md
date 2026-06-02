# 30 分デモ脚本

> 対象: 先方の開発リーダー。目的: 5 領域が 1 つの開発スタイルとしてまとまっていることを伝える。時間厳守。
>
> 🇬🇧 English version: [`docs/en/00-tour-30min.md`](../en/00-tour-30min.md)

## チートシート — どこで何を見せるか

| 分 | セクション | 実演? | ファイル / コマンド |
|---|---|---|---|
| 0:00–0:04 | リポジトリ概観 + アーキテクチャ | 🟢 ライブ | `README.md`, `docs/ja/architecture.md` (Mermaid) |
| 0:04–0:10 | ① Playwright E2E + GHA | 🟢 ライブ | `./scripts/run-playwright.sh`, `.github/workflows/playwright.yml` |
| 0:10–0:15 | ④ AI コンテキストファイル | 🟢 ライブ | `.github/copilot-instructions.md`, `AGENTS.md`, `.github/instructions/` |
| 0:15–0:21 | ③ Boards × spec-kit | 🟢 ライブ | `specs/001-login-feature/spec.md`, `.github/ISSUE_TEMPLATE/user-story.yml`, `.github/workflows/sync-issues-to-ado.yml` |
| 0:21–0:26 | ⑤ Azure CD (dry-run) | 🟢 ライブ | `./scripts/validate-bicep.sh`, `.github/workflows/deploy-{function-app,caller}.yml` |
| 0:26–0:30 | ② MCP テスト保守 (ウォークスルー) | 📖 ウォークスルー | `.vscode/mcp.json`, `docs/ja/02-mcp-test-maintenance.md` |

> ヒント: 一度ストップウォッチでリハーサルすること。MCP は最後に置いて、ライブ失敗が他のセクションを巻き込まないようにしている。

---

## 0:00–0:04 — リポジトリ概観

「これは 5 つのパターンを示した単一の monorepo です。まずはディレクトリ構成と全体図を見せます」と言いながら、`README.md` を開き「Topic ↔ file map」表へスクロール → `docs/ja/architecture.md` の Mermaid 図を表示。

主な話題:

- ハイブリッド構成: CI は実際に走って常にグリーン。クラウド系ワークフローは `workflow_dispatch` 限定 + デフォルト dry-run なので、テナントに事故 push する心配がない。

---

## 0:04–0:10 — ① Playwright E2E + GitHub Actions

**ライブ (ターミナル)**:

```bash
./scripts/run-playwright.sh
```

期待値: `playwright.config.ts` の `webServer:` 設定によって Vite が自動起動し、Chromium が 4 テスト (AC-001/002/003 + dashboard) を実行、HTML レポートは `app/frontend/playwright-report/` に書き出される (`npx playwright show-report` で閲覧)。

**続いて `.github/workflows/playwright.yml` を開いて指摘するポイント**:

- `strategy.matrix.shardIndex: [1, 2]` — シャード並列
- `reporter: blob`(`playwright.config.ts` の CI ブランチ) + `merge-reports --reporter html,github` ジョブで、複数シャードを 1 つの HTML レポートに統合
- `if: ${{ !cancelled() }}` を `if: always()` の代わりに使用 — テスト失敗時もアーティファクトをアップするが、手動キャンセル時はスキップする安全パターン
- `permissions:` は最小権限 (`contents: read` + `checks: write`) に絞っている

**話題**: これは調査レポートの通りのパターン。公式の `microsoft/playwright-github-action` は deprecated、現在は `npx playwright install --with-deps` 直叩きのみが推奨。

---

## 0:10–0:15 — ④ AI コンテキストファイル

順番に開く:

1. `.github/copilot-instructions.md` — リポジトリ全体ルール。「Hard rules」と「Things Copilot should NOT do」を示す。
2. `.github/instructions/playwright-tests.instructions.md` — パス指定: ロケーターポリシー (`getByRole` 最優先、生セレクタ厳禁)、テスト名フォーマット (`AC-NNN:`)。
3. `.github/instructions/azure-functions.instructions.md` — パス指定: トリガーラッパー / pure 関数分離、Managed Identity 必須。
4. `AGENTS.md` — 同じ意図を Codex / Claude / Cursor 向けに提供。

**話題**:

- これらは「人間チームの規約」を「AI の規約」に翻訳する仕組み。
- パス指定の `.instructions.md` を使えば、巨大な 1 ファイルを膨らませずにディレクトリ単位で異なる規約を与えられる。

---

## 0:15–0:21 — ③ 仕様駆動開発 (Boards × spec-kit)

順番に開く:

1. `specs/001-login-feature/spec.md` — Gherkin 受け入れ基準 (AC-001/002/003) と `[NEEDS CLARIFICATION]` マーカーを示す。
2. `app/frontend/tests/e2e/login.spec.ts` — 各 `test()` のタイトルが AC ID と一致していることを示す。
3. `.github/ISSUE_TEMPLATE/user-story.yml` — spec フォーマットを反映した issue テンプレート (AB#<id> 入力欄付き)。
4. `.github/workflows/sync-issues-to-ado.yml` — `ENTRA_APP_CLIENT_ID` 未設定なら preflight ジョブがクリーンに skip する仕組みを示す。
5. `docs/ja/03-spec-driven-dev.md` — PdM → ADO → Issue → Copilot → PR → CI → Done の 7 ステップフロー。

**話題**: 本番運用では PdM が Work Item に Gherkin で AC を書き、Copilot Coding Agent がそれを読んで実装コードと Playwright テストを一度に書き上げる。

---

## 0:21–0:26 — ⑤ Azure CD (dry-run)

**ライブ (ターミナル)**:

```bash
./scripts/validate-bicep.sh
```

期待値: `az bicep build` がコンパイル済み ARM JSON を警告なしで出力。

**続いて開くファイル**:

1. `infra/bicep/main.bicep` + `modules/servicebus.bicep` — `disableLocalAuth: true`(接続文字列を一切使わない) と `Azure Service Bus Data Receiver` の `roleAssignments` を指摘。
2. `infra/bicep/modules/functionapp.bicep` — `ServiceBusConnection__fullyQualifiedNamespace` + `__credential: managedidentity`。
3. `.github/workflows/deploy-function-app.yml` — Reusable workflow (`on: workflow_call`); 他にトリガーがないので事故起動しない。
4. `.github/workflows/deploy-caller.yml` — `workflow_dispatch` のみ、デフォルト `dry_run: true`。reusable 側 deploy ジョブの preflight が `AZURE_CLIENT_ID` 未設定なら綺麗に short-circuit。
5. `scripts/setup-oidc.sh` — 参考スクリプト。デモ中は **実行しない**。
6. `docs/ja/architecture.md` — OIDC 信頼関係のシーケンス図を示す。

**話題**: クライアントシークレットは消えた。Federated Credential の `subject` が `repo:<org>/<repo>:environment:<env>` と完全一致することが新しい「ベアラートークン」になる。

---

## 0:26–0:30 — ② MCP テスト保守 (ウォークスルー)

順番に開く:

1. `.vscode/mcp.json` — 2 サーバー構成: Playwright MCP + GitHub MCP。
2. `docs/ja/02-mcp-test-maintenance.md` — **事前に用意した self-healing 台本** を辿る: UI 文言変更で `login.spec.ts` が失敗 → Copilot Chat に修正を依頼 → MCP ツール列 (`browser_navigate` → `browser_snapshot` → `browser_generate_locator`) → unified diff 適用 → テスト復帰。

デモ VM で実 Copilot が使えるなら、同じプロンプトをライブ実行。使えなくても、台本だけで十分通る。

**話題**: 「セレクタ保守」という手作業を「Copilot に 30 秒お願い」に置き換える話。

---

## Q & A バッファ

時間が足りなくなったら、AI コンテキストのセクション (0:10–0:15) を落とすのが一番安全 — そこはファイルを見れば自明な内容。余裕があれば `cd app/functions && pytest -q` を実行して pure 関数テストパターンを見せる。
