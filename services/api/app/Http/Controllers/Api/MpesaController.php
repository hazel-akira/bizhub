<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Concerns\RespondsWithJson;
use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Services\MpesaService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MpesaController extends Controller
{
    use RespondsWithJson;

    public function __construct(private readonly MpesaService $mpesa) {}

    public function stkPush(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'order_id' => ['required', 'integer', 'exists:orders,id'],
        ]);

        $order = Order::findOrFail($validated['order_id']);

        if ($order->user_id !== $request->user()->id) {
            return $this->error('Order not found', 404);
        }

        if ($order->payment_status === 'paid') {
            return $this->error('Order is already paid');
        }

        $transaction = $this->mpesa->initiateStkForOrder($order);

        return $this->success([
            'checkout_request_id' => $transaction->checkout_request_id,
            'status' => 'processing',
        ]);
    }

    /**
     * Flutter app endpoint (unpaid screen).
     */
    public function stk(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'amount' => ['required', 'numeric', 'min:1'],
            'phone' => ['required', 'string', 'max:20'],
            'reference' => ['required', 'string', 'max:100'],
        ]);

        $result = $this->mpesa->initiateStk(
            (float) $validated['amount'],
            $validated['phone'],
            $validated['reference'],
        );

        return response()->json($result, 201);
    }

    public function status(string $checkoutRequestId): JsonResponse
    {
        $transaction = $this->mpesa->getStatus($checkoutRequestId);

        if (! $transaction) {
            return $this->error('Unknown checkout request', 404);
        }

        return response()->json([
            'status' => $transaction->status,
            'reference' => $transaction->reference,
            'mpesa_receipt_number' => $transaction->mpesa_receipt_number,
        ]);
    }

    public function callback(Request $request): JsonResponse
    {
        $this->mpesa->handleCallback($request->all());

        return response()->json(['ResultCode' => 0, 'ResultDesc' => 'Accepted']);
    }
}
