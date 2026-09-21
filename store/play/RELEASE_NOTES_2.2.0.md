# Akira Flow — Release 2.2.0 (version code 6)

## What's new

- **Role-based access** — Cashiers, stock, and managers only see pages they are allowed to use
- **Forgot password** — Staff can request a 6-digit email code and set a new password
- **Clearer bottom navigation** — Every tab now shows its name under the icon
- **Safer dashboard & reports** — Profit, costs, and staff tools stay hidden without permission

## Play Console — release notes (paste into "Release notes")

```
What's new in 2.2.0:
• Staff only see pages allowed by their role
• Forgot password with a 6-digit reset code
• Bottom navigation now shows names under icons
• Profit, costs, and staff tools hidden without permission
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

Bump `version` in `pubspec.yaml` first — format is `NAME+CODE` (e.g. `2.2.0+6`). The number after `+` must always increase.
