@extends('layouts.auth')

@section('title', 'Register')

@section('content')
<div class="bg-white rounded-[16px] shadow-sm p-6">
    <div class="text-center">
        <img src="/assets/images/akira-logo.png" alt="Akira Bites" class="mx-auto w-[160px] mb-2">
        <h1 class="text-2xl font-bold text-[var(--akira-black)]">Create Account</h1>
        <p class="mt-2 text-sm text-gray-600">Fast checkout & order history</p>
    </div>

    @if ($errors->any())
        <div class="mt-4 bg-red-50 border border-red-200 text-red-700 rounded-xl p-3 text-sm">
            {{ $errors->first() }}
        </div>
    @endif

    <form method="POST" action="{{ route('register') }}" class="mt-6 space-y-4">
        @csrf
        <div>
            <label for="name" class="block text-sm font-medium text-gray-700 mb-2">Name</label>
            <input id="name" name="name" type="text" required
                class="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-orange-500 focus:border-orange-500"
                value="{{ old('name') }}">
        </div>
        <div>
            <label for="email" class="block text-sm font-medium text-gray-700 mb-2">Email</label>
            <input id="email" name="email" type="email" required
                class="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-orange-500 focus:border-orange-500"
                value="{{ old('email') }}">
        </div>
        <div>
            <label for="password" class="block text-sm font-medium text-gray-700 mb-2">Password</label>
            <input id="password" name="password" type="password" required
                class="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-orange-500 focus:border-orange-500">
        </div>
        <div>
            <label for="password_confirmation" class="block text-sm font-medium text-gray-700 mb-2">Confirm Password</label>
            <input id="password_confirmation" name="password_confirmation" type="password" required
                class="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-orange-500 focus:border-orange-500">
        </div>
        <button type="submit"
            class="w-full mt-2 py-4 bg-[var(--akira-primary)] text-white font-semibold rounded-xl hover:bg-[var(--akira-primary-dark)] transition">
            Create account
        </button>
    </form>

    <div class="mt-4 text-center text-sm text-gray-600">
        Already have an account?
        <a href="{{ route('login') }}" class="text-[var(--akira-primary)] font-semibold hover:underline">Login</a>
    </div>
</div>
@endsection

