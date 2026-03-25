@extends('layouts.order')

@section('title', 'Your Cart')

@section('content')
<div class="max-w-2xl mx-auto">
    <h1 class="text-2xl font-bold text-[var(--akira-black)] mb-6">Your Cart</h1>

    <div id="cart-empty" class="hidden text-center py-12 bg-white rounded-2xl shadow-sm">
        <div class="w-20 h-20 mx-auto mb-4 rounded-full bg-orange-100 flex items-center justify-center">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-10 w-10 text-orange-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z" />
            </svg>
        </div>
        <p class="text-gray-600 mb-2">Your cart is empty</p>
        <p class="text-sm text-gray-500 mb-6">Add some delicious samosas from the menu!</p>
        <a href="{{ route('order.menu') }}" class="inline-flex items-center gap-2 px-6 py-3 bg-[var(--akira-primary)] text-white font-semibold rounded-xl hover:bg-[var(--akira-primary-dark)] transition">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
            </svg>
            Browse Menu
        </a>
    </div>

    <div id="cart-items" class="hidden space-y-4 mb-6">
        {{-- Cart items rendered by JS --}}
    </div>

    <div id="cart-footer" class="hidden fixed bottom-0 left-0 right-0 bg-white border-t shadow-lg p-4 safe-area-pb">
        <div class="container mx-auto max-w-2xl">
            <div class="flex items-center justify-between">
                <div>
                    <span class="text-sm text-gray-600">Total</span>
                    <p id="cart-total" class="text-xl font-bold text-[var(--akira-primary)]">KSh 0</p>
                </div>
            </div>

            <div class="h-4"></div>

            <button type="button" id="cart-whatsapp-btn"
                class="w-full py-4 bg-[var(--akira-primary)] text-white font-semibold rounded-xl hover:bg-[var(--akira-primary-dark)] transition flex items-center justify-center gap-2">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 10h.01M12 10h.01M16 10h.01M21 12c0 4-4 7-9 7a15.3 15.3 0 01-4.5-.7L3 20l1.2-3.6A6.2 6.2 0 013 12c0-4 4-7 9-7s9 3 9 7z" />
                </svg>
                Order via WhatsApp
            </button>

            <div class="h-3"></div>

            <a href="{{ route('order.checkout') }}"
                class="w-full inline-flex items-center justify-center text-sm font-semibold text-[var(--akira-primary)] hover:underline">
                Pay with M-Pesa
            </a>
        </div>
    </div>
</div>

@push('scripts')
<script>
    document.addEventListener('DOMContentLoaded', () => {
        if (window.OrderApp) {
            window.OrderApp.init();
            window.OrderApp.renderCart();
            window.OrderApp.initCartWhatsApp();
        }
    });
</script>
@endpush
@endsection
