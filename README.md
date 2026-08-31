# Akira Bites — Samosa business app

Flutter mobile app for managing the samosa business. Runs on **one device**; all data is stored locally.

---

## Run the app

```bash
flutter pub get
flutter run
```

Choose a device (phone emulator, physical device, or `flutter run -d chrome` for web).

---

## Features

- **Dashboard** — Sales, expenses, and profit for today
- **Customers** — Add, edit, delete; duplicate detection by phone; tap for actions (edit, WhatsApp, delete)
- **Orders** — Create orders and fulfill them (mark paid or unpaid)
- **Sales** — Record ndengu and meat samosa sales
- **Expenses** — Add expenses with name and amount
- **Haven't paid** — Track and mark unpaid customers
- **Reports** — Daily and weekly profit, full transaction list

---

## Tech stack

- **Flutter** — Cross-platform
- **Drift** — SQLite database (local only)
- **Riverpod** — State management
- **Material 3** — UI components

---

## Configuration

Prices are defined in `lib/core/constants.dart`:

- Ndengu: KES 20
- Meat: KES 40

Update these to match your business prices.

---

## Customer app (`akira_bites_client/`)

Separate Flutter app for customers: browse menu, add to cart, place order via WhatsApp.

```bash
cd akira_bites_client
flutter pub get
flutter run
```

---

## Laravel API (PostgreSQL)

The backend API lives in `[services/api/](services/api/)`. It powers auth, the web client, and M-Pesa.

**Start the API** (always run this before using the Flutter app):

```bash
./scripts/start-api.sh
```

Verify: open [http://127.0.0.1:8000/api/health](http://127.0.0.1:8000/api/health) — should return `{"ok":true,...}`.

**Flutter app:** on the login screen, use **API connection → Test**. Default URLs:

- Linux desktop: `http://127.0.0.1:8000`
- Android emulator: `http://10.0.2.2:8000`
- Physical phone: `http://YOUR_PC_LAN_IP:8000`

See `[services/api/README.md](services/api/README.md)` for database setup and endpoints.

**Production:** Play Store for the Android app; Fly.io + Neon for the API. See `[DEPLOY.md](DEPLOY.md)`.

---

## Android release build (Play Store)

1. Copy signing template:

```bash
cp android/key.properties.example android/key.properties
```

1. Edit `android/key.properties` with your real upload keystore values.
2. Build with production API URL and Google Web client ID:

```bash
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://YOUR_API_DOMAIN \
  --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
```

Notes:

- Release builds require `android/key.properties`.
- Production endpoint should be HTTPS.
- In release mode, API connection override is disabled in-app.
- Set `GOOGLE_CLIENT_IDS` on the API to the same Web client ID (and Android/iOS IDs if used).

### Google Sign-In setup

1. In [Google Cloud Console](https://console.cloud.google.com/), create OAuth client IDs:
  - **Web** — used as `GOOGLE_WEB_CLIENT_ID` in Flutter and in API `GOOGLE_CLIENT_IDS`
  - **Android** — package `app.akirabizhub.pos`, add your SHA-1 fingerprints
2. Add the Web client ID to `services/api/.env`:
  ```
   GOOGLE_CLIENT_IDS=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
  ```
3. Pass the Web client ID when running or building the Flutter app:
  ```
   --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
  ```

---

## Docs

- `[DEPLOY.md](DEPLOY.md)` — Fly.io API + Google Play
- `[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)` — Project structure and features



flutter run \

  --dart-define=API_BASE_URL=[https://akira-flow-api.onrender.com/](https://akira-flow-api.onrender.com/)

  --dart-define=GOOGLE_WEB_CLIENT_ID=[445326255543-m8hh5al6s529h1c97h4v1ueif4e0hdgd.apps.googleusercontent.com](http://445326255543-m8hh5al6s529h1c97h4v1ueif4e0hdgd.apps.googleusercontent.com)