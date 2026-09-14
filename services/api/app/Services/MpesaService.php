<?php

namespace App\Services;

use App\Enums\MpesaAccountType;
use App\Enums\MpesaTransactionStatus;
use App\Events\MpesaPaymentReceived;
use App\Models\Business;
use App\Models\MpesaConfig;
use App\Models\MpesaTransaction;
use App\Models\Order;
use App\Models\User;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class MpesaService
{
    public function initiateStkPush(
        Business $business,
        float $amount,
        string $phone,
        ?string $reference = null,
        ?array $items = null,
        ?User $user = null,
    ): MpesaTransaction {
        $config = $this->requireConfig($business);

        $transaction = MpesaTransaction::create([
            'business_id' => $business->id,
            'user_id' => $user?->id,
            'reference' => $reference ?: 'BIZ-'.$business->id.'-'.now()->format('YmdHis'),
            'phone' => $this->normalizePhone($phone),
            'amount' => (int) round($amount),
            'checkout_request_id' => 'pending_'.Str::uuid(),
            'status' => MpesaTransactionStatus::Pending,
            'metadata' => $items ? ['items' => $items] : null,
        ]);

        $this->sendDarajaStkPush($transaction, $config);

        return $transaction->fresh();
    }

    public function initiateStkForOrder(Order $order): MpesaTransaction
    {
        $business = $order->items()->with('product.business')->first()?->product?->business
            ?? $order->user?->business;

        if (! $business) {
            throw ValidationException::withMessages([
                'order_id' => ['This order is not linked to a business with M-Pesa.'],
            ]);
        }

        $transaction = $this->initiateStkPush(
            $business,
            (float) $order->total_amount,
            $order->phone_number,
            'ORDER-'.$order->id,
            null,
            $order->user,
        );

        $transaction->update(['order_id' => $order->id]);

        $order->update([
            'checkout_request_id' => $transaction->checkout_request_id,
            'payment_status' => 'pending',
        ]);

        return $transaction->fresh();
    }

    /**
     * Lipa na M-Pesa Dynamic QR — customer scans in the M-Pesa app.
     *
     * @return array{transaction: MpesaTransaction, qr_code: string, shortcode: string, account_type: string, merchant_name: string}
     */
    public function createQrPayment(
        Business $business,
        float $amount,
        ?string $reference = null,
        ?User $user = null,
    ): array {
        $config = $this->requireConfig($business);
        $this->registerC2bUrls($config);

        $billRef = $this->qrBillReference($reference);
        $transaction = MpesaTransaction::create([
            'business_id' => $business->id,
            'user_id' => $user?->id,
            'reference' => $billRef,
            'phone' => 'qr',
            'amount' => (int) round($amount),
            'checkout_request_id' => 'qr_'.Str::uuid(),
            'status' => MpesaTransactionStatus::Pending,
            'metadata' => ['channel' => 'qr'],
            'result_description' => 'Waiting for the customer to scan the QR in M-Pesa.',
        ]);

        $qrCode = $this->sendDarajaDynamicQr($transaction, $config, $business);

        $transaction->update([
            'metadata' => [
                'channel' => 'qr',
                'qr_code' => $qrCode,
            ],
        ]);

        return [
            'transaction' => $transaction->fresh(),
            'qr_code' => $qrCode,
            'shortcode' => (string) $config->shortcode,
            'account_type' => $config->account_type?->value ?? MpesaAccountType::Paybill->value,
            'merchant_name' => $this->merchantName($business),
        ];
    }

    public function confirmQrByReceipt(
        string $checkoutRequestId,
        string $receipt,
        int $businessId,
    ): MpesaTransaction {
        $transaction = MpesaTransaction::query()
            ->forBusiness($businessId)
            ->where('checkout_request_id', $checkoutRequestId)
            ->first();

        if (! $transaction) {
            throw ValidationException::withMessages([
                'mpesa' => ['Unknown QR payment.'],
            ]);
        }

        if ($transaction->status === MpesaTransactionStatus::Completed) {
            return $transaction;
        }

        $transaction->update([
            'status' => MpesaTransactionStatus::Completed,
            'mpesa_receipt_number' => strtoupper(trim($receipt)),
            'result_description' => 'Confirmed from M-Pesa message.',
        ]);

        MpesaPaymentReceived::dispatch($transaction->fresh());

        return $transaction->fresh();
    }

    public function handleC2bValidation(): array
    {
        return ['ResultCode' => 0, 'ResultDesc' => 'Accepted'];
    }

    public function handleC2bConfirmation(array $payload): void
    {
        Log::info('M-Pesa C2B confirmation received', [
            'trans_id' => $payload['TransID'] ?? null,
            'shortcode' => $payload['BusinessShortCode'] ?? null,
        ]);

        $receipt = is_string($payload['TransID'] ?? null) ? $payload['TransID'] : null;
        $amount = (int) round((float) ($payload['TransAmount'] ?? 0));
        $shortcode = trim((string) ($payload['BusinessShortCode'] ?? ''));
        $billRef = trim((string) ($payload['BillRefNumber'] ?? $payload['InvoiceNumber'] ?? ''));
        $phone = isset($payload['MSISDN']) ? $this->normalizePhone((string) $payload['MSISDN']) : null;

        if ($receipt && MpesaTransaction::query()->where('mpesa_receipt_number', $receipt)->exists()) {
            return;
        }

        $transaction = null;
        if ($billRef !== '') {
            $transaction = MpesaTransaction::query()
                ->where('status', MpesaTransactionStatus::Pending)
                ->where('reference', $billRef)
                ->latest('id')
                ->first();
        }

        if (! $transaction && $shortcode !== '' && $amount > 0) {
            $transaction = MpesaTransaction::query()
                ->where('status', MpesaTransactionStatus::Pending)
                ->where('amount', $amount)
                ->where('checkout_request_id', 'like', 'qr_%')
                ->whereHas('business.mpesaConfig', function ($query) use ($shortcode) {
                    $query->where('shortcode', $shortcode);
                })
                ->where('created_at', '>=', now()->subMinutes(20))
                ->latest('id')
                ->first();
        }

        if (! $transaction) {
            return;
        }

        $transaction->update([
            'status' => MpesaTransactionStatus::Completed,
            'mpesa_receipt_number' => $receipt,
            'phone' => filled($phone) && $phone !== 'qr' ? $phone : $transaction->phone,
            'result_description' => 'Paid via Lipa na M-Pesa QR.',
        ]);

        if ($transaction->order_id) {
            $transaction->order?->update([
                'payment_status' => 'paid',
                'mpesa_receipt' => $transaction->mpesa_receipt_number,
            ]);
        }

        MpesaPaymentReceived::dispatch($transaction->fresh());
    }

    /** @deprecated Use initiateStkPush() — kept for unpaid-screen compatibility */
    public function initiateStk(float $amount, string $phone, string $reference, ?User $user = null): array
    {
        $business = $user?->business;
        if (! $business) {
            throw ValidationException::withMessages([
                'phone' => ['Sign in to a business before collecting M-Pesa.'],
            ]);
        }

        $transaction = $this->initiateStkPush($business, $amount, $phone, $reference, null, $user);

        return [
            'checkout_request_id' => $transaction->checkout_request_id,
            'status' => $transaction->status?->value ?? MpesaTransactionStatus::Pending->value,
        ];
    }

    public function getStatus(string $checkoutRequestId, ?int $businessId = null): ?MpesaTransaction
    {
        $query = MpesaTransaction::query()->where('checkout_request_id', $checkoutRequestId);

        if ($businessId !== null) {
            $query->forBusiness($businessId);
        }

        $transaction = $query->with('business.mpesaConfig')->first();
        if (
            $transaction
            && $transaction->status === MpesaTransactionStatus::Pending
            && $transaction->created_at?->lt(now()->subSeconds(8))
            && ! str_starts_with((string) $transaction->checkout_request_id, 'qr_')
        ) {
            $this->reconcileWithDaraja($transaction);
            $transaction->refresh();
        }

        return $transaction;
    }

    public function upsertConfig(Business $business, array $data): MpesaConfig
    {
        $config = $business->mpesaConfig ?? new MpesaConfig(['business_id' => $business->id]);

        if (array_key_exists('shortcode', $data) && filled($data['shortcode'])) {
            $config->shortcode = $data['shortcode'];
        }
        if (array_key_exists('account_type', $data) && filled($data['account_type'])) {
            $config->account_type = MpesaAccountType::from($data['account_type']);
        }

        // Daraja sandbox STK only works with Paybill shortcode 174379.
        if (trim((string) $config->shortcode) === '174379') {
            $config->account_type = MpesaAccountType::Paybill;
        }
        foreach (['consumer_key', 'consumer_secret', 'passkey'] as $secret) {
            if (array_key_exists($secret, $data) && filled($data[$secret])) {
                $config->{$secret} = $data[$secret];
            }
        }

        $config->save();
        Cache::forget($this->tokenCacheKey($business->id));

        return $config->fresh();
    }

    public function handleCallback(array $payload): void
    {
        Log::info('M-Pesa callback received', ['keys' => array_keys($payload)]);

        $body = data_get($payload, 'Body.stkCallback');
        if (! is_array($body)) {
            return;
        }

        $checkoutRequestId = $body['CheckoutRequestID'] ?? null;
        $merchantRequestId = $body['MerchantRequestID'] ?? null;

        $transaction = null;
        if (filled($checkoutRequestId)) {
            $transaction = MpesaTransaction::where('checkout_request_id', $checkoutRequestId)->first();
        }
        if (! $transaction && filled($merchantRequestId)) {
            $transaction = MpesaTransaction::where('merchant_request_id', $merchantRequestId)->first();
        }
        if (! $transaction) {
            return;
        }

        $resultCode = (int) ($body['ResultCode'] ?? 1);
        $resultDesc = is_string($body['ResultDesc'] ?? null) ? $body['ResultDesc'] : 'Unknown result';

        if ($resultCode === 0) {
            $receipt = $this->callbackMetadataValue($body, 'MpesaReceiptNumber');

            $transaction->update([
                'status' => MpesaTransactionStatus::Completed,
                'mpesa_receipt_number' => $receipt !== null ? (string) $receipt : null,
                'result_description' => $resultDesc,
            ]);

            if ($transaction->order_id) {
                $transaction->order?->update([
                    'payment_status' => 'paid',
                    'mpesa_receipt' => $transaction->mpesa_receipt_number,
                ]);
            }

            MpesaPaymentReceived::dispatch($transaction->fresh());

            return;
        }

        $transaction->update([
            'status' => MpesaTransactionStatus::Failed,
            'result_description' => $resultDesc,
        ]);

        $transaction->order?->update(['payment_status' => 'failed']);
    }

    /**
     * Ask Daraja for the STK outcome when the callback never arrives (e.g. dead ngrok URL).
     */
    private function reconcileWithDaraja(MpesaTransaction $transaction): void
    {
        $config = $transaction->business?->mpesaConfig;
        if (! $config?->isReady() || ! filled($transaction->checkout_request_id)) {
            return;
        }

        $timestamp = now('Africa/Nairobi')->format('YmdHis');
        $password = base64_encode($config->shortcode.$config->passkey.$timestamp);

        $response = Http::timeout(20)
            ->withToken($this->getAccessToken($config))
            ->acceptJson()
            ->asJson()
            ->post(config('services.mpesa.base_url').'/mpesa/stkpushquery/v1/query', [
                'BusinessShortCode' => $config->shortcode,
                'Password' => $password,
                'Timestamp' => $timestamp,
                'CheckoutRequestID' => $transaction->checkout_request_id,
            ]);

        $payload = $response->json();
        if (! is_array($payload)) {
            return;
        }

        $resultCode = $payload['ResultCode'] ?? null;
        if ($resultCode === null || $resultCode === '') {
            return;
        }

        $resultCode = (int) $resultCode;
        $resultDesc = is_string($payload['ResultDesc'] ?? null)
            ? $payload['ResultDesc']
            : 'STK query result';

        // 4999 = still waiting for PIN / processing.
        if ($resultCode === 4999) {
            return;
        }

        if ($resultCode === 0) {
            $transaction->update([
                'status' => MpesaTransactionStatus::Completed,
                'result_description' => $resultDesc,
            ]);

            if ($transaction->order_id) {
                $transaction->order?->update([
                    'payment_status' => 'paid',
                    'mpesa_receipt' => $transaction->mpesa_receipt_number,
                ]);
            }

            MpesaPaymentReceived::dispatch($transaction->fresh());

            return;
        }

        $transaction->update([
            'status' => MpesaTransactionStatus::Failed,
            'result_description' => $resultDesc,
        ]);
        $transaction->order?->update(['payment_status' => 'failed']);
    }

    private function requireConfig(Business $business): MpesaConfig
    {
        $business->load('mpesaConfig');
        $config = $business->mpesaConfig;
        if (! $config?->isReady()) {
            throw ValidationException::withMessages([
                'mpesa' => ['M-Pesa is not configured for this business. Add Till or Paybill credentials in Settings.'],
            ]);
        }

        return $config;
    }

    private function sendDarajaDynamicQr(
        MpesaTransaction $transaction,
        MpesaConfig $config,
        Business $business,
    ): string {
        $accountType = $config->account_type ?? MpesaAccountType::Paybill;
        if (trim((string) $config->shortcode) === '174379') {
            $accountType = MpesaAccountType::Paybill;
        }

        $response = Http::timeout(30)
            ->withToken($this->getAccessToken($config))
            ->acceptJson()
            ->asJson()
            ->post(config('services.mpesa.base_url').'/mpesa/qrcode/v1/generate', [
                'MerchantName' => $this->merchantName($business),
                'RefNo' => $transaction->reference,
                'Amount' => (string) $transaction->amount,
                'TrxCode' => $accountType->qrTrxCode(),
                'CPI' => trim((string) $config->shortcode),
                'Size' => '300',
            ]);

        $payload = $response->json();
        if (! is_array($payload)) {
            $payload = [];
        }

        $code = (string) ($payload['ResponseCode'] ?? '');
        $qrCode = $payload['QRCode'] ?? null;

        if ($response->failed() || ! in_array($code, ['0', '00'], true) || ! is_string($qrCode) || $qrCode === '') {
            $message = $this->darajaErrorMessage($payload, $response->status(), $config);

            $transaction->update([
                'status' => MpesaTransactionStatus::Failed,
                'result_description' => $message,
            ]);

            throw ValidationException::withMessages([
                'mpesa' => [
                    $message !== '' && ! str_contains(strtolower($message), 'stk')
                        ? $message
                        : 'Could not create the Lipa na M-Pesa QR. Check Till/Paybill credentials in Settings.',
                ],
            ]);
        }

        return $qrCode;
    }

    private function registerC2bUrls(MpesaConfig $config): void
    {
        try {
            $confirm = $this->resolveC2bUrl('c2b-confirm');
            $validate = $this->resolveC2bUrl('c2b-validate');

            Http::timeout(20)
                ->withToken($this->getAccessToken($config))
                ->acceptJson()
                ->asJson()
                ->post(config('services.mpesa.base_url').'/mpesa/c2b/v1/registerurl', [
                    'ShortCode' => trim((string) $config->shortcode),
                    'ResponseType' => 'Completed',
                    'ConfirmationURL' => $confirm,
                    'ValidationURL' => $validate,
                ]);
        } catch (\Throwable $e) {
            Log::warning('M-Pesa C2B URL registration skipped', [
                'business_id' => $config->business_id,
                'error' => $e->getMessage(),
            ]);
        }
    }

    private function resolveC2bUrl(string $suffix): string
    {
        $stk = $this->resolveCallbackUrl();
        $replaced = preg_replace('#/stk-callback$#', '/'.$suffix, $stk);
        if (is_string($replaced) && $replaced !== $stk) {
            return $replaced;
        }

        return rtrim((string) config('app.url'), '/').'/api/payments/'.$suffix;
    }

    private function qrBillReference(?string $reference): string
    {
        $clean = strtoupper(preg_replace('/[^A-Z0-9]/', '', (string) $reference) ?? '');
        if ($clean === '') {
            $clean = 'QR'.Str::upper(Str::random(8));
        }

        return Str::limit($clean, 12, '');
    }

    private function merchantName(Business $business): string
    {
        $name = trim((string) $business->name);

        return Str::limit($name !== '' ? $name : 'Akira Flow', 20, '');
    }

    private function sendDarajaStkPush(MpesaTransaction $transaction, MpesaConfig $config): void
    {
        $token = $this->getAccessToken($config);
        $timestamp = now('Africa/Nairobi')->format('YmdHis');
        $password = base64_encode($config->shortcode.$config->passkey.$timestamp);
        $phone = $this->normalizePhone($transaction->phone);
        $stk = $this->resolveStkPushParameters($config);

        $response = Http::timeout(30)
            ->withToken($token)
            ->acceptJson()
            ->asJson()
            ->post(config('services.mpesa.base_url').'/mpesa/stkpush/v1/processrequest', [
                'BusinessShortCode' => $config->shortcode,
                'Password' => $password,
                'Timestamp' => $timestamp,
                'TransactionType' => $stk['transaction_type'],
                'Amount' => $transaction->amount,
                'PartyA' => $phone,
                'PartyB' => $stk['party_b'],
                'PhoneNumber' => $phone,
                'CallBackURL' => $this->resolveCallbackUrl(),
                'AccountReference' => Str::limit($transaction->reference ?? 'AkiraFlow', 12, ''),
                'TransactionDesc' => 'Sale payment',
            ]);

        $payload = $response->json();
        if (! is_array($payload)) {
            $payload = [];
        }

        if ($response->failed()) {
            $message = $this->darajaErrorMessage($payload, $response->status(), $config);

            $transaction->update([
                'status' => MpesaTransactionStatus::Failed,
                'result_description' => $message,
            ]);

            throw ValidationException::withMessages([
                'mpesa' => [$message],
            ]);
        }
        $responseCode = (string) ($payload['ResponseCode'] ?? '1');

        if ($responseCode !== '0') {
            $message = $payload['CustomerMessage'] ?? $payload['ResponseDescription'] ?? 'STK Push was rejected.';

            $transaction->update([
                'status' => MpesaTransactionStatus::Failed,
                'result_description' => is_string($message) ? $message : 'STK Push was rejected.',
                'merchant_request_id' => $payload['MerchantRequestID'] ?? null,
                'checkout_request_id' => $payload['CheckoutRequestID'] ?? $transaction->checkout_request_id,
            ]);

            throw ValidationException::withMessages([
                'mpesa' => [is_string($message) ? $message : 'STK Push was rejected.'],
            ]);
        }

        $transaction->update([
            'checkout_request_id' => $payload['CheckoutRequestID'] ?? $transaction->checkout_request_id,
            'merchant_request_id' => $payload['MerchantRequestID'] ?? null,
            'status' => MpesaTransactionStatus::Pending,
            'result_description' => $payload['CustomerMessage'] ?? 'STK Push sent. Waiting for PIN.',
        ]);
    }

    private function getAccessToken(MpesaConfig $config): string
    {
        return Cache::remember(
            $this->tokenCacheKey($config->business_id),
            now()->addMinutes(50),
            function () use ($config) {
                $response = Http::timeout(20)
                    ->withBasicAuth($config->consumer_key, $config->consumer_secret)
                    ->acceptJson()
                    ->get(config('services.mpesa.base_url').'/oauth/v1/generate', [
                        'grant_type' => 'client_credentials',
                    ]);

                $token = $response->json('access_token');
                if ($response->failed() || ! filled($token)) {
                    throw ValidationException::withMessages([
                        'mpesa' => [
                            $this->darajaErrorMessage($response->json() ?? [], $response->status())
                                ?: 'Could not authenticate with Safaricom. Check the consumer key and secret.',
                        ],
                    ]);
                }

                return $token;
            },
        );
    }

    /**
     * @return array{transaction_type: string, party_b: string}
     */
    private function resolveStkPushParameters(MpesaConfig $config): array
    {
        $shortcode = trim((string) $config->shortcode);
        $accountType = $config->account_type ?? MpesaAccountType::Paybill;

        if ($shortcode === '174379') {
            return [
                'transaction_type' => MpesaAccountType::Paybill->transactionType(),
                'party_b' => $shortcode,
            ];
        }

        return [
            'transaction_type' => $accountType->transactionType(),
            'party_b' => $shortcode,
        ];
    }

    private function darajaErrorMessage(mixed $payload, int $status, ?MpesaConfig $config = null): string
    {
        $message = null;

        if (is_array($payload)) {
            foreach (['errorMessage', 'ResponseDescription', 'CustomerMessage', 'error_description'] as $key) {
                if (isset($payload[$key]) && is_string($payload[$key]) && $payload[$key] !== '') {
                    $message = $payload[$key];
                    break;
                }
            }
        }

        if ($message !== null && stripos($message, 'invalid callback') !== false) {
            return 'Invalid M-Pesa callback URL. Safaricom rejects URLs containing "mpesa" in the path. '
                .'Set MPESA_CALLBACK_URL to https://YOUR-DOMAIN/api/payments/stk-callback on the server.';
        }

        if ($message !== null && stripos($message, 'invalid transaction type') !== false) {
            $typeLabel = $config?->account_type?->label() ?? 'unknown';
            $shortcode = $config?->shortcode ?? '?';

            return 'Invalid M-Pesa transaction type for '.$typeLabel.' shortcode '.$shortcode.'. '
                .'Sandbox: Paybill + 174379 + Lipa Na M-Pesa Online passkey. '
                .'Till: account type Till + your till number (Buy Goods). '
                .'Paybill: account type Paybill + your paybill number.';
        }

        if ($message !== null) {
            return $message;
        }

        return 'Safaricom rejected the STK Push (HTTP '.$status.'). Use sandbox Paybill 174379 and the Lipa Na M-Pesa Online passkey.';
    }

    private function tokenCacheKey(int $businessId): string
    {
        return 'mpesa.oauth.'.$businessId;
    }

    /** @return array{url: string, valid: bool, error?: string} */
    public function publicCallbackUrl(): array
    {
        try {
            return [
                'url' => $this->resolveCallbackUrl(),
                'valid' => true,
            ];
        } catch (ValidationException $e) {
            return [
                'url' => (string) config('services.mpesa.callback_url'),
                'valid' => false,
                'error' => collect($e->errors())->flatten()->first(),
            ];
        }
    }

    private function resolveCallbackUrl(): string
    {
        $configured = trim((string) config('services.mpesa.callback_url', ''));
        $url = $configured;

        if ($url === '') {
            $base = rtrim((string) config('app.url'), '/');
            if ($base === '') {
                throw ValidationException::withMessages([
                    'mpesa' => [
                        'M-Pesa callback URL is not configured. Set MPESA_CALLBACK_URL or APP_URL on the server.',
                    ],
                ]);
            }
            $url = $base.'/api/payments/stk-callback';
        }

        $url = rtrim($url, '/');

        if (! str_starts_with(strtolower($url), 'https://')) {
            throw ValidationException::withMessages([
                'mpesa' => [
                    'M-Pesa callback URL must use HTTPS. Current value: '.$url,
                ],
            ]);
        }

        $path = parse_url($url, PHP_URL_PATH) ?? '';
        if (preg_match('/mpesa/i', $path)) {
            throw ValidationException::withMessages([
                'mpesa' => [
                    'Callback URL must not contain "mpesa" in the path — Safaricom rejects it (error 400.002.02). '
                    .'Use https://YOUR-DOMAIN/api/payments/stk-callback instead of /api/mpesa/callback.',
                ],
            ]);
        }

        return $url;
    }

    private function callbackMetadataValue(array $body, string $name): mixed
    {
        $items = data_get($body, 'CallbackMetadata.Item', []);
        if (! is_array($items)) {
            return null;
        }

        foreach ($items as $item) {
            if (! is_array($item)) {
                continue;
            }
            if (($item['Name'] ?? '') === $name) {
                return $item['Value'] ?? null;
            }
        }

        return null;
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
