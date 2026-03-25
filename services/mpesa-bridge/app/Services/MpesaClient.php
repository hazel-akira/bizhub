<?php

namespace App\Services;

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use RuntimeException;

final class MpesaClient
{
    public function getAccessToken(): string
    {
        return Cache::remember('mpesa.oauth_token', 3500, function (): string {
            $key = config('mpesa.consumer_key');
            $secret = config('mpesa.consumer_secret');
            if ($key === '' || $secret === '') {
                throw new RuntimeException('M-Pesa consumer key/secret not configured.');
            }

            $url = rtrim((string) config('mpesa.base_url'), '/').'/oauth/v1/generate?grant_type=client_credentials';
            $response = Http::withBasicAuth($key, $secret)->timeout(30)->get($url);

            if (! $response->successful()) {
                Log::error('M-Pesa OAuth failed', ['body' => $response->body()]);
                throw new RuntimeException('M-Pesa OAuth failed.');
            }

            $data = $response->json();
            $token = $data['access_token'] ?? null;
            if (! is_string($token) || $token === '') {
                throw new RuntimeException('M-Pesa OAuth: missing access_token.');
            }

            return $token;
        });
    }

    /**
     * @return array<string, mixed>
     */
    public function stkPush(string $phone254, int $amountKes, string $accountRef, string $desc): array
    {
        $shortcode = (string) config('mpesa.shortcode');
        $passkey = (string) config('mpesa.passkey');
        $callbackUrl = (string) config('mpesa.callback_url');

        if ($shortcode === '' || $passkey === '') {
            throw new RuntimeException('M-Pesa shortcode/passkey not configured.');
        }
        if ($callbackUrl === '') {
            throw new RuntimeException('MPESA_CALLBACK_URL not configured.');
        }

        $timestamp = now()->format('YmdHis');
        $password = base64_encode($shortcode.$passkey.$timestamp);

        $payload = [
            'BusinessShortCode' => $shortcode,
            'Password' => $password,
            'Timestamp' => $timestamp,
            'TransactionType' => (string) config('mpesa.transaction_type'),
            'Amount' => (string) $amountKes,
            'PartyA' => $phone254,
            'PartyB' => $shortcode,
            'PhoneNumber' => $phone254,
            'CallBackURL' => $callbackUrl,
            'AccountReference' => mb_substr($accountRef, 0, 12),
            'TransactionDesc' => mb_substr($desc, 0, 13),
        ];

        $token = $this->getAccessToken();
        $url = rtrim((string) config('mpesa.base_url'), '/').'/mpesa/stkpush/v1/processrequest';

        $response = Http::withToken($token)->timeout(45)->acceptJson()->asJson()->post($url, $payload);
        $data = $response->json() ?? [];

        if (! $response->successful()) {
            Log::error('M-Pesa STK failed', ['body' => $response->body()]);
            throw new RuntimeException('M-Pesa STK request failed.');
        }

        return is_array($data) ? $data : [];
    }
}
