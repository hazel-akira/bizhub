@extends('layouts.order')

@section('title', 'Menu')

@section('content')
<div class="px-[20px] pt-[24px] pb-[8px]">
    <h1 class="text-[24px] font-bold text-[var(--akira-black)]">Our Menu</h1>
    <p class="mt-[6px] text-[14px] text-gray-600">Fresh samosas, made to order</p>
</div>

<div class="px-[16px] pt-[16px] pb-[24px]">
    <div id="menu-loading" class="text-center py-12 text-gray-500">
        Loading menu...
    </div>

    <div id="menu-grid" class="hidden">
        {{-- Products rendered by JS --}}
    </div>

    <div id="menu-error" class="hidden text-center py-12 text-red-600">
        Could not load menu. Please refresh.
    </div>
</div>

@push('scripts')
<script>
    document.addEventListener('DOMContentLoaded', () => {
        if (window.OrderApp) {
            window.OrderApp.init();
            window.OrderApp.loadMenu();
        }
    });
</script>
@endpush
@endsection
