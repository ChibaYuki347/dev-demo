import { test, expect } from '@playwright/test';

test.describe('Dashboard', () => {
  test('AC-001 (continued): direct navigation to /dashboard renders the welcome heading', async ({ page }) => {
    // Demo note: in a real app this would be guarded by auth and redirect to /login.
    // Here we simply verify the dashboard renders, mirroring the post-login state.
    await page.goto('/dashboard');
    await expect(page.getByRole('heading', { name: 'Welcome back' })).toBeVisible();
  });
});
