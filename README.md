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

## M-Pesa (STK Push)

To collect payments via M-Pesa from the **Haven't paid** screen:

1. Start the M-Pesa bridge: `cd services/mpesa-bridge && php artisan serve --port=8000`
2. Configure Daraja credentials in `services/mpesa-bridge/.env` (see [README](services/mpesa-bridge/README.md))
3. Use ngrok for Safaricom callbacks when testing locally
4. Set `mpesaApiBaseUrl` in `lib/core/constants.dart` for your setup (emulator vs device)

---

## Docs

- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — Project structure and features
