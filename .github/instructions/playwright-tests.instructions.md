---
applyTo: "app/frontend/tests/**/*.spec.ts"
---

# Playwright Test Instructions

Path-scoped overrides for files under `app/frontend/tests/`.

## Locator policy
- **First choice**: `getByRole(role, { name })`
- **Second choice**: `getByLabel`, `getByPlaceholder`, `getByText`
- **Last resort**: `getByTestId('...')` — only when no semantic alternative exists, and add an inline comment explaining why.
- **Never**: raw CSS selectors (`page.locator('.btn-primary')`), XPath, or position-based selectors.

## Mapping to Acceptance Criteria
- Every `test('...')` title MUST start with the AC ID from the spec or Work Item:
  ```ts
  test('AC-001: valid credentials redirect to dashboard', async ({ page }) => { ... });
  ```
- One `test.describe` per feature/page; the describe title matches the User Story title from `specs/<feature>/spec.md`.

## Assertions
- Prefer Playwright's auto-retrying assertions: `await expect(locator).toBeVisible()` over `expect(await locator.isVisible()).toBe(true)`.
- Use `page.waitForURL(...)` instead of `page.waitForTimeout(...)`. `waitForTimeout` is banned outside debug code.

## Test data
- Reuse fixtures from `app/frontend/tests/fixtures/` (create one if needed).
- Hard-coded credentials are OK in this demo (they are pure mocks); in real code they would come from `process.env` + `playwright-mcp.config.json` `secrets` mapping.

## Trace / screenshots
- The project-level `playwright.config.ts` already sets `trace: 'on-first-retry'`, `screenshot: 'only-on-failure'`, `video: 'retain-on-failure'`. Do not override per-test unless investigating a flaky case.

## MCP-generated tests
- Tests generated via `@playwright/mcp` should be committed verbatim **after one human review pass** that:
  1. Verifies AC mapping in the title
  2. Replaces any `data-testid` with semantic locators where possible
  3. Adds a `// Generated with Playwright MCP on <date>` comment for traceability
