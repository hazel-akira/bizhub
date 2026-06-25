#!/usr/bin/env bash
# Start the Akira Bites Laravel API (frees port 8000 first).
set -euo pipefail
cd "$(dirname "$0")/../services/api"

PORT="${1:-8000}"

if command -v fuser >/dev/null 2>&1; then
  fuser -k "${PORT}/tcp" 2>/dev/null || true
  sleep 1
fi

pkill -f "artisan serve.*--port=${PORT}" 2>/dev/null || true
sleep 1

php artisan config:clear
echo ""
echo "  Akira Bites API"
echo "  http://127.0.0.1:${PORT}"
echo "  Health: http://127.0.0.1:${PORT}/api/health"
echo ""
exec php artisan serve --host=0.0.0.0 --port="$PORT"
