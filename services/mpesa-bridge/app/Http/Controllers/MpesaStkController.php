<?php

namespace App\Http\Controllers;

use App\Models\Order;
use App\Services\MpesaService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class MpesaStkController extends Controller
{
    protected function tokenUserId(): ?int
    {
        // Sanctum bearer token user id (or null if no token provided)
        return Auth::guard('sanctum')->id();
    }

    /**
     * Initiate STK Push for an order.
     * Request: { amount, phone, reference } or { order_id }
     */
    public function __invoke(Request $request): JsonResponse
    {
        $orderId = $request->input('order_id');
        if ($orderId) {
            $order = Order::find($orderId);
            if (! $order) {
                return response()->json(['message' => 'Order not found'], 404);
            }

            // If this order was created by an authenticated token user, require the same token.
            if ($order->user_id) {
                $tokenUserId = $this->tokenUserId();
                if (! $tokenUserId || (int) $order->user_id !== (int) $tokenUserId) {
                    return response()->json(['message' => 'Order not found'], 404);
                }
            }

            $amount = $order->total_amount;
            $phone = $order->phone_number;
            $reference = 'order_' . $order->id;
        } else {
            $request->validate([
                'amount' => 'required|numeric|min:1',
                'phone' => 'required|string|regex:/^0[17]\d{8}$/',
                'reference' => 'required|string',
            ]);
            $amount = (float) $request->input('amount');
            $phone = $request->input('phone');
            $reference = $request->input('reference');
        }

        $service = MpesaService::fromConfig();

        if (! config('mpesa.consumer_key') || ! config('mpesa.consumer_secret')) {
            return response()->json([
                'message' => 'M-Pesa not configured',
                'checkout_request_id' => null,
                'status' => 'error',
            ], 503);
        }

        if (! config('mpesa.passkey')) {
            return response()->json([
                'message' => 'MPESA_PASSKEY missing. Add your Daraja sandbox passkey in .env.',
                'checkout_request_id' => null,
                'status' => 'error',
            ], 503);
        }

        $callbackUrl = config('mpesa.callback_url');
        if (! $callbackUrl || ! str_starts_with((string) $callbackUrl, 'https://')) {
            return response()->json([
                'message' => 'MPESA_CALLBACK_URL must be set to an HTTPS URL.',
                'checkout_request_id' => null,
                'status' => 'error',
            ], 503);
        }

        $checkoutRequestId = $service->initiateStkPush($amount, $phone, $reference, $orderId ?? null);

        if (! $checkoutRequestId) {
            return response()->json([
                'message' => 'Failed to initiate M-Pesa payment',
                'checkout_request_id' => null,
                'status' => 'error',
            ], 502);
        }

        if ($orderId) {
            Order::where('id', $orderId)->update(['checkout_request_id' => $checkoutRequestId]);
        }

        return response()->json([
            'checkout_request_id' => $checkoutRequestId,
            'status' => 'processing',
        ], 201);
    }
}
