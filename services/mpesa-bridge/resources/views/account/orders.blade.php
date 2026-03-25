@extends('layouts.order')

@section('title', 'My Orders')

@section('content')
<div class="max-w-2xl mx-auto pt-2">
    <div class="flex items-center justify-between mb-6">
        <div>
            <h1 class="text-2xl font-bold text-[var(--akira-black)]">My Orders</h1>
            <p class="mt-1 text-sm text-gray-600">Your recent order payments and statuses</p>
        </div>

        <form method="POST" action="{{ route('logout') }}">
            @csrf
            <button type="submit" class="px-4 py-2 rounded-xl text-sm font-semibold bg-gray-200 hover:bg-gray-300 transition">
                Logout
            </button>
        </form>
    </div>

    @if ($orders->isEmpty())
        <div class="bg-white rounded-2xl shadow-sm p-6 text-center">
            <p class="text-gray-600">No orders yet.</p>
            <a href="{{ route('order.menu') }}" class="mt-4 inline-block text-[var(--akira-primary)] font-semibold hover:underline">
                Order from the menu
            </a>
        </div>
    @else
        <div class="space-y-4">
            @foreach ($orders as $order)
                <div class="bg-white rounded-2xl shadow-sm p-4 flex items-start justify-between gap-4">
                    <div>
                        <div class="text-sm text-gray-600">Order #{{ $order->id }}</div>
                        <div class="mt-1 font-bold text-[var(--akira-primary)]">KSh {{ $order->total_amount }}</div>
                        <div class="mt-2">
                            @php
                                $status = $order->payment_status;
                                $pillClass = $status === 'paid'
                                    ? 'bg-green-100 text-green-800'
                                    : ($status === 'failed' ? 'bg-red-100 text-red-800' : 'bg-amber-100 text-amber-800');
                            @endphp
                            <span class="px-3 py-1 rounded-full text-sm font-semibold {{ $pillClass }}">
                                {{ $status }}
                            </span>
                        </div>
                        @if ($order->mpesa_receipt)
                            <div class="mt-2 text-xs text-gray-500">
                                Receipt: {{ $order->mpesa_receipt }}
                            </div>
                        @endif
                    </div>

                    <div class="text-right">
                        <a href="{{ route('order.status', ['id' => $order->id]) }}"
                           class="inline-flex items-center justify-center px-4 py-2 rounded-xl bg-[var(--akira-primary)] text-white font-semibold text-sm hover:bg-[var(--akira-primary-dark)] transition">
                            View status
                        </a>
                    </div>
                </div>
            @endforeach
        </div>
    @endif
</div>
@endsection

