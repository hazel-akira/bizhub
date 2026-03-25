<?php

namespace App\Http\Controllers;

use App\Models\StkRequest;
use Illuminate\Http\JsonResponse;

class MpesaStatusController extends Controller
{
    /**
     * Get payment status for a checkout request (polling).
     */
    public function __invoke(string $checkoutRequestId): JsonResponse
    {
        $stk = StkRequest::where('checkout_request_id', $checkoutRequestId)->first();

        if (! $stk) {
            return response()->json(['message' => 'Unknown checkout request'], 404);
        }

        return response()->json([
            'status' => $stk->status,
            'reference' => $stk->reference,
            'mpesa_receipt_number' => $stk->mpesa_receipt_number,
        ]);
    }
}
