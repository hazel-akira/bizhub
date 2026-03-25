<?php

namespace App\Http\Controllers;

use App\Models\Order;
use App\Models\Product;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use Illuminate\Support\Facades\Auth;

class OrderController extends Controller
{
    protected function tokenUserId(): ?int
    {
        // Sanctum bearer token user id (or null if no token provided)
        return Auth::guard('sanctum')->id();
    }

    /**
     * Create a new order (items, total, phone).
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'items' => 'required|array',
            'items.*.product_id' => 'required|integer|exists:products,id',
            'items.*.name' => 'required|string',
            'items.*.price' => 'required|integer|min:0',
            'items.*.quantity' => 'required|integer|min:1',
            'phone_number' => 'required|string|regex:/^0[17]\d{8}$/',
        ]);

        $total = 0;
        $items = [];
        foreach ($validated['items'] as $item) {
            $subtotal = $item['price'] * $item['quantity'];
            $total += $subtotal;
            $items[] = [
                'product_id' => $item['product_id'],
                'name' => $item['name'],
                'price' => $item['price'],
                'quantity' => $item['quantity'],
            ];
        }

        $order = Order::create([
            'items' => $items,
            'total_amount' => $total,
            'phone_number' => $validated['phone_number'],
            'user_id' => $this->tokenUserId(),
            'payment_status' => 'pending',
        ]);

        return response()->json([
            'data' => [
                'id' => $order->id,
                'items' => $order->items,
                'total_amount' => $order->total_amount,
                'phone_number' => $order->phone_number,
                'payment_status' => $order->payment_status,
            ],
        ], 201);
    }

    /**
     * Get order by ID (for status page).
     */
    public function show(int $id): JsonResponse
    {
        $order = Order::find($id);

        if (! $order) {
            return response()->json(['message' => 'Order not found'], 404);
        }

        // If the order belongs to a token user, require the same token.
        if ($order->user_id) {
            $tokenUserId = $this->tokenUserId();
            if (! $tokenUserId || (int) $order->user_id !== (int) $tokenUserId) {
                return response()->json(['message' => 'Order not found'], 404);
            }
        }

        return response()->json([
            'data' => [
                'id' => $order->id,
                'items' => $order->items,
                'total_amount' => $order->total_amount,
                'phone_number' => $order->phone_number,
                'payment_status' => $order->payment_status,
                'mpesa_receipt' => $order->mpesa_receipt,
            ],
        ]);
    }
}
