# ④ AI コンテキストファイル

> 🇬🇧 English version: [`docs/en/04-ai-context.md`](../en/04-ai-context.md)

## 3 層モデル

| ファイル | スコープ | 読み手 |
|---|---|---|
| `.github/copilot-instructions.md` | リポジトリ全体 | GitHub Copilot (Chat, Coding Agent, CLI) |
| `.github/instructions/*.instructions.md` | パス指定 (`applyTo:` frontmatter) | GitHub Copilot |
| `AGENTS.md` | リポジトリ全体 | Codex CLI, Claude Code, Cursor, OpenCode, … (`AGENTS.md` 慣例) |

`CLAUDE.md` と `GEMINI.md` も同じ仕組みで個別ツール向けに動くが、ここでは簡潔さのため `AGENTS.md` だけにまとめている。

## パス指定の例

`.github/instructions/playwright-tests.instructions.md`:

```yaml
---
applyTo: "app/frontend/tests/**/*.spec.ts"
---
```

このファイルはアクティブなファイルが glob にマッチしたときだけ読まれる — グローバルな `.github/copilot-instructions.md` を肥大化させずに、領域別のルールをそのコードの近くに置ける。

## 各ファイルに書く内容

### `.github/copilot-instructions.md` (リポジトリ全体)

- ミッション (1 段落)
- アーキテクチャ要約 (コンポーネントごとに 1 行)
- 全領域共通のコーディング規約 (TS strict, Python の型ヒント, Bicep の targetScope など)
- 横断的禁止事項 (`"Salesforce コードを入れるな"`, `"接続文字列の Service Bus は使うな"` など)
- ローカルでよく使うコマンド集

### `.github/instructions/<area>.instructions.md` (パス指定)

- ロケーター方針、命名規約
- その領域に固有のテストパターン
- そのディレクトリにだけ適用するコード構造ルール

### `AGENTS.md`

- Copilot 用ファイルと同じ意図を圧縮して書く — 重複を最小化
- 「リポジトリに参加して最初に読むファイル」 — Copilot 以外のエージェントに最初の手がかりを与える

## 読み込まれているか確認する方法

VS Code + Copilot:

1. `settings.json` に `"github.copilot.chat.codeGeneration.useInstructionFiles": true` が必要 (今回 `.vscode/settings.json` に設定済み)。
2. Copilot Chat を開いて `/help` を実行 → 読み込まれた instructions のリストを確認。
3. `.spec.ts` ファイルを編集 → Copilot Chat がロケーター提案時に `playwright-tests` ルールを参照するはず。

Copilot CLI の場合:

```bash
copilot --print-instructions
```

## アンチパターン

| ❌ ダメ | ✅ 推奨 |
|---|---|
| 全部を `.github/copilot-instructions.md` に詰め込む | ファイル種別固有のルールは `.github/instructions/<area>.instructions.md` に押し出す |
| 同じルールを `copilot-instructions.md` と `AGENTS.md` で重複させる | `AGENTS.md` は短く保ち、詳細は `copilot-instructions.md` を参照させる |
| `"簡潔で役立つように"` のような曖昧な記述 | 具体的・検証可能なルール (`"全 Playwright テストタイトルは AC-NNN: で始まること"`) |
| 秘密情報・テナント ID・サンプル認証情報をインラインに書く | 設定キーで参照、実値は絶対に貼らない |
| 例なしのルール | すべてのルールに `before/after` またはコードスニペットを添える |

## なぜこれが仕様駆動開発 (領域 ③) で重要か

Copilot Coding Agent が Azure Boards Work Item をアサインされて PR を始めるとき、**手元にあるコンテキストは**:

1. Work Item の Title / Description / 受け入れ基準
2. リポジトリの `.github/copilot-instructions.md` + `AGENTS.md` + パス指定ルール
3. リポジトリ検索 / RAG で見つかるもの

(1) が仕様。(2) は「どう実装すべきか」の契約。両者が PR の品質を完全に決める。(2) が無いと、Copilot は毎回規約を発明することになる。
