# syntax=docker/dockerfile:1

# -----------------------------------------------------------------------------
# Stage 1 — Install PHP dependencies (no dev packages)
# -----------------------------------------------------------------------------
FROM composer:2 AS vendor

WORKDIR /app

COPY composer.json composer.lock ./

RUN composer install \
    --no-dev \
    --no-interaction \
    --no-scripts \
    --prefer-dist \
    --optimize-autoloader

COPY . .

RUN composer dump-autoload --optimize --classmap-authoritative \
    && php artisan package:discover --ansi

# -----------------------------------------------------------------------------
# Stage 2 — Production runtime (PHP 8.3-FPM + Nginx + Supervisor)
# -----------------------------------------------------------------------------
FROM php:8.3-fpm-bookworm

LABEL maintainer="BizHub" \
      org.opencontainers.image.title="Akira Bites API" \
      org.opencontainers.image.description="Laravel 13 API for BizHub"

RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx \
    supervisor \
    curl \
    postgresql-client \
    libpq5 \
    libzip4 \
    libpq-dev \
    libzip-dev \
    && docker-php-ext-install -j"$(nproc)" \
        opcache \
        pdo \
        pdo_pgsql \
        zip \
        bcmath \
    && apt-get purge -y libpq-dev libzip-dev \
    && rm -rf /var/lib/apt/lists/* /tmp/*

COPY docker/php/php.ini /usr/local/etc/php/conf.d/99-laravel.ini
COPY docker/php/opcache.ini /usr/local/etc/php/conf.d/opcache.ini
COPY docker/nginx/default.conf /etc/nginx/conf.d/default.conf
COPY docker/supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY docker/scripts/entrypoint.sh /usr/local/bin/entrypoint.sh

WORKDIR /var/www/html

COPY --from=vendor /app /var/www/html

RUN rm -f /etc/nginx/sites-enabled/default \
    && chmod +x /usr/local/bin/entrypoint.sh \
    && mkdir -p storage/framework/{cache,sessions,views} storage/logs bootstrap/cache \
    && chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=90s --retries=3 \
    CMD curl -fsS http://127.0.0.1:8080/up || exit 1

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
