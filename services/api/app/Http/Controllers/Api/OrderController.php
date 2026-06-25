<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Concerns\RespondsWithJson;
use App\Http\Controllers\Controller;
use App\Models\Order;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class OrderController extends Controller
{
    use RespondsWithJson;

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'items' => ['required', 'array', 'min:1'],
            'items.*.product_id' => ['required', 'integer'],
            'items.*.name' => ['required', 'string', 'max:255'],
            'items.*.price' => ['required', 'integer', 'min:1'],
            'items.*.quantity' => ['required', 'integer', 'min:1'],
            'phone_number' => ['required', 'regex:/^0[17]\d{8}$/'],
        ]);

        $order = DB::transaction(function () use ($request, $validated) {
            $total = collect($validated['items'])->sum(
                fn (array $item) => $item['price'] * $item['quantity']
            );

            $order = Order::create([
                'user_id' => $request->user()->id,
                'phone_number' => $validated['phone_number'],
                'total_amount' => $total,
                'payment_status' => 'pending',
            ]);

            foreach ($validated['items'] as $item) {
                $order->items()->create([
                    'product_id' => $item['product_id'],
                    'name' => $item['name'],
                    'price' => $item['price'],
                    'quantity' => $item['quantity'],
                ]);
            }

            return $order->load('items');
        });

        return $this->success($this->formatOrder($order), 201);
    }

    public function show(Request $request, Order $order): JsonResponse
    {
        if ($order->user_id !== $request->user()->id) {
            return $this->error('Order not found', 404);
        }

        return $this->success($this->formatOrder($order->load('items')));
    }

    private function formatOrder(Order $order): array
    {
        return [
            'id' => $order->id,
            'phone_number' => $order->phone_number,
            'total_amount' => $order->total_amount,
            'payment_status' => $order->payment_status,
            'mpesa_receipt' => $order->mpesa_receipt,
            'checkout_request_id' => $order->checkout_request_id,
            'items' => $order->items->map(fn ($item) => [
                'product_id' => $item->product_id,
                'name' => $item->name,
                'price' => $item->price,
                'quantity' => $item->quantity,
            ])->values(),
            'created_at' => $order->created_at?->toIso8601String(),
        ];
    }
}
