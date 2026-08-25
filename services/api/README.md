# Akira Bites API — Business Platform

```
Flutter App  →  Laravel API  →  PostgreSQL (AkiraSaaS)
```

Modular business platform API. Controllers are thin; business logic lives in **Services**. Every query is scoped to `auth()->user()->business_id`.

## Start

```bash
./scripts/start-api.sh
# Health: http://127.0.0.1:8000/api/health
# Schema overview: http://127.0.0.1:8000/
```

## Architecture

```
app/
├── Http/
│   ├── Controllers/Api/     # Thin controllers per module
│   ├── Requests/            # Validation (Login, StoreSale, etc.)
│   └── Middleware/          # EnsureBusinessAccess
├── Models/                  # Eloquent + BelongsToBusiness trait
└── Services/                # SaleService, ExpenseService, DashboardService, InventoryService
```

## Modules & Endpoints

### Platform (public)
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/business-types` | Supported tenant categories (food vendor, grocery, boutique, …) |

### Auth
| Method | Path | Auth |
|--------|------|------|
| POST | `/api/register` | No — requires `business_type` |
| POST | `/api/login` | No |
| POST | `/api/auth/google` | No — Google ID token; `business_name` + `business_type` for new accounts |
| POST | `/api/logout` | Bearer |
| GET | `/api/profile` | Bearer |

Legacy Flutter paths: `/api/auth/register`, `/api/auth/login`, `/api/auth/me`, `/api/auth/google`

### Business (requires `business` middleware)
| Method | Path |
|--------|------|
| GET | `/api/business` |
| PUT | `/api/business` |

### Categories
| GET/POST | `/api/categories` |
| PUT/DELETE | `/api/categories/{id}` |

### Global catalog (platform — read-only for businesses)
| GET | `/api/global-categories` |
| GET | `/api/global-products` |
| GET | `/api/global-products/search?q=` |

### Products (business inventory)
| GET/POST | `/api/products` |
| POST | `/api/products/from-global` — import from catalog |
| POST | `/api/products/custom` — custom business product |
| GET/PUT/DELETE | `/api/products/{id}` |

Public web menu: `GET /api/shop/products`

### Sales (no delete — affects reports)
| GET | `/api/sales` |
| GET | `/api/sales/{id}` |
| POST | `/api/sales` |

**POST body example:**
```json
{
  "payment_method": "cash",
  "items": [
    { "product_id": 1, "quantity": 5 }
  ]
}
```

### Expenses
| GET/POST | `/api/expenses` |
| PUT/DELETE | `/api/expenses/{id}` |

### Customers
| GET/POST | `/api/customers` |
| PUT/DELETE | `/api/customers/{id}` |

### Dashboard
| GET | `/api/dashboard` |

**Response:**
```json
{
  "data": {
    "today_sales": 15000,
    "today_expenses": 4000,
    "today_profit": 11000,
    "products_count": 32,
    "sales_count": 84
  }
}
```

## Multi-tenant business types

Each registration creates an isolated **business** tenant. Supported categories:

| `business_type` | Label |
|-----------------|-------|
| `food_vendor` | Food Vendors |
| `grocery_shop` | Grocery Shop |
| `boutique` | Boutiques |
| `hardware_store` | Hardware Stores |
| `pharmacy` | Pharmacies |
| `electronics_shop` | Electronic Shop |
| `cybercafe` | Cybercafe |
| `beauty_shop` | Beauty & Cosmetics |

On signup, the API seeds default product categories, expense categories, and starter products (food businesses get samosa items).

### Global catalog access by business type

| Business type | Allowed global categories |
|---------------|---------------------------|
| `food_vendor` | Food & Snacks, Beverages |
| `small_restaurant` | Food & Snacks, Beverages, Groceries |
| `grocery_shop` | Groceries, Beverages, Food & Snacks, Agriculture |
| `boutique` | Fashion |
| `hardware_store` | Hardware |
| `pharmacy` | Pharmacy |
| `electronics_shop` | Electronics |
| `cybercafe` | Services, Stationery, Electronics |
| `beauty_shop` | Beauty & Cosmetics |

Pharmacies never see food/beverages in catalog search; beauty shops never see medicines.

## Multi-tenant rule

Every business query uses:

```php
Product::forBusiness(auth()->user()->business_id)->get();
```

The `business` middleware blocks users without a `business_id`.

## Database

PostgreSQL database: `AkiraSaaS` (see `.env`).

```bash
php artisan migrate:status   # never migrate:fresh on production DB
```

## Production

Host this API on **Fly.io** with **Neon** Postgres. The Flutter app is distributed on **Google Play**, not from this server.

See [`../../DEPLOY.md`](../../DEPLOY.md).

