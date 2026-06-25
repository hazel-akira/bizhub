<?php

namespace App\Services;

use App\Models\MpesaTransaction;
use App\Models\Order;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;

class MpesaService
{
    public function initiateStkForOrder(Order $order): MpesaTransaction
    {
        $checkoutRequestId = 'ws_CO_'.Str::uuid();

        $transaction = MpesaTransaction::create([
            'order_id' => $order->id,
            'reference' => 'ORDER-'.$order->id,
            'phone' => $order->phone_number,
            'amount' => $order->total_amount,
            'checkout_request_id' => $checkoutRequestId,
            'status' => 'processing',
        ]);

        $order->update([
            'checkout_request_id' => $checkoutRequestId,
            'payment_status' => 'pending',
        ]);

        if ($this->isConfigured()) {
            $this->sendDarajaStkPush($transaction);
        } elseif (app()->environment('local')) {
            // Local dev: auto-complete after a short delay via callback simulation.
            $transaction->update([
                'status' => 'processing',
                'result_description' => 'Awaiting M-Pesa confirmation (configure Daraja for live STK).',
            ]);
        }

        return $transaction->fresh();
    }

    public function initiateStk(float $amount, string $phone, string $reference): array
    {
        $checkoutRequestId = 'ws_CO_'.Str::uuid();

        $transaction = MpesaTransaction::create([
            'reference' => $reference,
            'phone' => $phone,
            'amount' => (int) round($amount),
            'checkout_request_id' => $checkoutRequestId,
            'status' => 'processing',
        ]);

        if ($this->isConfigured()) {
            $this->sendDarajaStkPush($transaction);
        }

        return [
            'checkout_request_id' => $checkoutRequestId,
            'status' => 'processing',
        ];
    }

    public function getStatus(string $checkoutRequestId): ?MpesaTransaction
    {
        return MpesaTransaction::where('checkout_request_id', $checkoutRequestId)->first();
    }

    public function handleCallback(array $payload): void
    {
        $body = $payload['Body']['stkCallback'] ?? null;
        if (! is_array($body)) {
            return;
        }

        $checkoutRequestId = $body['CheckoutRequestID'] ?? null;
        if (! $checkoutRequestId) {
            return;
        }

        $transaction = MpesaTransaction::where('checkout_request_id', $checkoutRequestId)->first();
        if (! $transaction) {
            return;
        }

        $resultCode = (int) ($body['ResultCode'] ?? 1);
        $resultDesc = $body['ResultDesc'] ?? 'Unknown result';

        if ($resultCode === 0) {
            $receipt = null;
            foreach ($body['CallbackMetadata']['Item'] ?? [] as $item) {
                if (($item['Name'] ?? '') === 'MpesaReceiptNumber') {
                    $receipt = $item['Value'] ?? null;
                }
            }

            $transaction->update([
                'status' => 'paid',
                'mpesa_receipt_number' => $receipt,
                'result_description' => $resultDesc,
            ]);

            if ($transaction->order_id) {
                $transaction->order?->update([
                    'payment_status' => 'paid',
                    'mpesa_receipt' => $receipt,
                ]);
            }

            return;
        }

        $transaction->update([
            'status' => 'failed',
            'result_description' => $resultDesc,
        ]);

        $transaction->order?->update(['payment_status' => 'failed']);
    }

    private function isConfigured(): bool
    {
        return filled(config('services.mpesa.consumer_key'))
            && filled(config('services.mpesa.consumer_secret'))
            && filled(config('services.mpesa.shortcode'))
            && filled(config('services.mpesa.passkey'));
    }

    private function sendDarajaStkPush(MpesaTransaction $transaction): void
    {
        $token = $this->getAccessToken();
        $timestamp = now()->format('YmdHis');
        $password = base64_encode(
            config('services.mpesa.shortcode').config('services.mpesa.passkey').$timestamp
        );

        $phone = $this->normalizePhone($transaction->phone);

        Http::withToken($token)
            ->post(config('services.mpesa.base_url').'/mpesa/stkpush/v1/processrequest', [
                'BusinessShortCode' => config('services.mpesa.shortcode'),
                'Password' => $password,
                'Timestamp' => $timestamp,
                'TransactionType' => 'CustomerPayBillOnline',
                'Amount' => $transaction->amount,
                'PartyA' => $phone,
                'PartyB' => config('services.mpesa.shortcode'),
                'PhoneNumber' => $phone,
                'CallBackURL' => config('services.mpesa.callback_url'),
                'AccountReference' => $transaction->reference ?? 'AkiraBites',
                'TransactionDesc' => 'Akira Bites order payment',
            ]);
    }

    private function getAccessToken(): string
    {
        $response = Http::withBasicAuth(
            config('services.mpesa.consumer_key'),
            config('services.mpesa.consumer_secret'),
        )->get(config('services.mpesa.base_url').'/oauth/v1/generate', [
            'grant_type' => 'client_credentials',
        ]);

        return $response->json('access_token');
    }

    private function normalizePhone(string $phone): string
    {
        $digits = preg_replace('/\D+/', '', $phone) ?? '';

        if (str_starts_with($digits, '0')) {
            return '254'.substr($digits, 1);
        }

        if (str_starts_with($digits, '254')) {
            return $digits;
        }

        return $digits;
    }
}
