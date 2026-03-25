<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>@yield('title', 'Akira Bites') — Order</title>
    <link rel="preconnect" href="https://fonts.bunny.net">
    <link href="https://fonts.bunny.net/css?family=dm-sans:400,500,600,700|instrument-sans:400,500,600" rel="stylesheet" />
    @vite(['resources/css/app.css', 'resources/js/app.js', 'resources/js/order.js'])
    <style>
        :root {
            --akira-primary: #FF6B35;
            --akira-primary-dark: #E55A2B;
            --akira-black: #1A1A1A;
            --akira-surface: #F5F5F5;
        }
    </style>
</head>
<body class="min-h-screen bg-[var(--akira-surface)] font-sans antialiased">
    <header class="bg-[var(--akira-primary)] text-white sticky top-0 z-10">
        <div class="h-[56px] px-[16px] flex items-center">
            <div class="w-[44px]"></div>
            <div class="flex-1 text-center">
                <a href="{{ route('order.menu') }}" class="text-xl font-bold tracking-tight">Akira Bites</a>
            </div>
            <a href="{{ route('order.cart') }}"
                class="relative inline-flex items-center justify-center w-[44px] h-[44px]">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-[26px] h-[26px]" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z" />
                </svg>
                <span id="cart-badge"
                    class="hidden absolute top-[4px] right-[4px] min-w-[20px] min-h-[20px] bg-[var(--akira-black)] rounded-full px-[5px] py-[2px] text-[11px] font-bold flex items-center justify-center">
                    <span id="cart-badge-count">0</span>
                </span>
            </a>
        </div>
    </header>

    <main class="container mx-auto px-4 py-6 pb-24">
        @yield('content')
    </main>

    @if (request()->is('admin/orders'))
        <footer class="py-4 text-center text-sm text-gray-500">
            <a href="{{ route('order.menu') }}" class="hover:text-gray-700">Back to Menu</a>
        </footer>
    @endif

    <script>
        document.addEventListener('DOMContentLoaded', () => {
            if (window.OrderApp) window.OrderApp.init();
        });
    </script>
    @stack('scripts')
</body>
</html>
