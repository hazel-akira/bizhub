# Akira Bites — Customer Web Ordering

Mobile-first web app for customers to browse the menu, add items to cart, and pay via M-Pesa.

## Pages

| Route | Description |
|-------|-------------|
| `/` | Menu — Browse products, add to cart |
| `/cart` | Cart — Review items, adjust quantity, proceed to checkout |
| `/checkout` | Checkout — Enter phone, pay with M-Pesa |
| `/order/{id}/status` | Order status — Waiting / Success / Failed |
| `/admin/orders` | Admin — View all orders |

## Flow

1. **Menu** → Add items to cart (stored in `localStorage`)
2. **Cart** → Adjust quantities, click "Proceed to Checkout"
3. **Checkout** → Enter M-Pesa phone (07XXXXXXXX), click "Pay with M-Pesa"
4. Backend creates order → Triggers STK Push → Redirects to status page
5. **Status** → Polls order until payment completes; shows WhatsApp confirm button on success

## APIs

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/api/products` | List menu items |
| POST | `/api/orders` | Create order |
| GET | `/api/orders/{id}` | Get order (for status polling) |
| POST | `/api/mpesa/stk` | Initiate STK Push |
| GET | `/api/mpesa/status/{checkoutRequestId}` | Poll M-Pesa status |
| POST | `/api/mpesa/callback` | Safaricom callback |
| GET | `/api/admin/orders` | List orders (admin) |

## WhatsApp

After successful payment, "Confirm via WhatsApp" opens `wa.me/254743385942` with a prefilled message (order details + phone). Matches Flutter customer app format.

## Run

```bash
cd services/mpesa-bridge
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate
php artisan db:seed
npm install && npm run build
php artisan serve --port=8000
```

Open http://localhost:8000
