# Plan — Login Feature

> Mirrors what `/speckit.plan` would emit.

## Technology choices

| Concern | Choice | Why |
|---|---|---|
| Frontend stack | **Vite + vanilla TypeScript** | Minimal install footprint; demo focus is the patterns around it, not the framework |
| Routing | Hand-rolled `pushState` for `/login` and `/dashboard` | Avoids router dependency; keeps the demo focused on Playwright targets |
| Auth backend | **Client-side mock** comparing against hard-coded credentials | Production-realistic backends are out of scope for a 30-minute demo |
| Test runner | **`@playwright/test`** | Direct match for the E2E topic; mature, fast, Microsoft-maintained |
| Dev server orchestration | Playwright `webServer:` config | Makes `npx playwright test` fully self-contained — no manual `npm run dev` |

## Architecture

```
┌──────────────┐         ┌────────────────────┐
│  /login      │ submit  │  authenticate()    │
│  (form)      ├────────►│  pure TS function  │
└──────┬───────┘         └─────────┬──────────┘
       │ success                    │ failure
       ▼                            ▼
┌──────────────┐            ┌──────────────────┐
│ /dashboard   │            │ #login-error     │
│  Welcome back│            │ role="alert"     │
└──────────────┘            └──────────────────┘
```

`authenticate(email, password) -> { ok: boolean, reason?: string }` is a pure function in `src/auth.ts` so it can be unit-tested independently of the DOM.

## Constitution check

| Rule | Status |
|---|---|
| Playwright locators use `getByRole` / `getByLabel` | ✅ |
| Each `test()` title starts with `AC-NNN:` | ✅ |
| No `data-testid` introduced unnecessarily | ✅ |
| `webServer:` in `playwright.config.ts` | ✅ |
| New conventions reflected in `.github/copilot-instructions.md` | ✅ |

## Risks

- The Mermaid demo of UI states is static — a dev lead might ask "what's the framework?". Answer: deliberately vanilla so the demo doesn't get derailed into framework debates.
- `authenticate()` lives entirely client-side. This is acceptable for a demo target but would never ship in production; the README must call this out so the dev lead doesn't think we're proposing it.
