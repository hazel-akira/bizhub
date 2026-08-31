#!/bin/sh
set -e

cd /var/www/html

echo "[entrypoint] Starting Akira Bites API..."

if [ "${APP_ENV:-local}" = "production" ]; then
    missing=""
    for var in DB_CONNECTION DB_HOST DB_DATABASE DB_USERNAME DB_PASSWORD APP_KEY; do
        eval "val=\${$var:-}"
        if [ -z "$val" ]; then
            missing="$missing $var"
        fi
    done
    if [ -n "$missing" ]; then
        echo "[entrypoint] ERROR: Missing required production env:$missing"
        exit 1
    fi
    if [ "${DB_CONNECTION}" != "pgsql" ]; then
        echo "[entrypoint] ERROR: DB_CONNECTION must be pgsql in production (got: ${DB_CONNECTION})."
        exit 1
    fi
fi

# Neon "pooled" host breaks Laravel migrations — auto-switch to direct host.
if echo "${DB_HOST:-}" | grep -q '\-pooler\.'; then
    DB_HOST="$(printf '%s' "$DB_HOST" | sed 's/-pooler\././')"
    export DB_HOST
    echo "[entrypoint] WARNING: Neon pooler host detected; using direct host for migrations: ${DB_HOST}"
fi

# Wait for PostgreSQL when configured
if [ "${DB_CONNECTION:-}" = "pgsql" ] && [ -n "${DB_HOST:-}" ]; then
    echo "[entrypoint] Waiting for PostgreSQL at ${DB_HOST}:${DB_PORT:-5432}..."
    until pg_isready -h "$DB_HOST" -p "${DB_PORT:-5432}" -U "${DB_USERNAME:-postgres}" -q; do
        sleep 2
    done
    echo "[entrypoint] PostgreSQL is ready."
fi

# Ensure writable directories (supports mounted volumes)
mkdir -p \
    storage/app/public \
    storage/app/private \
    storage/framework/cache/data \
    storage/framework/sessions \
    storage/framework/views \
    storage/logs \
    bootstrap/cache

chown -R www-data:www-data storage bootstrap/cache database
chmod -R 775 storage bootstrap/cache database

# Public storage symlink for product images
php artisan storage:link --force 2>/dev/null || true

# Database migrations
if [ "${RUN_MIGRATIONS:-true}" = "true" ]; then
    echo "[entrypoint] Running migrations..."
    php artisan migrate --force --no-interaction
fi

# Optional seed (global catalog) — disabled by default in production
if [ "${RUN_SEEDER:-false}" = "true" ]; then
    echo "[entrypoint] Running database seeders..."
    php artisan db:seed --force --no-interaction
fi

# Laravel optimization
if [ "${APP_ENV:-local}" = "production" ]; then
    echo "[entrypoint] Caching configuration for production..."
    php artisan config:cache
    php artisan route:cache
    php artisan view:cache
    php artisan event:cache
else
    php artisan config:clear --quiet || true
    php artisan route:clear --quiet || true
    php artisan view:clear --quiet || true
fi

# config:cache creates root-owned files — php-fpm runs as www-data.
chown -R www-data:www-data storage bootstrap/cache database
chmod -R 775 storage bootstrap/cache database

echo "[entrypoint] Ready — handing off to supervisord."
exec "$@"
