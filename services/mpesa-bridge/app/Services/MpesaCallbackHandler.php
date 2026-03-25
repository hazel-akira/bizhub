<?php

namespace App\Services;

use App\Models\StkRequest;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

final class MpesaCallbackHandler
{
    public function handle(array $payload): void
    {
        $stk = data_get($payload, 'Body.stkCallback');
        if (! is_array($stk)) {
            Log::warning('M-Pesa callback: missing Body.stkCallback');
            return;
        }

        $checkoutId = $stk['CheckoutRequestID'] ?? null;
        if (! is_string($checkoutId) || $checkoutId === '') {
            return;
        }

        $resultCode = $stk['ResultCode'] ?? null;
        $items = $this->flattenItems($stk['CallbackMetadata']['Item'] ?? []);
        $receipt = isset($items['MpesaReceiptNumber']) ? (string) $items['MpesaReceiptNumber'] : null;

        /** @var StkRequest|null $req */
        $req = StkRequest::query()->where('checkout_request_id', $checkoutId)->first();
        if ($req === null) {
            Log::warning('M-Pesa callback: unknown CheckoutRequestID', ['checkout' => $checkoutId]);
            return;
        }

        if ($req->status === 'completed') {
            return;
        }

        $success = (int) $resultCode === 0;

        DB::transaction(function () use ($req, $success, $receipt, $stk, $items): void {
            $meta = $req->meta ?? [];
            $meta['callback'] = [
                'ResultCode' => $stk['ResultCode'] ?? null,
                'ResultDesc' => $stk['ResultDesc'] ?? null,
                'items' => $items,
                'received_at' => now()->toIso8601String(),
            ];

            $req->update([
                'status' => $success ? 'completed' : 'failed',
                'mpesa_receipt_number' => $success ? $receipt : null,
                'meta' => $meta,
            ]);
        });
    }

    /**
     * @param  array<int, array<string, mixed>>  $itemList
     * @return array<string, mixed>
     */
    private function flattenItems(array $itemList): array
    {
        $out = [];
        foreach ($itemList as $row) {
            if (! is_array($row)) {
                continue;
            }
            $name = $row['Name'] ?? null;
            if (! is_string($name) || $name === '') {
                continue;
            }
            $out[$name] = $row['Value'] ?? null;
        }
        return $out;
    }
}
