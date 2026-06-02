import { test, expect } from '@playwright/test';

/**
 * E2E tests for the login flow.
 * Each test title starts with the AC ID from specs/001-login-feature/spec.md.
 */
test.describe('Login feature (specs/001-login-feature/spec.md)', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
  });

  test('AC-001: valid credentials redirect to dashboard', async ({ page }) => {
    await page.getByLabel('Email').fill('valid@example.com');
    await page.getByLabel('Password').fill('correct-horse-battery-staple');
    await page.getByRole('button', { name: 'Sign in' }).click();

    await page.waitForURL('**/dashboard');
    await expect(page.getByRole('heading', { name: 'Welcome back' })).toBeVisible();
  });

  test('AC-002: invalid credentials show generic error message', async ({ page }) => {
    await page.getByLabel('Email').fill('valid@example.com');
    await page.getByLabel('Password').fill('wrong-password');
    await page.getByRole('button', { name: 'Sign in' }).click();

    await expect(page).toHaveURL(/\/$|\/login/);
    await expect(page.getByRole('alert')).toHaveText('Invalid email or password');
    // Email field retains the submitted value
    await expect(page.getByLabel('Email')).toHaveValue('valid@example.com');
  });

  test('AC-003: empty email surfaces a client-side validation message', async ({ page }) => {
    await page.getByLabel('Password').fill('something');
    await page.getByRole('button', { name: 'Sign in' }).click();

    await expect(page.getByRole('alert')).toHaveText('Email is required');
    await expect(page.getByLabel('Email')).toBeFocused();
  });
});
