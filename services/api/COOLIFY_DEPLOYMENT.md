# Coolify Deployment Guide — Akira Bites API

Laravel 13 / PHP 8.3 backend for the BizHub Flutter mobile app. Deploy **only** the `services/api` directory as an independent Coolify application. The Flutter app is built and distributed separately (Play Store, App Store, or sideload).

---

## Quick Start

| Setting | Value |
|---------|-------|
| **Base directory** | `services/api` |
| **Build pack** | Dockerfile |
| **Dockerfile** | `Dockerfile` |
| **Exposed port** | `8080` |
| **Health check** | `GET /up` or `GET /api/health` |

---

## Coolify Service Checklist

### 1. Create PostgreSQL database

- [ ] Provision a PostgreSQL 15+ database in Coolify (or external managed Postgres).
- [ ] Note `DB_HOST`, `DB_PORT`, `DB_DATABASE`, `DB_USERNAME`, `DB_PASSWORD`.
- [ ] For managed Postgres with SSL, set `DB_SSLMODE=require`.

### 2. Create the API application

- [ ] New resource → **Application** → connect your Git repository.
- [ ] Set **Base Directory** to `services/api`.
- [ ] Build pack: **Dockerfile** (uses root `Dockerfile` in that directory).
- [ ] Set **Port** to `8080` (container listens on 8080; Coolify proxy handles HTTPS).
- [ ] Assign a domain (e.g. `api.yourdomain.com`).
- [ ] Enable HTTPS via Coolify / Let's Encrypt.

### 3. Environment variables

Set all variables below in Coolify **Environment Variables** (runtime, not build-time).

#### Required

| Variable | Example | Notes |
|----------|---------|-------|
| `APP_NAME` | `Akira Bites API` | |
| `APP_ENV` | `production` | |
| `APP_KEY` | `base64:...` | Generate: `php artisan key:generate --show` |
| `APP_DEBUG` | `false` | **Must** be false in production |
| `APP_URL` | `https://api.yourdomain.com` | Must match public HTTPS URL (no trailing slash) |
| `DB_CONNECTION` | `pgsql` | |
| `DB_HOST` | `postgres` or IP | Coolify internal hostname or external |
| `DB_PORT` | `5432` | |
| `DB_DATABASE` | `bizhub` | |
| `DB_USERNAME` | `postgres` | |
| `DB_PASSWORD` | *(secret)* | |
| `TRUSTED_PROXIES` | `*` | Required behind Coolify reverse proxy |

#### Recommended

| Variable | Value | Notes |
|----------|-------|-------|
| `LOG_CHANNEL` | `stderr` or `stack` | Container-friendly logging |
| `LOG_LEVEL` | `warning` | Reduce noise in production |
| `SESSION_DRIVER` | `database` | Requires `sessions` table |
| `CACHE_STORE` | `database` | Or `redis` if you add Redis |
| `QUEUE_CONNECTION` | `database` | Worker runs via Supervisor in container |
| `FILESYSTEM_DISK` | `local` | See persistent storage section |
| `RUN_MIGRATIONS` | `true` | Auto-migrate on container start |
| `RUN_SEEDER` | `false` | Set `true` once for global catalog seed |

#### M-Pesa (if using payments)

| Variable | Notes |
|----------|-------|
| `MPESA_BASE_URL` | `https://api.safaricom.co.ke` for production |
| `MPESA_CONSUMER_KEY` | Daraja app credentials |
| `MPESA_CONSUMER_SECRET` | |
| `MPESA_SHORTCODE` | Paybill / till number |
| `MPESA_PASSKEY` | |
| `MPESA_CALLBACK_URL` | `https://api.yourdomain.com/api/mpesa/callback` — must be publicly reachable |

#### CORS (web clients only)

| Variable | Notes |
|----------|-------|
| `FRONTEND_URL` | Comma-separated origins, e.g. `https://shop.yourdomain.com` |

Native Flutter mobile apps **do not use CORS** — bearer token auth works without origin headers.

#### Sanctum (optional)

| Variable | Notes |
|----------|-------|
| `SANCTUM_STATEFUL_DOMAINS` | Only needed for cookie-based SPA auth |
| `SANCTUM_TOKEN_PREFIX` | Optional token prefix for secret scanning |

### 4. Persistent storage volume

Product images are stored on the `public` disk (`storage/app/public`). Without a volume, uploads are lost on redeploy.

- [ ] Mount a Coolify **persistent volume** to `/var/www/html/storage`
- [ ] Alternatively, configure S3 (`FILESYSTEM_DISK=s3` + AWS vars) for durable uploads

### 5. Health checks

Coolify health check settings:

| Path | Expected |
|------|----------|
| `/up` | HTTP 200 (Laravel built-in) |
| `/api/health` | HTTP 200 JSON `{"ok":true,...}` |

### 6. Post-deploy verification

- [ ] `curl -s https://api.yourdomain.com/up` returns 200
- [ ] `curl -s https://api.yourdomain.com/api/health` returns `{"ok":true}`
- [ ] `POST /api/register` creates a user (after migrations are fixed — see blockers)
- [ ] `POST /api/login` returns a bearer token
- [ ] Authenticated `GET /api/profile` works with `Authorization: Bearer <token>`
- [ ] Product image upload returns a URL under `https://api.yourdomain.com/storage/...`
- [ ] M-Pesa callback URL is reachable from Safaricom (if enabled)

### 7. Flutter app configuration

The Flutter app connects independently — configure the API base URL in the app (via `ApiConfigService` / connection settings). Point it to `https://api.yourdomain.com` (no `/api` suffix; the client appends `/api/...` paths).

---

## Architecture

```
┌─────────────┐     HTTPS      ┌──────────────────┐     ┌────────────┐
│ Flutter App │ ──────────────►│ Coolify Proxy    │────►│ Nginx:8080 │
│ (separate)  │  Bearer token  │ (Traefik/Caddy)  │     │ PHP-FPM    │
└─────────────┘                └──────────────────┘     │ Supervisor │
                                                        │  └─ queue    │
                                                        └──────┬─────┘
                                                               │
                                                        ┌──────▼─────┐
                                                        │ PostgreSQL │
                                                        └────────────┘
```

Container processes (Supervisor):

1. **php-fpm** — handles PHP requests via Nginx
2. **nginx** — serves `public/` on port 8080
3. **laravel-worker** — processes `database` queue jobs

---

## PostgreSQL Compatibility

Verified compatible:

- All 11 active migrations use Laravel schema builder (portable SQL).
- `unsignedInteger`, `foreignId`, `decimal`, `text`, `json` columns work on PostgreSQL.
- `pdo_pgsql` extension is installed in the production image.
- Default connection in `.env.example` is `pgsql`.

PostgreSQL-specific settings:

- `search_path` = `public` (in `config/database.php`)
- Optional `DB_SSLMODE=require` for managed databases

---

## Sanctum — Production Notes

| Topic | Status | Recommendation |
|-------|--------|----------------|
| **Flutter mobile auth** | Bearer tokens via `auth:sanctum` | Works out of the box; no CORS/cookies needed |
| **Token expiration** | `null` (never expires) | Consider setting `SANCTUM_EXPIRATION` or expiring tokens in `config/sanctum.php` for production security |
| **Stateful API** | `statefulApi()` enabled | Harmless for mobile; needed only for cookie-based SPAs |
| **CSRF** | Applied to stateful routes only | Not relevant for bearer-token mobile clients |
| **Personal access tokens table** | Migration exists | Created by `2026_06_11_123133_create_personal_access_tokens_table.php` |

---

## CORS — Production Notes

From `config/cors.php`:

- Paths: `api/*`, `sanctum/csrf-cookie`
- `allowed_origins`: parsed from `FRONTEND_URL` env var
- `allowed_origins_patterns`: **only when `APP_ENV=local`** (localhost wildcard)
- `supports_credentials`: `false` (correct for bearer-token API)

**For production:** set `FRONTEND_URL` to your actual web shop origins. Native Flutter apps are unaffected.

---

## File Uploads & Storage

| Item | Detail |
|------|--------|
| **Endpoint** | `POST /api/products/{product}/image` |
| **Validation** | `image`, max 5120 KB (5 MB) |
| **Disk** | `public` → `storage/app/public/products/{business_id}/{id}.{ext}` |
| **Public URL** | `{APP_URL}/storage/products/...` via `storage:link` |
| **Nginx limit** | `client_max_body_size 10M` |
| **PHP limits** | `upload_max_filesize 10M`, `post_max_size 12M` |
| **Entrypoint** | Runs `php artisan storage:link --force` on every start |

**Critical:** mount persistent storage or use S3 — otherwise product images are ephemeral.

---

## Storage & Permissions

The Dockerfile and entrypoint ensure:

```
storage/          → www-data:www-data, 775
bootstrap/cache/  → www-data:www-data, 775
```

Entrypoint re-applies permissions on every start (supports volume mounts).

Laravel caches written at startup in production:

- `config:cache`
- `route:cache`
- `view:cache`
- `event:cache`

---

## Deployment Blockers & Warnings

### Existing databases

The core schema migration (`2026_06_11_120000_create_core_business_schema`) uses `Schema::hasTable()` guards. If your PostgreSQL database already has these tables from a manual setup, the migration will skip creation and mark itself as run safely.

For databases that pre-date this migration file, run `php artisan migrate` once after deploy — it will only apply missing migrations.

### `docker.yml` is superseded

The old `docker.yml` used `php artisan serve` (development only). Use `Dockerfile` for production.

### Queue worker in same container

The database queue worker runs inside the API container via Supervisor. For high traffic, consider a separate Coolify worker service running `php artisan queue:work`.

### No Redis

Cache, session, and queue all use the database. This works but adds DB load. Consider adding Redis in Coolify for scale.

### M-Pesa callback must be public

Safaricom servers must reach `POST /api/mpesa/callback` over HTTPS. Verify firewall and Coolify routing.

### APP_URL must be HTTPS in production

Product image URLs and M-Pesa callbacks are built from `APP_URL`. Set it to the public HTTPS domain.

---

## Suggested Production Improvements

| Priority | Improvement |
|----------|-------------|
| **P0** | Mount persistent volume for `storage/` |
| **P1** | Set Sanctum token expiration (e.g. 30 days) |
| **P1** | Add Redis for cache/queue/session |
| **P1** | Configure real mail driver (not `log`) for notifications |
| **P2** | Move uploads to S3-compatible storage |
| **P2** | Add rate limiting on `/api/login` and `/api/register` |
| **P2** | Separate queue worker container for scale |
| **P2** | Add scheduled tasks container (`php artisan schedule:work`) if cron jobs are added |
| **P3** | Enable `LOG_CHANNEL=stderr` for log aggregation |
| **P3** | Set up database backups in Coolify |
| **P3** | Add staging environment with Daraja sandbox M-Pesa |

---

## Local Docker Build Test

```bash
cd services/api

docker build -t bizhub-api .

docker run --rm -p 8080:8080 \
  -e APP_KEY=base64:$(openssl rand -base64 32) \
  -e APP_ENV=production \
  -e APP_DEBUG=false \
  -e APP_URL=http://localhost:8080 \
  -e DB_CONNECTION=pgsql \
  -e DB_HOST=host.docker.internal \
  -e DB_PORT=5432 \
  -e DB_DATABASE=bizhub \
  -e DB_USERNAME=postgres \
  -e DB_PASSWORD=secret \
  -e RUN_MIGRATIONS=true \
  bizhub-api
```

Then: `curl http://localhost:8080/up`

---

## Environment Variable Reference (Complete)

| Variable | Required | Default | Purpose |
|----------|----------|---------|---------|
| `APP_NAME` | Yes | — | Application name |
| `APP_ENV` | Yes | `production` | Environment |
| `APP_KEY` | Yes | — | Encryption key |
| `APP_DEBUG` | Yes | `false` | Debug mode |
| `APP_URL` | Yes | — | Public base URL |
| `APP_LOCALE` | No | `en` | Locale |
| `APP_MAINTENANCE_DRIVER` | No | `file` | Maintenance mode driver |
| `LOG_CHANNEL` | No | `stack` | Log destination |
| `LOG_LEVEL` | No | `debug` | Log verbosity |
| `DB_CONNECTION` | Yes | `pgsql` | Database driver |
| `DB_HOST` | Yes | — | Database host |
| `DB_PORT` | No | `5432` | Database port |
| `DB_DATABASE` | Yes | — | Database name |
| `DB_USERNAME` | Yes | — | Database user |
| `DB_PASSWORD` | Yes | — | Database password |
| `DB_SSLMODE` | No | `prefer` | PostgreSQL SSL mode |
| `DB_URL` | No | — | Alternative DSN |
| `SESSION_DRIVER` | No | `database` | Session storage |
| `SESSION_LIFETIME` | No | `120` | Session TTL (minutes) |
| `CACHE_STORE` | No | `database` | Cache driver |
| `QUEUE_CONNECTION` | No | `database` | Queue driver |
| `FILESYSTEM_DISK` | No | `local` | Default filesystem |
| `BROADCAST_CONNECTION` | No | `log` | Broadcast driver |
| `MAIL_MAILER` | No | `log` | Mail driver |
| `MAIL_FROM_ADDRESS` | No | — | Sender email |
| `MAIL_FROM_NAME` | No | — | Sender name |
| `MPESA_BASE_URL` | No | sandbox URL | Daraja API base |
| `MPESA_CONSUMER_KEY` | If M-Pesa | — | API key |
| `MPESA_CONSUMER_SECRET` | If M-Pesa | — | API secret |
| `MPESA_SHORTCODE` | If M-Pesa | — | Business shortcode |
| `MPESA_PASSKEY` | If M-Pesa | — | Lipa na M-Pesa passkey |
| `MPESA_CALLBACK_URL` | If M-Pesa | — | STK callback URL |
| `FRONTEND_URL` | No | localhost | CORS allowed origins |
| `SANCTUM_STATEFUL_DOMAINS` | No | auto | Cookie auth domains |
| `SANCTUM_TOKEN_PREFIX` | No | — | Token prefix |
| `TRUSTED_PROXIES` | Yes (proxy) | `*` | Trusted reverse proxies |
| `RUN_MIGRATIONS` | No | `true` | Auto-run migrations |
| `RUN_SEEDER` | No | `false` | Auto-run seeders |
| `AWS_*` | If S3 | — | S3 storage credentials |
