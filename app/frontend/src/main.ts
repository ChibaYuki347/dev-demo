import { authenticate } from './auth';

const app = document.getElementById('app') as HTMLElement;

function renderLogin(prefilledEmail = ''): void {
  app.innerHTML = `
    <section class="card" aria-labelledby="login-title">
      <h1 id="login-title">Sign in</h1>
      <form id="login-form" novalidate>
        <label>
          <span>Email</span>
          <input
            type="email"
            name="email"
            autocomplete="username"
            required
            value="${escapeHtml(prefilledEmail)}"
          />
        </label>
        <label>
          <span>Password</span>
          <input
            type="password"
            name="password"
            autocomplete="current-password"
            required
          />
        </label>
        <button type="submit">Sign in</button>
        <div id="login-error" class="alert" role="alert" hidden></div>
      </form>
    </section>
  `;

  const form = document.getElementById('login-form') as HTMLFormElement;
  const errorBox = document.getElementById('login-error') as HTMLDivElement;

  form.addEventListener('submit', (e) => {
    e.preventDefault();
    const data = new FormData(form);
    const email = String(data.get('email') ?? '');
    const password = String(data.get('password') ?? '');

    if (!email) {
      showError(errorBox, 'Email is required');
      (form.elements.namedItem('email') as HTMLInputElement).focus();
      return;
    }
    if (!password) {
      showError(errorBox, 'Password is required');
      (form.elements.namedItem('password') as HTMLInputElement).focus();
      return;
    }

    const result = authenticate(email, password);
    if (result.ok) {
      history.pushState({}, '', '/dashboard');
      renderDashboard();
    } else {
      showError(errorBox, result.reason ?? 'Sign in failed');
    }
  });
}

function renderDashboard(): void {
  app.innerHTML = `
    <section class="card dashboard" aria-labelledby="dash-title">
      <h1 id="dash-title">Welcome back</h1>
      <p>You are signed in to the dev-demo dashboard.</p>
    </section>
  `;
}

function showError(box: HTMLDivElement, msg: string): void {
  box.textContent = msg;
  box.hidden = false;
}

function escapeHtml(s: string): string {
  return s
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function route(): void {
  if (location.pathname === '/dashboard') {
    renderDashboard();
  } else {
    renderLogin();
  }
}

window.addEventListener('popstate', route);
route();
