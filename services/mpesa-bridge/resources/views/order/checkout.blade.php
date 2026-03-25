@extends('layouts.order')

@section('title', 'Checkout')

@section('content')
<div class="max-w-md mx-auto">
    <h1 class="text-2xl font-bold text-[var(--akira-black)] mb-6">Checkout</h1>

    <div id="checkout-empty" class="hidden text-center py-12 bg-white rounded-2xl shadow-sm">
        <p class="text-gray-600 mb-4">Your cart is empty</p>
        <a href="{{ route('order.menu') }}" class="text-[var(--akira-primary)] font-semibold hover:underline">Back to Menu</a>
    </div>

    <form id="checkout-form" class="hidden space-y-6">
        @csrf
        <div class="bg-white rounded-2xl shadow-sm p-6 space-y-4">
            <div id="checkout-summary" class="text-sm text-gray-600">
                {{-- Rendered by JS --}}
            </div>
            <p class="text-xl font-bold text-[var(--akira-primary)]">
                Total: <span id="checkout-total">KSh 0</span>
            </p>
        </div>

        <div class="bg-white rounded-2xl shadow-sm p-6">
            <label for="phone" class="block text-sm font-medium text-gray-700 mb-2">M-Pesa Phone Number</label>
            <input type="tel" id="phone" name="phone" placeholder="07XXXXXXXX" required
                class="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-orange-500 focus:border-orange-500"
                pattern="0[17]\d{8}">
            <p class="mt-1 text-xs text-gray-500">Format: 07XXXXXXXX (e.g. 0712345678)</p>
        </div>

        <button type="submit" id="pay-btn" class="w-full py-4 bg-[var(--akira-primary)] text-white font-semibold rounded-xl hover:bg-[var(--akira-primary-dark)] transition flex items-center justify-center gap-2">
            <span id="pay-btn-text">Pay with M-Pesa</span>
            <span id="pay-btn-loading" class="hidden">
                <svg class="animate-spin h-5 w-5" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                    <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                    <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
            </span>
        </button>
    </form>
</div>

@push('scripts')
<script>
    document.addEventListener('DOMContentLoaded', () => {
        OrderApp.init();
        OrderApp.initCheckout();
    });
</script>
@endpush
@endsection
