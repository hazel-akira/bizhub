<?php

namespace App\Services;

use App\Models\StkRequest;
use App\Support\PhoneNormalizer;
use Illuminate\Support\Facades\DB;
use RuntimeException;

final class StkPushService
{
    public function __construct(
        private readonly MpesaClient $client,
    ) {}

    /**
     * @return array{checkout_request_id: string|null, status: string}
     */
    public function initiate(float $amount, string $phone, string $reference): array
    {
        $phone254 = PhoneNormalizer::toMpesaMsisdn($phone);
        if ($phone254 === '' || strlen($phone254) < 12) {
            throw new RuntimeException('Invalid phone number for M-Pesa.');
        }

        $amountKes = (int) round($amount);
        if ($amountKes < 1) {
            throw new RuntimeException('Amount must be at least 1 KES.');
        }

        return DB::transaction(function () use ($phone254, $amountKes, $reference, $amount): array {
            $stk = StkRequest::query()->create([
                'reference' => $reference,
                'amount' => $amount,
                'phone' => $phone254,
                'status' => 'pending',
                'meta' => ['initiated_at' => now()->toIso8601String()],
            ]);

            try {
                $raw = $this->client->stkPush(
                    $phone254,
                    $amountKes,
                    $reference,
                    'Akira Bites',
                );
            } catch (\Throwable $e) {
                $stk->update([
                    'status' => 'failed',
                    'meta' => array_merge($stk->meta ?? [], ['error' => $e->getMessage()]),
                ]);
                throw $e;
            }

            $code = $raw['ResponseCode'] ?? null;
            $accepted = $code === '0' || $code === 0;
            $checkoutId = is_string($raw['CheckoutRequestID'] ?? null) ? $raw['CheckoutRequestID'] : null;

            $stk->update([
                'checkout_request_id' => $checkoutId,
                'status' => $accepted ? 'processing' : 'failed',
                'meta' => array_merge($stk->meta ?? [], ['stk_response' => $raw]),
            ]);

            if (! $accepted) {
                $msg = $raw['CustomerMessage'] ?? $raw['ResponseDescription'] ?? 'STK not accepted';
                throw new RuntimeException(is_string($msg) ? $msg : 'STK not accepted.');
            }

            return [
                'checkout_request_id' => $checkoutId,
                'status' => 'processing',
            ];
        });
    }
}
