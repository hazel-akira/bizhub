#!/usr/bin/env bash
# Print Android Google Sign-In values for Google Cloud Console setup.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/android"

echo "=== Akira Flow — Google Sign-In (Android) ==="
echo ""
echo "Package name: app.akirabizhub.pos"
echo ""
echo "Web client ID (GOOGLE_WEB_CLIENT_ID / serverClientId):"
echo "  445326255543-m8hh5al6s529h1c97h4v1ueif4e0hdgd.apps.googleusercontent.com"
echo ""
echo "SHA-1 fingerprints (add ALL that apply to your Android OAuth client):"
echo ""

if [ -f "$HOME/.android/debug.keystore" ]; then
  echo "Debug (flutter run):"
  keytool -list -v -keystore "$HOME/.android/debug.keystore" \
    -alias androiddebugkey -storepass android -keypass android 2>/dev/null \
    | grep "SHA1:" || true
  echo ""
fi

if [ -f "$ROOT/android/keystores/upload-keystore.jks" ]; then
  echo "Release upload keystore:"
  keytool -list -v -keystore "$ROOT/android/keystores/upload-keystore.jks" 2>/dev/null \
    | grep "SHA1:" || echo "  (run keytool manually — needs keystore password)"
  echo ""
fi

echo "Gradle signing report:"
./gradlew :app:signingReport 2>/dev/null | grep -E "Variant: debug$|Variant: release$|SHA1:" || true
echo ""
echo "Google Cloud Console:"
echo "  https://console.cloud.google.com/apis/credentials"
echo "  → Create OAuth client ID → Android"
echo "  → Package: app.akirabizhub.pos + SHA-1 above"
echo ""
echo "Full guide: docs/GOOGLE_OAUTH_SETUP.md"
