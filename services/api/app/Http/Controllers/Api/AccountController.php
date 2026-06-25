<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Concerns\RespondsWithJson;
use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AccountController extends Controller
{
    use RespondsWithJson;

    public function orders(Request $request): JsonResponse
    {
        $orders = $request->user()
            ->orders()
            ->latest()
            ->get()
            ->map(fn ($order) => [
                'id' => $order->id,
                'total_amount' => $order->total_amount,
                'payment_status' => $order->payment_status,
                'mpesa_receipt' => $order->mpesa_receipt,
                'created_at' => $order->created_at?->toIso8601String(),
            ]);

        return $this->success($orders);
    }
}
