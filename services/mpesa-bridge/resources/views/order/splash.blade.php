@extends('layouts.splash')

@section('title', 'Welcome')

@section('content')
<div class="w-full max-w-md px-6 text-center">
    <div class="splash-anim">
        <img
            src="/assets/images/akira-logo.png"
            alt="Akira Bites"
            class="mx-auto w-[220px] h-auto drop-shadow"
        />
        <p class="mt-4 text-[14px] text-gray-600">
            Fresh samosas, made to order
        </p>
    </div>

    <div class="mt-10 grid grid-cols-2 gap-4 splash-anim">
        <div class="bg-white rounded-[16px] shadow-sm overflow-hidden float-1">
            <div class="aspect-[4/3] bg-gray-100 flex items-center justify-center overflow-hidden">
                <img class="w-full h-full object-cover" src="/assets/images/beef_samosa.png" alt="Beef Samosa">
            </div>
            <div class="p-3 text-left">
                <p class="font-semibold text-[#1A1A1A] text-[13px] leading-[1.2]">Beef Samosa</p>
                <p class="mt-1 font-bold text-[#FF6B35] text-[13px]">KSh 40</p>
            </div>
        </div>

        <div class="bg-white rounded-[16px] shadow-sm overflow-hidden float-2">
            <div class="aspect-[4/3] bg-gray-100 flex items-center justify-center overflow-hidden">
                <img class="w-full h-full object-cover" src="/assets/images/ndengu_samosa.png" alt="Ndengu Samosa">
            </div>
            <div class="p-3 text-left">
                <p class="font-semibold text-[#1A1A1A] text-[13px] leading-[1.2]">Ndengu Samosa</p>
                <p class="mt-1 font-bold text-[#FF6B35] text-[13px]">KSh 20</p>
            </div>
        </div>

        <div class="bg-white rounded-[16px] shadow-sm overflow-hidden float-3 col-span-2">
            <div class="aspect-[3/2] bg-gray-100 flex items-center justify-center overflow-hidden">
                <img class="w-full h-full object-cover" src="/assets/images/chicken_samosa.png" alt="Chicken Samosa">
            </div>
            <div class="p-3 text-left flex items-center justify-between">
                <p class="font-semibold text-[#1A1A1A] text-[13px] leading-[1.2]">Chicken Samosa</p>
                <p class="font-bold text-[#FF6B35] text-[13px]">KSh 50</p>
            </div>
        </div>
    </div>

    <div class="mt-10 splash-anim">
        <p class="text-sm text-gray-500">
            Loading...
        </p>
    </div>
</div>
@endsection

@section('scripts')
<script>
    // Splash screen delay before showing the menu.
    setTimeout(() => {
        window.location.href = "{{ route('order.menu') }}";
    }, 2200);
</script>
@endsection

