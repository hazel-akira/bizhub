# Deploy — API (Fly.io) + Android (Play Store)

The cashier app goes to **Google Play**. Only the Laravel API needs a host, because Safaricom must call `POST /api/payments/stk-callback` on a public HTTPS URL (do **not** use `/api/mpesa/callback` — Daraja rejects URLs containing "mpesa").

## Cost

| Piece | Choice | Typical cost |
|---|---|---|
| Android app | Google Play Console (you already have this) | One-time Play fee (already paid) |
| Database | [Neon](https://neon.tech) free Postgres | $0 |
| API | [Fly.io](https://fly.io) Docker (this repo’s `services/api/Dockerfile`) | about **$2–5 / month** |

Sleeping free hosts (Render free, some Cloud Run idle setups) are a poor fit: M-Pesa callbacks fail while the API is asleep.

Oracle Cloud “Always Free” can be $0 but you would run the server yourself. Fly + Neon is the cheapest option that stays simple.

## 1. Free Postgres (Neon)

1. Create a project at https://neon.tech
2. Copy the connection string (host, database, user, password, port `5432`)
3. Enable SSL; set `DB_SSLMODE=require` on the API

## 2. API on Fly.io

From your machine (install the [Fly CLI](https://fly.io/docs/flyctl/install/)):

```bash
cd services/api
fly auth signup   # or fly auth login
fly launch --copy-config --no-deploy
```

Set secrets (do not put these in git):

```bash
fly secrets set \
  APP_ENV=production \
  APP_DEBUG=false \
  APP_KEY="$(php artisan key:generate --show)" \
  APP_URL=https://YOUR-APP.fly.dev \
  DB_CONNECTION=pgsql \
  DB_HOST=YOUR-NEON-HOST \
  DB_PORT=5432 \
  DB_DATABASE=YOUR-NEON-DB \
  DB_USERNAME=YOUR-NEON-USER \
  DB_PASSWORD=YOUR-NEON-PASSWORD \
  DB_SSLMODE=require \
  TRUSTED_PROXIES='*' \
  RUN_MIGRATIONS=true \
  MPESA_BASE_URL=https://sandbox.safaricom.co.ke \
  MPESA_CALLBACK_URL=https://YOUR-APP.fly.dev/api/payments/stk-callback \
  GOOGLE_CLIENT_IDS=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
```

Deploy:

```bash
fly deploy
```

Check `https://YOUR-APP.fly.dev/api/health`.

When Daraja **Go Live** is approved, change:

- `MPESA_BASE_URL=https://api.safaricom.co.ke`
- `MPESA_CALLBACK_URL` stays your Fly HTTPS URL

Per-shop Till/Paybill keys still live in the app **Settings** screen, not in Fly secrets.

## 3. Play Store build

Release builds ignore the in-app API URL override. Bake in the Fly URL:

```bash
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://YOUR-APP.fly.dev \
  --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
```

Upload `build/app/outputs/bundle/release/app-release.aab` in Play Console.

See the root `README.md` for `android/key.properties` signing.

## What not to do

- Do not host Flutter web as the main cashier app if Play Store is the goal.
- Do not use `localhost` or ngrok in a store build.
- Do not put Daraja consumer secrets in the Flutter app; they stay on Laravel (and in Settings, encrypted in the database).
