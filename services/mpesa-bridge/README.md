# M-Pesa bridge (minimal backend)

Receives STK Push requests from the Flutter app and forwards them to Safaricom Daraja. Safaricom callbacks update payment status, which Flutter polls.

## Setup

```bash
cd services/mpesa-bridge
composer install
cp .env.example .env
php artisan key:generate
```

Add Daraja credentials to `.env`:

```env
MPESA_CONSUMER_KEY=...
MPESA_CONSUMER_SECRET=...
MPESA_SHORTCODE=...      # Sandbox: 174379
MPESA_PASSKEY=...        # From Daraja test credentials
MPESA_CALLBACK_URL=...   # Public HTTPS URL (use ngrok for local)
```

Run migrations (already includes `stk_requests`):

```bash
php artisan migrate
```

## Run

```bash
php artisan serve --port=8000
```

For **Safaricom callbacks**, the server must be reachable over HTTPS. Use ngrok:

```bash
ngrok http 8000
# Set MPESA_CALLBACK_URL to https://YOUR-NGROK-URL/api/mpesa/callback
```

## API

| Method | Path | Body |
|--------|------|------|
| POST | `/api/mpesa/stk` | `{ "amount": 100, "phone": "0712345678", "reference": "unpaid_1" }` |
| GET | `/api/mpesa/status/{checkoutRequestId}` | — |
| POST | `/api/mpesa/callback` | (Safaricom only) |

## Flutter config

In `lib/core/constants.dart`, set `mpesaApiBaseUrl`:

- **Android emulator:** `http://10.0.2.2:8000`
- **iOS simulator:** `http://localhost:8000`
- **Physical device (same WiFi):** `http://YOUR_COMPUTER_IP:8000`
