<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <meta name="csrf-token" content="{{ csrf_token() }}">
        <title>@yield('title', 'Akira Bites')</title>

        <link rel="preconnect" href="https://fonts.bunny.net">
        <link href="https://fonts.bunny.net/css?family=dm-sans:400,500,600,700|instrument-sans:400,500,600" rel="stylesheet" />
        @vite(['resources/css/app.css', 'resources/js/app.js'])

        <style>
            :root {
                --akira-primary: #FF6B35;
                --akira-black: #1A1A1A;
            }

            @keyframes splashFadeIn {
                0% { opacity: 0; transform: translateY(10px) scale(0.98); }
                100% { opacity: 1; transform: translateY(0) scale(1); }
            }

            @keyframes floatCard {
                0%, 100% { transform: translateY(0); }
                50% { transform: translateY(-10px); }
            }

            .splash-anim {
                animation: splashFadeIn 700ms ease-out both;
            }

            .float-1 { animation: floatCard 2.2s ease-in-out infinite; }
            .float-2 { animation: floatCard 2.6s ease-in-out infinite; animation-delay: 120ms; }
            .float-3 { animation: floatCard 2.9s ease-in-out infinite; animation-delay: 240ms; }
        </style>
    </head>
    <body class="min-h-screen bg-[var(--akira-surface)] font-sans antialiased flex items-center justify-center">
        @yield('content')
        @yield('scripts')
    </body>
</html>

