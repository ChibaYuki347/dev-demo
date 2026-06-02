# ① Playwright E2E と GitHub Actions

> 🇬🇧 English version: [`docs/en/01-playwright-e2e.md`](../en/01-playwright-e2e.md)

## このパターンを採用する理由

調査レポートの結論:

- `microsoft/playwright-github-action` は deprecated — `npx playwright install --with-deps` を直接使うこと。
- シャード並列 + `blob` reporter + `merge-reports` が公式のスケーリングパターン。
- `if: ${{ !cancelled() }}` は `if: always()` より安全 — テスト失敗時もアーティファクトをアップロードするが、手動キャンセル時はスキップする。

このデモは 3 つすべてを実装している。

## ファイル

| ファイル | 役割 |
|---|---|
| `app/frontend/playwright.config.ts` | `webServer:` 設定で `npx playwright test` が自己完結 (手動の `npm run dev` 不要); CI では `reporter: 'blob'` |
| `app/frontend/tests/e2e/login.spec.ts` | 3 つのテスト、それぞれタイトルが `AC-NNN:` で `specs/001-login-feature/spec.md` と一致 |
| `app/frontend/tests/e2e/dashboard.spec.ts` | 最小のスモークテスト |
| `.github/workflows/playwright.yml` | matrix シャード + merge ジョブ + GitHub アノテーション + HTML artifact |

## ローカル実行

```bash
./scripts/run-playwright.sh
```

初回実行時は依存をインストールし、`webServer:` 経由で Vite を起動、`http://127.0.0.1:5173` に対して Chromium を走らせ、`app/frontend/playwright-report/` に HTML レポートを書き出す。

## CI パターンの解説

```
e2e (matrix: shardIndex=[1,2], shardTotal=[2])
  ├── shard 1 → blob-report-1 artifact
  └── shard 2 → blob-report-2 artifact
        ↓
merge-reports
  ├── blob-report-* をダウンロード (pattern + merge-multiple)
  ├── npx playwright merge-reports --reporter html,github  ./all-blob-reports
  └── html-report--attempt-<n> artifact をアップロード
```

デモで強調すべきポイント:

1. **シャード 2 つで十分パターンを示せる** — ランナー時間を浪費しない。実プロジェクトでは 4–8 が一般的。
2. **`reporter: 'blob'` が肝** — バイナリレポートを生成して `merge-reports` で繋ぎ合わせる。HTML レポートを直接マージしようとしないこと。
3. **`merge-reports --reporter html,github`** で HTML artifact と GitHub Actions アノテーション (run UI の file:line リンク) の両方を出力。
4. merge ジョブは `if: ${{ !cancelled() }}` を使うので、1 つのシャードが失敗しても実行される。マージ後のレポートには失敗も含まれる。

## あえて含めなかったもの

| 機能 | 理由 |
|---|---|
| 複数ブラウザ project (Firefox, WebKit) | デモ速度優先。追加は簡単 — `playwright.config.ts` のコメントを外すだけ |
| `daun/playwright-report-summary@v4` の PR コメント | `node24` ピン留め action; 実 PR では機能するが `push` イベントではノイズになる。必要に応じて追加 |
| `ctrf-io/github-test-reporter@v1` | 重量級、CTRF JSON reporter が必要; QA ダッシュボード向きでこのデモにはオーバースペック |
| `actions/cache@v4` で Playwright ブラウザ | [公式に非推奨](https://playwright.dev/docs/ci#caching-browsers) — リストア時間 ≈ ダウンロード時間で、Linux の OS 依存はキャッシュ不可 |
| Microsoft Playwright Workspaces | スコープ外; 調査レポート §1.4 を参照 |

## デモの拡張方法

Firefox + WebKit を追加:

```ts
// playwright.config.ts
projects: [
  { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
  { name: 'firefox',  use: { ...devices['Desktop Firefox'] } },
  { name: 'webkit',   use: { ...devices['Desktop Safari'] } },
],
```

…そして `npx playwright install --with-deps chromium` を `--with-deps` (全ブラウザ) に変更。
