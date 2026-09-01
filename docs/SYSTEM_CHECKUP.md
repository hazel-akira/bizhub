# System Checkup — SQLite vs Cloud (PostgreSQL)

Last updated: September 2026

This document tracks which parts of Akira Flow use **local SQLite** (offline) vs **cloud API + PostgreSQL** (signed in).

---

## Architecture

| Mode | When | Data store |
|------|------|------------|
| **Offline** | Not signed in | Local Drift/SQLite on device |
| **Cloud** | Signed in with API token | Laravel API → PostgreSQL (Neon on Render) |

When signed in, `databaseProvider` **throws** if anything tries to open SQLite:

```
Local SQLite is disabled while signed in to the cloud.
```

---

## Production API status (Render)

**Check:** `GET https://akira-flow-api.onrender.com/api/health`

Healthy production should show:

```json
{
  "database_driver": "pgsql",
  "database": "neondb",
  "database_ok": true
}
```

If you see `"database_driver": "sqlite"`, Render is **not** using Neon Postgres. Data is stored in an ephemeral container file and is lost on redeploy.

### Fix Render Postgres

In Render → **akira-flow-api** → **Environment**, set (from `services/api/.env.render`):

```env
APP_ENV=production
APP_KEY=base64:...          # generate: php artisan key:generate --show
APP_URL=https://akira-flow-api.onrender.com

DB_CONNECTION=pgsql
DB_HOST=ep-....neon.tech    # DIRECT host (no -pooler)
DB_PORT=5432
DB_DATABASE=neondb
DB_USERNAME=neondb_owner
DB_PASSWORD=...             # from Neon dashboard
DB_SSLMODE=require

RUN_MIGRATIONS=true
RUN_SEEDER=false
GOOGLE_CLIENT_IDS=...
MPESA_CALLBACK_URL=https://akira-flow-api.onrender.com/api/mpesa/callback
```

Redeploy and confirm `/api/health` shows `pgsql`.

---

## Flutter — screen-by-screen status

### Works when signed in (cloud path)

| Screen | Cloud provider / API |
|--------|---------------------|
| Dashboard | `apiDashboardProvider` |
| Sales | `createApiSaleProvider`, `apiTodaySalesProvider` |
| Orders | `GET/POST /api/shop-orders` |
| Customers | `businessApiProvider.getCustomers()` |
| Unpaid Customers | `getUnpaidSales()`, cloud payments |
| Expenses | `apiTodayExpensesProvider`, `createApiExpenseProvider` |
| Inventory | `apiProductsProvider` (non-food shops) |
| Settings | Cloud sales reminder |
| Assistant | `CloudBusinessAssistantService` (uses API) |
| M-Pesa checkout | `mpesa_provider` + API |

### Offline-only when signed in (guarded)

| Screen | Status | Workaround |
|--------|--------|------------|
| **Production** | Local SQLite only | Shows info screen when signed in; use Sales/Orders |
| **Profit Tracker** | Calculator works; save/history offline-only | Dashboard shows profit from API |
| **Reports** | Has cloud path but not in main nav | Use Dashboard |

### Legacy / unused screens (local only)

| Screen | Notes |
|--------|-------|
| `payments_screen.dart` | Not in navigation |
| `unpaid_screen.dart` | Superseded by Unpaid Customers |

---

## Flutter — provider audit

| Provider | Cloud when signed in? |
|----------|----------------------|
| `customers_provider` | Yes |
| `orders_provider` | Yes |
| `unpaid_customers_provider` | Yes |
| `reports_provider` | Yes |
| `api_data_provider` | Yes |
| `dashboard_provider` | Yes (no SQLite fallback) |
| `assistant_provider` | Yes |
| `sales_provider` | Local only — not watched when cloud |
| `expenses_provider` | Local only — bypassed by expenses screen |
| `production_provider` | Local only — guarded |
| `profit_tracker_provider` | Local only — guarded |
| `payments_provider` | Local only |
| `unpaid_provider` | Legacy local |

---

## Backend API endpoints (cloud)

| Feature | Routes |
|---------|--------|
| Auth | `POST /api/auth/login`, `/register`, `/google` |
| Sales | `GET/POST /api/sales`, unpaid + payments |
| Shop orders | `GET/POST /api/shop-orders`, `POST .../fulfill` |
| Customers | CRUD `/api/customers` |
| Products | `/api/products` |
| Expenses | `/api/expenses` |
| Dashboard | `GET /api/dashboard` |
| M-Pesa | `/api/mpesa/*` |
| Global catalog | `/api/global-categories`, `/api/global-products` |

**Deploy note:** If `/api/shop-orders` returns **404**, push latest code and run migrations on Render.

---

## Fixes applied in this checkup

1. **Orders** — cloud API + Flutter providers (fixes food vendor Orders crash)
2. **Dashboard providers** — removed SQLite fallback when signed in
3. **Assistant** — cloud service using dashboard + unpaid API
4. **Production** — offline-only guard when signed in
5. **Profit Tracker** — calculator usable; save disabled when cloud
6. **Sales / Customers / Unpaid** — stop invalidating local providers when cloud
7. **Google auth** — API returns 422 instead of 500 on bad tokens
8. **render.yaml** — corrected `APP_URL` and `MPESA_CALLBACK_URL` hostname

---

## Remaining work (future)

| Item | Priority |
|------|----------|
| Deploy API + confirm Postgres on Render | **High** |
| Cloud **Production batches** API | Medium |
| Cloud **Profit Tracker** save/history API | Low |
| Remove dead local screens/providers | Low |
| PHPUnit tests for Google auth | Low |
| iOS Google Sign-In URL scheme | If shipping iOS |

---

## Verification checklist

After deploying API and hot-restarting the app:

- [ ] `/api/health` → `database_driver: pgsql`
- [ ] Sign in → Dashboard loads without SQLite error
- [ ] Food vendor: Orders page loads (empty or list)
- [ ] Create order → appears in list
- [ ] Mark served → creates credit sale
- [ ] Assistant: "today summary" works when signed in
- [ ] Production shows offline-only message when signed in
- [ ] Google Sign-In completes (see [GOOGLE_OAUTH_SETUP.md](./GOOGLE_OAUTH_SETUP.md))

---

## Run / build command

```bash
flutter run \
  --dart-define=API_BASE_URL=https://akira-flow-api.onrender.com \
  --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
```
