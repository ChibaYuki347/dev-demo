# Spec — Login Feature (`001-login-feature`)

> Generated in the spirit of [`github/spec-kit`](https://github.com/github/spec-kit) `/speckit.specify`.
> Hand-crafted for this demo; in a real project this would be created by running:
>
> ```bash
> /speckit.specify "Email + password login with a dashboard landing page and clear error messaging on invalid credentials"
> ```

## User Stories

### User Story 1 — Successful login (Priority: P1)

As a **returning user**
I want to **sign in with my email and password**
So that **I can access my personalized dashboard**.

#### Acceptance Scenarios

**AC-001**: valid credentials redirect to the dashboard
- **Given** an unauthenticated user is on `/login`
- **When** they submit `valid@example.com` / `correct-horse-battery-staple`
- **Then** they are redirected to `/dashboard`
- **And** the heading `Welcome back` is visible

**AC-002**: invalid credentials show an error message
- **Given** an unauthenticated user is on `/login`
- **When** they submit `valid@example.com` / `wrong-password`
- **Then** the URL stays on `/login`
- **And** the message `Invalid email or password` is visible
- **And** the email field retains the submitted value

### User Story 2 — Form validation (Priority: P2)

As any **user**
I want **immediate feedback when I forget a required field**
So that **I do not waste a round-trip to the server**.

#### Acceptance Scenarios

**AC-003**: submitting with an empty email surfaces a client-side validation message
- **Given** the user is on `/login`
- **When** they click `Sign in` with an empty email field
- **Then** an inline error `Email is required` is announced
- **And** focus moves to the email field

## Functional Requirements

- **FR-001**: System MUST render a login form with email, password, and submit controls accessible via `getByRole('textbox', { name: 'Email' })`, `getByLabel('Password')`, and `getByRole('button', { name: 'Sign in' })`.
- **FR-002**: System MUST authenticate the demo user `valid@example.com` against the hard-coded mock password and reject everything else with a generic `Invalid email or password` message (no user enumeration).
- **FR-003**: System MUST redirect to `/dashboard` on success and render a heading `Welcome back`.
- **FR-004**: System MUST mark required fields and prevent form submission when they are empty using native HTML5 validation.
- **FR-005**: System MUST surface validation and authentication failures in `role="alert"` containers so assistive tech announces them.
- **FR-006**: [NEEDS CLARIFICATION: should the demo include a "Remember me" checkbox? Out of scope for v1 unless requested.]

## Success Criteria

- **SC-001**: 100% of `AC-NNN` are covered by Playwright `test()` blocks whose title begins with the AC ID.
- **SC-002**: Median end-to-end Playwright run time on `ubuntu-latest` (single shard) ≤ 30 seconds.
- **SC-003**: Lighthouse a11y score on `/login` ≥ 95 (manual check; not enforced in CI for this demo).

## Out of scope

- Real user backend / database
- Session persistence, JWTs, refresh tokens
- OAuth / SSO
- Internationalization beyond English UI strings
