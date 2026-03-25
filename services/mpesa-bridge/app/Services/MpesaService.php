<?php

namespace App\Services;

use App\Models\Order;
use App\Models\StkRequest;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * M-Pesa Daraja API integration for STK Push.
 * Mirrors the flow used by the Flutter app (lib/services/mpesa_api_service.dart).
 */
class MpesaService
{
    public function __construct(
        protected string $baseUrl,
        protected string $consumerKey,
        protected string $consumerSecret,
        protected string $shortcode,
        protected string $passkey,
        protected string $callbackUrl,
    ) {}

    public static function fromConfig(): self
    {
        return new self(
            config('mpesa.base_url'),
            config('mpesa.consumer_key'),
            config('mpesa.consumer_secret'),
            config('mpesa.shortcode'),
            config('mpesa.passkey'),
            config('mpesa.callback_url'),
        );
    }

    protected function getAccessToken(): ?string
    {
        $url = rtrim($this->baseUrl, '/') . '/oauth/v1/generate?grant_type=client_credentials';
        $response = Http::withBasicAuth($this->consumerKey, $this->consumerSecret)
            ->get($url);

        if (! $response->successful()) {
            Log::error('M-Pesa OAuth failed', ['body' => $response->body()]);

            return null;
        }

        $data = $response->json();

        return $data['access_token'] ?? null;
    }

    /**
     * Initiate STK Push. Returns checkout_request_id or null on failure.
     *
     * @param int|null $orderId Optional order ID to link StkRequest for callback.
     */
    public function initiateStkPush(float $amount, string $phone, string $reference, ?int $orderId = null): ?string
    {
        $token = $this->getAccessToken();
        if (! $token) {
            return null;
        }

        // Normalize phone: 07XXXXXXXX -> 2547XXXXXXXX
        $phone = preg_replace('/^0/', '254', $phone);

        $timestamp = date('YmdHis');
        $password = base64_encode($this->shortcode . $this->passkey . $timestamp);

        $url = rtrim($this->baseUrl, '/') . '/mpesa/stkpush/v1/processrequest';

        $payload = [
            'BusinessShortCode' => (int) $this->shortcode,
            'Password' => $password,
            'Timestamp' => $timestamp,
            'TransactionType' => config('mpesa.transaction_type', 'CustomerPayBillOnline'),
            'Amount' => (int) round($amount),
            'PartyA' => (int) $phone,
            'PartyB' => (int) $this->shortcode,
            'PhoneNumber' => (int) $phone,
            'CallBackURL' => $this->callbackUrl,
            'AccountReference' => substr($reference, 0, 12),
            'TransactionDesc' => 'AkiraBites Order',
        ];

        $response = Http::withToken($token)
            ->post($url, $payload);

        if (! $response->successful()) {
            Log::error('M-Pesa STK Push failed', [
                'status' => $response->status(),
                'body' => $response->body(),
            ]);

            return null;
        }

        $data = $response->json();
        $checkoutRequestId = $data['CheckoutRequestID'] ?? null;

        if ($checkoutRequestId) {
            StkRequest::create([
                'checkout_request_id' => $checkoutRequestId,
                'reference' => $reference,
                'status' => 'pending',
                'order_id' => $orderId,
            ]);
        }

        return $checkoutRequestId;
    }
}
