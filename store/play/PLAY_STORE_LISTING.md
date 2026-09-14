# Akira Flow — Google Play Console fill-in guide

Use this document while sitting in [Play Console](https://play.google.com/console). Copy the boxed text as-is unless a field says REPLACE.

Package name is already set in the Android project. **Do not change it** after the first AAB upload — Google locks it forever.

| Item | Value |
|------|--------|
| App name on device | `Akira Flow` |
| Package name / applicationId | `app.akirabizhub.pos` |
| Version in `pubspec.yaml` | `2.0.0+2` (name `2.0.0`, version code `2`) |
| Default language | English (United States) |
| Category | **Business** |
| Graphics folder | `store/play/graphics/` |

---

## 0. Before you open Play Console

1. Replace `REPLACE_WITH_YOUR_EMAIL` in `store/play/privacy-policy.html` with a real inbox you check.
2. Privacy and support are live on Vercel:
   - Privacy: `https://akira-flow-privacy.vercel.app/`
   - Privacy (alias): `https://akira-flow-privacy.vercel.app/privacy`
   - Support: `https://akira-flow-privacy.vercel.app/support`
3. To update the pages later: `cd store/play/legal && npx vercel --yes --prod`
4. In Google Cloud Console, keep the **Android** OAuth client on package `app.akirabizhub.pos` and add:
   - Debug SHA-1
   - Upload-key SHA-1
   - **Play App Signing** SHA-1 (available after you create the Play app and upload the first AAB)

---

## 1. Create the app (first time only)

1. Open [Play Console](https://play.google.com/console) → **Create app**.
2. Fill:

| Field | Enter |
|-------|--------|
| App name | `Akira Flow` |
| Default language | English (United States) |
| App or game | **App** |
| Free or paid | **Free** |
| Declarations | Tick the Play policies / US export checkboxes |

3. Create the app. You will land on a **Dashboard** with a setup checklist. Work top to bottom.

---

## 2. Main store listing

Left menu: **Grow users → Store presence → Main store listing** (some accounts still show **Store presence → Main store listing**).

### App name (max 30)

```
Akira Flow
```

### Short description (max 80)

```
POS for Kenyan shops: sales, M-Pesa, stock, and daily profit.
```

### Full description (max 4000)

```
Akira Flow is a point-of-sale and shop manager for Kenyan small businesses. Record sales, collect M-Pesa, track stock, and see today’s profit on one phone.

WHO IT IS FOR
Food vendors, small restaurants, grocery shops, pharmacies, boutiques, beauty shops, electronics shops, hardware stores, and cybercafes.

WHAT YOU CAN DO
• Record cash and M-Pesa sales in seconds
• Send a Lipa Na M-Pesa STK prompt to the customer’s phone
• Keep inventory with low-stock alerts
• Track orders, unpaid balances, expenses, and daily profit
• Import customers from your phone contacts
• Ask the in-app assistant for today’s summary, profit, and who owes
• Sign in with email or Google and sync your shop to the cloud

WHY SHOP OWNERS USE IT
Stop guessing if you made money today. Akira Flow shows sales, costs, and profit in Kenyan shillings, with a workflow built around Till and Paybill collections.

HOW TO START
1. Create a business account and pick your shop type
2. Add products (or pick from the catalog)
3. Record a sale — cash or M-Pesa
4. Check the dashboard at the end of the day

Akira Flow is built for operators who sell every day — not for enterprise ERP.

Need help? Use the support email on this Play Store listing.
```

### Graphics — upload from `store/play/graphics/`

Upload in this order (Play shows the first 2–4 screenshots most often):

| Play field | File | Spec |
|------------|------|------|
| App icon | `icon-512.png` | 512×512 PNG, transparency OK |
| Feature graphic | `feature-graphic-1024x500.jpg` | 1024×500, no transparency |
| Phone screenshots (required, 2–8) | `01` … `06` `*-1080x1920.jpg` | 1080×1920 JPEG |
| Extra landscape (helps featuring) | `07-dashboard-1920x1080-landscape.jpg` | 1920×1080 JPEG |
| Promo video | skip for now | YouTube URL only if you have one |

Phone screenshot captions:

1. See today’s profit at a glance
2. Record a sale in seconds
3. Stock that stays under control
4. Ask how the business is doing
5. Sign in and start selling
6. Built for every kind of shop

Tablet screenshots are optional unless you declare tablet as a form factor.

Save the listing.

---

## 3. Store settings

**Grow users → Store presence → Store settings** (or **Setup → Store settings**).

| Field | Enter |
|-------|--------|
| App category | **Business** |
| Tags | Business management, Finance, Point of sale, Inventory |
| Email (required) | your real support email |
| Phone | optional, Kenyan number is fine |
| Website | `https://akira-flow-privacy.vercel.app/support` |
| External marketing | No, unless you really will run ads |

---

## 4. App content declarations (required)

Complete every item under **Monitor and improve → Policy and programmes → App content** (or **Policy → App content**).

### Privacy policy (required)

URL:

```
https://akira-flow-privacy.vercel.app/
```

`/privacy` is the same page: `https://akira-flow-privacy.vercel.app/privacy`

### Ads

Does your app contain ads? **No**.

### App access

All features are available after sign-in. Provide:

- A demo Google/email account Play reviewers can use
- Password
- Notes: “Sign in, pick Food Vendors if asked, open Dashboard then Sales.”

If Google Sign-In is still in Testing mode, add the reviewer Gmail as a test user in Google Cloud OAuth consent.

### Content ratings

Start the IARC questionnaire.

Typical answers for this app:

- No violence, sexual content, drugs, or gambling
- Users share business/customer info (names, phones) → say **yes** to user-generated / personal info if asked
- No social features like public chat rooms
- Expected rating: **PEGI 3 / Everyone** (confirm what the questionnaire returns)

### Target audience

- Age groups: **18 and over** only
- Not directed at children
- Appeal: **No** (not appealing to children)

### News app

**No**.

### COVID-19 contact tracing / status

**No**.

### Data safety

Start with **Does your app collect or share user data?** → **Yes**.

Declare these types (Collected = yes, Shared as noted). Encryption in transit = **Yes**. Users can request deletion = **Yes**.

| Data type | Collected | Shared | Why |
|-----------|-----------|--------|-----|
| Name | Yes | No | Account |
| Email | Yes | Google (sign-in only) | Account |
| User IDs | Yes | No | Account |
| Phone number | Yes | Safaricom M-Pesa for STK | Customers + STK |
| Photos | Yes | No | Product images |
| Contacts | Yes (on device; uploaded only if saved as a customer) | No unless saved | Add customer |
| App activity / other user-generated content (sales, stock, expenses) | Yes | No | Core POS |
| Purchase history / financial info (sale amounts, M-Pesa receipts) | Yes | Safaricom for the STK request | Payments |

Not collected: precise location, SMS, files unrelated to product photos, health, contacts of people you never save.

Approximate location: **No**.

Data is used for **App functionality** and **Account management**. Not sold. Not used for ads.

### Government apps

**No**.

### Financial features

Your app **collects money for the merchant via M-Pesa**. Declare **Payments** / similar payment option if shown. Not a bank, not crypto, not loans, not a stored-value wallet for consumers.

### Health

**No**.

### Foreground services / photos and videos permissions

If asked: camera and photos are for **product images** the shop owner adds. Contacts are for **adding customers**. Notifications are for **optional sales reminders**.

---

## 5. Countries and pricing

**Test and release → Production** is locked until testing is done. You can still set:

- Countries: start with **Kenya** only (add East Africa later)
- Price: **Free**

---

## 6. Play App Signing + first AAB

1. **Test and release → App integrity → App signing** — leave Play App Signing **on** (default).
2. Copy the **App signing key certificate SHA-1** into Google Cloud → Android OAuth client.
3. Build the bundle on your machine (release signing already uses `android/key.properties`):

```bash
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://akira-flow-api.onrender.com \
  --dart-define=GOOGLE_WEB_CLIENT_ID=445326255543-m8hh5al6s529h1c97h4v1ueif4e0hdgd.apps.googleusercontent.com
```

Upload:

`build/app/outputs/bundle/release/app-release.aab`

The AAB must keep `applicationId` **`app.akirabizhub.pos`**.

---

## 7. Closed testing (needed before Production on newer personal accounts)

If Play Console says you must test first (accounts created after 13 Nov 2023):

1. **Test and release → Testing → Closed testing → Create track**.
2. Upload the same AAB.
3. Add **at least 12 testers** (Gmail addresses) → they must open the opt-in link and install from Play.
4. Keep **12 opted-in for 14 continuous days**.
5. Testers should actually open the app (sign in, record a sale).
6. Then **Apply for production** from the Dashboard and answer the questionnaire with real feedback you collected.

Organization Play accounts may skip this — follow what your Dashboard shows.

---

## 8. After you click Publish

Review usually takes a few days. Common rejects:

| Issue | Fix |
|-------|-----|
| Privacy URL 404 | Confirm `https://akira-flow-privacy.vercel.app/` loads |
| Google Sign-In error 10 / 28444 | Add Play App Signing SHA-1 in Google Cloud |
| Misleading screenshots | Replace marketing shots with captures from a real signed-in session |
| Incomplete Data safety | Match contacts, photos, and M-Pesa sharing |
| Login wall with no demo account | Fill App access with a reviewer login |

---

## Graphic files (ready to upload)

```
store/play/graphics/
  icon-512.png
  feature-graphic-1024x500.jpg
  01-dashboard-1080x1920.jpg
  02-sales-1080x1920.jpg
  03-inventory-1080x1920.jpg
  04-assistant-1080x1920.jpg
  05-login-1080x1920.jpg
  06-business-types-1080x1920.jpg
  07-dashboard-1920x1080-landscape.jpg
```

These screenshots are branded listing images that match Akira Flow’s real screens (dashboard, sales + M-Pesa STK, inventory, assistant, login, business types). When you can, also capture the same screens on a physical phone after signing in — Play prefers real UI if review ever questions a mockup.
