# Akira Flow — Release 2.1.0 (version code 5)

## What's new

- **Staff roles** — Add team members with owner, manager, or cashier access
- **Smarter profit tracking** — Sales now record unit cost for accurate daily profit
- **Expanded business catalogs** — More starter products for Kenyan shop types
- **Improved dashboard & reports** — Clearer sales, expenses, and profit summaries
- **Backup export** — Export your shop data from Settings
- **Inventory & sales polish** — Faster product search, category filters, and quick sale flow

## Play Console — release notes (paste into "Release notes")

```
What's new in 2.1.0:
• Add staff with owner, manager, or cashier roles
• More accurate profit tracking with unit costs on sales
• Expanded product catalogs for Kenyan businesses
• Improved dashboard, reports, and inventory screens
• Export shop data backup from Settings
```

## Upload steps

1. Open [Play Console](https://play.google.com/console) → **Akira Flow**
2. Go to **Test and release** → **Production** (or your active track)
3. Click **Create new release**
4. Upload the AAB:

   ```
   build/app/outputs/bundle/release/app-release.aab
   ```

5. Paste the release notes above
6. Review and **Start rollout to Production**

## Build command (for future releases)

```bash
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://akira-flow-api.onrender.com \
  --dart-define=GOOGLE_WEB_CLIENT_ID=445326255543-m8hh5al6s529h1c97h4v1ueif4e0hdgd.apps.googleusercontent.com
```

Bump `version` in `pubspec.yaml` first — format is `NAME+CODE` (e.g. `2.1.0+5`). The number after `+` must always increase.
