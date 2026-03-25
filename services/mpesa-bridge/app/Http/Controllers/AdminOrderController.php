<?php

namespace App\Http\Controllers;

use App\Models\Order;
use Illuminate\Http\JsonResponse;
use Illuminate\View\View;

class AdminOrderController extends Controller
{
    /**
     * Admin page to view orders.
     */
    public function index(): View
    {
        return view('admin.orders');
    }

    /**
     * API: List orders (for admin).
     */
    public function list(): JsonResponse
    {
        $orders = Order::orderByDesc('created_at')->limit(100)->get();

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
