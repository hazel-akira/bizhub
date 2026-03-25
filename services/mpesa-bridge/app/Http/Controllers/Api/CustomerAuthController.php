<?php

namespace App\Http\Controllers\Api;

use App\Models\Order;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;

class CustomerAuthController extends \App\Http\Controllers\Controller
{
    public function register(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'max:255', 'unique:users,email'],
            'password' => ['required', 'string', 'min:8', 'confirmed'],
        ]);

        $user = User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'password' => Hash::make($validated['password']),
        ]);

        $token = $user->createToken('customer')->plainTextToken;

        return response()->json([
            'data' => [
                'access_token' => $token,
                'token_type' => 'Bearer',
            ],
        ]);
    }

    public function login(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'email' => ['required', 'email', 'max:255'],
            'password' => ['required', 'string'],
        ]);

        $user = User::where('email', $validated['email'])->first();

        if (! $user || ! Hash::check($validated['password'], $user->password)) {
            return response()->json(['message' => 'Invalid credentials'], 401);
        }

        $token = $user->createToken('customer')->plainTextToken;

        return response()->json([
            'data' => [
                'access_token' => $token,
                'token_type' => 'Bearer',
            ],
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $user = Auth::guard('sanctum')->user();
        if ($user && $user->currentAccessToken()) {
            $user->currentAccessToken()->delete();
        }

        return response()->json(['message' => 'Logged out']);
    }

    public function myOrders(Request $request): JsonResponse
    {
        $userId = Auth::guard('sanctum')->id();

        if (! $userId) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        $orders = Order::query()
            ->where('user_id', $userId)
            ->orderByDesc('created_at')
            ->limit(50)
            ->get();

        return response()->json([
            'data' => $orders->map(fn (Order $o) => [
                'id' => $o->id,
                'items' => $o->items,
                'total_amount' => $o->total_amount,
                'phone_number' => $o->phone_number,
                'payment_status' => $o->payment_status,
                'mpesa_receipt' => $o->mpesa_receipt,
                'created_at' => $o->created_at->toIso8601String(),
            ]),
        ]);
    }
}

