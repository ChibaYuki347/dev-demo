import { defineConfig, devices } from '@playwright/test';

/**
 * Playwright config for the dev-demo frontend.
 *
 * Key design choices (see docs/en/01-playwright-e2e.md or docs/ja/01-playwright-e2e.md):
 *  - `webServer` makes `npx playwright test` self-contained — no manual `npm run dev` needed
 *  - `reporter` switches between `blob` in CI (so shards can be merged) and `html` locally
 *  - `forbidOnly` fails the build if someone commits `test.only`
 *  - `trace: 'on-first-retry'` keeps disk usage low while giving rich post-mortem on flakes
 */
export default defineConfig({
  testDir: './tests/e2e',
  timeout: 30_000,
  expect: { timeout: 5_000 },

  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,

  // blob in CI so shards can be merged via `npx playwright merge-reports`.
  // html locally for instant feedback.
  reporter: process.env.CI
    ? [
        ['blob'],
        ['github'],
      ]
    : [
        ['list'],
        ['html', { open: 'never' }],
      ],

  use: {
    baseURL: 'http://127.0.0.1:5173',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    headless: true,
  },

  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    // Add Firefox / WebKit projects here for cross-browser; commented out to
    // keep the demo fast.
  ],

  webServer: {
    command: 'npm run dev -- --host 127.0.0.1 --port 5173',
    url: 'http://127.0.0.1:5173',
    reuseExistingServer: !process.env.CI,
    timeout: 120_000,
    stdout: 'pipe',
    stderr: 'pipe',
  },
});
