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
                --akira-surface: #F5F5F5;
            }
        </style>
    </head>
    <body class="min-h-screen bg-[var(--akira-surface)] font-sans antialiased">
        <main class="min-h-screen flex items-center justify-center px-6">
            <div class="w-full max-w-md">
                @yield('content')
            </div>
        </main>
    </body>
</html>

