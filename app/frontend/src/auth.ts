/**
 * Pure auth function — testable without the DOM.
 * Demo-only: real auth would hit a backend.
 */
export interface AuthResult {
  ok: boolean;
  reason?: string;
}

const DEMO_EMAIL = 'valid@example.com';
const DEMO_PASSWORD = 'correct-horse-battery-staple';

export function authenticate(email: string, password: string): AuthResult {
  if (email === DEMO_EMAIL && password === DEMO_PASSWORD) {
    return { ok: true };
  }
  // Intentionally generic — never reveal which field is wrong (no user enumeration).
  return { ok: false, reason: 'Invalid email or password' };
}
