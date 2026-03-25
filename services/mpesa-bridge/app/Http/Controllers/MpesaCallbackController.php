<?php

namespace App\Http\Controllers;

use App\Models\Order;
use App\Models\StkRequest;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

/**
 * Safaricom Daraja callback for STK Push result.
 * Updates StkRequest and linked Order with payment status.
 */
class MpesaCallbackController extends Controller
{
    public function __invoke(Request $request): JsonResponse
    {
        $body = $request->all();

        Log::info('M-Pesa callback received', ['body' => $body]);

        $body = $body['Body'] ?? $body;
        $stkCallback = $body['stkCallback'] ?? null;

        if (! $stkCallback) {
            return response()->json(['ResultCode' => 0, 'ResultDesc' => 'OK']);
        }

        $checkoutRequestId = $stkCallback['CheckoutRequestID'] ?? null;
        $resultCode = (int) ($stkCallback['ResultCode'] ?? -1);
        $resultDesc = $stkCallback['ResultDesc'] ?? 'Unknown';

        $stk = $checkoutRequestId
            ? StkRequest::where('checkout_request_id', $checkoutRequestId)->first()
            : null;

        if ($resultCode === 0) {
            $callbackMetadata = $stkCallback['CallbackMetadata']['Item'] ?? [];
            $mpesaReceipt = null;
            foreach ($callbackMetadata as $item) {
                if (($item['Name'] ?? null) === 'MpesaReceiptNumber') {
                    $mpesaReceipt = $item['Value'] ?? null;
                    break;
                }
            }

            if ($stk) {
                $stk->update([
                    'status' => 'completed',
                    'mpesa_receipt_number' => $mpesaReceipt,
                ]);

                $reference = $stk->reference;
                if (preg_match('/^order_(\d+)$/', $reference, $m)) {
                    Order::where('id', $m[1])->update([
                        'payment_status' => 'paid',
                        'mpesa_receipt' => $mpesaReceipt,
                    ]);
                }
            }
        } else {
            if ($stk) {
                $stk->update(['status' => 'failed']);

                $reference = $stk->reference;
                if (preg_match('/^order_(\d+)$/', $reference, $m)) {
                    Order::where('id', $m[1])->update(['payment_status' => 'failed']);
                }
            }
        }

        return response()->json(['ResultCode' => 0, 'ResultDesc' => 'OK']);
    }
}
