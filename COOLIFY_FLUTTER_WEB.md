# Coolify Deployment — Akira Bites Flutter Web

Host the BizHub Flutter app as a static web app (nginx). The Laravel API is a **separate** Coolify application in `services/api`.

---

## Quick Start

| Setting | Value |
|---------|--------|
| **Repository** | `hazel-akira/bizhub` (same repo as API) |
| **Base directory** | `/` (repository root) |
| **Build pack** | Dockerfile |
| **Dockerfile** | `Dockerfile.web` |
| **Port (exposed)** | `80` |
| **Port mappings** | *(leave empty)* |
| **Domain** | `https://app.akirabites.shop` (or your choice) |

---

## 1. Create a new Coolify application

Do **not** reuse the API app — create a **second** application in the same project:

1. **New Resource** → **Application** → same Git repo
2. Base directory: **empty** or `/`
3. Dockerfile: **`Dockerfile.web`**
4. Port exposes: **`80`**
5. Port mappings: **empty**
6. Domain: e.g. `https://app.akirabites.shop`

---

## 2. Build-time environment variable

The API URL is baked into the web build at compile time.

| Variable | Value | Buildtime? |
|----------|-------|------------|
| `API_BASE_URL` | `https://api.akirabites.shop` | **Yes** |

In Coolify → Environment Variables:

- Key: `API_BASE_URL`
- Value: `https://api.akirabites.shop` (no trailing slash)
- **Available at Buildtime**: ON
- Runtime only: OFF

---

## 3. DNS

Add an **A record** at your DNS provider (same server IP as the API):

| Type | Host | Value |
|------|------|-------|
| A | `app` | `52.149.96.127` |

(Replace IP with your Coolify server IP if different.)

---

## 4. Deploy

Push `Dockerfile.web` to `main`, then **Deploy** in Coolify.

First build takes ~5–10 minutes (Flutter SDK download + compile).

Verify:

```bash
curl -sI https://app.akirabites.shop/
```

Open the URL in a browser → login / register should call `https://api.akirabites.shop/api/...`.

---

## Local test before deploy

```bash
flutter build web --release --dart-define=API_BASE_URL=https://api.akirabites.shop

docker build -f Dockerfile.web -t akira-bites-web .
docker run --rm -p 8081:80 akira-bites-web
```

Open http://localhost:8081

---

## Android / Play Store (separate from web hosting)

For the **mobile POS app** on phones, build an App Bundle and upload to Google Play:

```bash
cp android/key.properties.example android/key.properties
# Edit key.properties with your upload keystore

flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://api.akirabites.shop
```

Output: `build/app/outputs/bundle/release/app-release.aab`

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| 502 Bad Gateway | Port exposes = `80`, port mappings empty |
| API calls fail (CORS) | Flutter mobile/web uses bearer tokens; ensure `APP_URL` on API is correct. Web may need `FRONTEND_URL` if browser blocks requests |
| Old API URL in app | Rebuild with correct `API_BASE_URL` build arg |
| Build timeout | Increase Coolify build timeout; first Flutter build is slow |
