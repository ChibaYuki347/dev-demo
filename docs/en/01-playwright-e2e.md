# ① Playwright E2E with GitHub Actions

> 🇯🇵 Japanese version: [`docs/ja/01-playwright-e2e.md`](../ja/01-playwright-e2e.md)

## Why this pattern

The research report concluded that:

- `microsoft/playwright-github-action` is deprecated — use `npx playwright install --with-deps` directly.
- Sharded parallelism + `blob` reporter + `merge-reports` is the official scaling pattern.
- `if: ${{ !cancelled() }}` is safer than `if: always()` because it still uploads artifacts on test failure but skips on manual cancel.

This demo implements all three.

## Files

| File | Purpose |
|---|---|
| `app/frontend/playwright.config.ts` | `webServer:` block makes `npx playwright test` self-contained (no manual `npm run dev`); `reporter: 'blob'` in CI |
| `app/frontend/tests/e2e/login.spec.ts` | 3 tests, each titled `AC-NNN:` to match `specs/001-login-feature/spec.md` |
| `app/frontend/tests/e2e/dashboard.spec.ts` | minimal smoke test |
| `.github/workflows/playwright.yml` | sharded matrix + merge job + GitHub annotations + HTML artifact |

## Local run

```bash
./scripts/run-playwright.sh
```

This installs dependencies on first run, starts Vite via `webServer:`, runs Chromium against `http://127.0.0.1:5173`, and writes an HTML report to `app/frontend/playwright-report/`.

## CI pattern walkthrough

```
e2e (matrix: shardIndex=[1,2], shardTotal=[2])
  ├── shard 1 → blob-report-1 artifact
  └── shard 2 → blob-report-2 artifact
        ↓
merge-reports
  ├── download blob-report-* (pattern + merge-multiple)
  ├── npx playwright merge-reports --reporter html,github  ./all-blob-reports
  └── upload html-report--attempt-<n> artifact
```

Key points to call out during the demo:

1. **Two shards is enough to demonstrate the pattern** without burning runner minutes. Real projects often use 4–8.
2. **`reporter: 'blob'` is the magic** — it produces a binary report that `merge-reports` can stitch back together. Don't try to merge HTML reports directly.
3. **`merge-reports --reporter html,github`** writes both an HTML artifact AND the GitHub Actions annotations (file:line links in the run UI).
4. The merge job uses `if: ${{ !cancelled() }}` so it still runs when one shard failed — the merged report then includes the failures.

## What was deliberately left out

| Feature | Reason |
|---|---|
| Multiple browser projects (Firefox, WebKit) | Demo speed; easy to add — just uncomment in `playwright.config.ts` |
| `daun/playwright-report-summary@v4` PR comment | Pinned `node24` action; works in real PRs but adds noise on `push` events. Add when needed. |
| `ctrf-io/github-test-reporter@v1` | Heavier, requires CTRF JSON reporter; great for QA dashboards but overkill for this demo |
| `actions/cache@v4` for Playwright browsers | [Officially discouraged](https://playwright.dev/docs/ci#caching-browsers) — restore time ≈ download time and Linux OS deps cannot be cached |
| Microsoft Playwright Workspaces | Out of scope; documented in the research report §1.4 |

## Extending the demo

Add Firefox + WebKit:

```ts
// playwright.config.ts
projects: [
  { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
  { name: 'firefox',  use: { ...devices['Desktop Firefox'] } },
  { name: 'webkit',   use: { ...devices['Desktop Safari'] } },
],
```

…and adjust `npx playwright install --with-deps chromium` to `--with-deps` (all browsers).
