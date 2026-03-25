const API_BASE_URL = (() => {
  const meta = document.querySelector('meta[name="api-base"]');
  const val = meta?.content || '';
  return val.replace(/\/+$/, '');
})();

const TOKEN_KEY = 'akira_bites_token';

function getAccessToken() {
  try {
    return localStorage.getItem(TOKEN_KEY);
  } catch {
    return null;
  }
}

function setAccessToken(token) {
  try {
    if (!token) localStorage.removeItem(TOKEN_KEY);
    else localStorage.setItem(TOKEN_KEY, token);
  } catch {
    // ignore
  }
}

function apiUrl(path) {
  // path is expected to include the leading "/api/..."
  if (!API_BASE_URL) return path;
  return `${API_BASE_URL}${path}`;
}

async function apiFetch(path, options = {}) {
  const token = getAccessToken();
  const headers = { ...(options.headers || {}) };
  headers['Accept'] = 'application/json';
  if (token && !headers['Authorization']) headers['Authorization'] = `Bearer ${token}`;

  const res = await fetch(apiUrl(path), {
    ...options,
    headers,
  });

  const json = await res.json().catch(() => ({}));
  if (!res.ok) {
    const message = json?.message || (json?.errors ? 'Request failed' : 'Request failed');
    throw new Error(message);
  }
  return json;
}

function showScreen(screenId) {
  const screens = [
    'screen-menu',
    'screen-cart',
    'screen-checkout',
    'screen-status',
    'screen-login',
    'screen-register',
    'screen-account-orders',
  ];

  screens.forEach((id) => {
    const el = document.getElementById(id);
    if (!el) return;
    el.classList.toggle('hidden', id !== screenId);
  });
}

function parseRoute() {
  const path = (window.location.pathname || '/').replace(/\/+$/, '') || '/';

  if (path === '/' || path === '/menu') return { name: 'menu' };
  if (path === '/cart') return { name: 'cart' };
  if (path === '/checkout') return { name: 'checkout' };
  if (path === '/login') return { name: 'login' };
  if (path === '/register') return { name: 'register' };
  if (path === '/account/orders') return { name: 'account-orders' };

  const statusMatch = path.match(/^\/order\/(\d+)\/status$/);
  if (statusMatch) return { name: 'status', orderId: parseInt(statusMatch[1], 10) };

  // fallback
  return { name: 'menu' };
}

function showAuthError(el, message) {
  if (!el) return;
  el.textContent = message;
  el.classList.remove('hidden');
}

document.addEventListener('DOMContentLoaded', async () => {
  if (!window.OrderApp) {
    // order-app.js should set window.OrderApp
    console.error('OrderApp not found');
    return;
  }

  const route = parseRoute();
  window.OrderApp.init();

  if (route.name === 'menu') {
    showScreen('screen-menu');
    window.OrderApp.loadMenu();
    return;
  }

  if (route.name === 'cart') {
    showScreen('screen-cart');
    window.OrderApp.renderCart();
    window.OrderApp.initCartWhatsApp();
    return;
  }

  if (route.name === 'checkout') {
    showScreen('screen-checkout');
    window.OrderApp.initCheckout();
    return;
  }

  if (route.name === 'status') {
    showScreen('screen-status');
    const title = document.getElementById('status-title');
    if (title) title.textContent = `Order #${route.orderId}`;
    window.OrderApp.initOrderStatus(route.orderId);
    return;
  }

  if (route.name === 'login') {
    showScreen('screen-login');

    const form = document.getElementById('login-form');
    const err = document.getElementById('auth-error');
    if (form) {
      form.addEventListener('submit', async (e) => {
        e.preventDefault();
        err?.classList.add('hidden');
        try {
          const email = document.getElementById('login-email')?.value?.trim();
          const password = document.getElementById('login-password')?.value;
          const json = await apiFetch('/api/auth/login', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email, password }),
          });
          setAccessToken(json?.data?.access_token);
          window.location.href = '/account/orders';
        } catch (ex) {
          showAuthError(err, ex.message || 'Login failed');
        }
      });
    }
    return;
  }

  if (route.name === 'register') {
    showScreen('screen-register');

    const form = document.getElementById('register-form');
    const err = document.getElementById('auth-error-register');
    if (form) {
      form.addEventListener('submit', async (e) => {
        e.preventDefault();
        err?.classList.add('hidden');
        try {
          const name = document.getElementById('register-name')?.value?.trim();
          const email = document.getElementById('register-email')?.value?.trim();
          const password = document.getElementById('register-password')?.value;
          const password_confirmation = document.getElementById('register-password-confirm')?.value;

          const json = await apiFetch('/api/auth/register', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ name, email, password, password_confirmation }),
          });
          setAccessToken(json?.data?.access_token);
          window.location.href = '/account/orders';
        } catch (ex) {
          showAuthError(err, ex.message || 'Registration failed');
        }
      });
    }
    return;
  }

  if (route.name === 'account-orders') {
    showScreen('screen-account-orders');

    const token = getAccessToken();
    if (!token) {
      window.location.href = '/login';
      return;
    }

    const list = document.getElementById('orders-list');
    const loading = document.getElementById('orders-loading');
    const empty = document.getElementById('orders-empty');
    const logoutBtn = document.getElementById('logout-btn');

    if (logoutBtn) {
      logoutBtn.addEventListener('click', async () => {
        try {
          await apiFetch('/api/auth/logout', { method: 'POST' }).catch(() => null);
        } finally {
          setAccessToken(null);
          window.location.href = '/menu';
        }
      });
    }

    try {
      loading?.classList.remove('hidden');
      list?.classList.add('hidden');
      empty?.classList.add('hidden');

      const json = await apiFetch('/api/account/orders');
      const orders = json?.data || [];

      if (!orders.length) {
        empty?.classList.remove('hidden');
        return;
      }

      list.innerHTML = orders
        .map((o) => {
          const status = (o.payment_status || 'pending').toUpperCase();
          return `
            <div class="bg-white rounded-2xl shadow-sm p-4 flex items-start justify-between gap-4">
              <div>
                <div class="font-bold text-[var(--akira-black)]">#${o.id}</div>
                <div class="text-sm text-gray-600 mt-1">Total: KSh ${o.total_amount}</div>
                <div class="text-sm font-semibold mt-1 ${
                  o.payment_status === 'paid' ? 'text-green-700' : o.payment_status === 'failed' ? 'text-red-700' : 'text-amber-700'
                }">Status: ${status}</div>
              </div>
              <div class="flex flex-col items-end gap-2">
                <a href="/order/${o.id}/status" class="text-sm font-semibold text-[var(--akira-primary)] hover:underline">
                  View
                </a>
              </div>
            </div>
          `;
        })
        .join('');

      list?.classList.remove('hidden');
    } catch (ex) {
      // If token is invalid/expired, send them to login.
      setAccessToken(null);
      window.location.href = '/login';
    } finally {
      loading?.classList.add('hidden');
    }

    return;
  }
});

