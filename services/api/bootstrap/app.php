<?php

use App\Http\Middleware\EnsureBusinessAccess;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        channels: __DIR__.'/../routes/channels.php',
        health: '/up',
        apiPrefix: 'api',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        // Reverse proxy (Fly.io / nginx): honor X-Forwarded-* for HTTPS URLs and client IPs.
        $middleware->trustProxies(
            at: env('TRUSTED_PROXIES', '*'),
            headers: Request::HEADER_X_FORWARDED_FOR
                | Request::HEADER_X_FORWARDED_HOST
                | Request::HEADER_X_FORWARDED_PORT
                | Request::HEADER_X_FORWARDED_PROTO,
        );

        $middleware->statefulApi();
        $middleware->alias([
            'business' => EnsureBusinessAccess::class,
        ]);

        // Safaricom posts to /api/mpesa/callback with no CSRF token.
        // Laravel 11+ moved VerifyCsrfToken exceptions here (there is no app/Http/Middleware/VerifyCsrfToken.php).
        $middleware->validateCsrfTokens(except: [
            'api/mpesa/callback',
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->shouldRenderJsonWhen(
            fn (Request $request) => $request->is('api/*'),
        );
    })->create();
