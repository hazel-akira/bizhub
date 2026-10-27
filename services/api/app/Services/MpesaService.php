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
        $phone = $this->requireMsisdn($phone);

        $transaction = MpesaTransaction::create([
            'business_id' => $business->id,
            'user_id' => $user?->id,
            'reference' => $reference ?: 'BIZ-'.$business->id.'-'.now()->format('YmdHis'),
            'phone' => $phone,
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
     * @return array{transaction: MpesaTransaction, qr_code: string, qr_payload: string, sandbox: bool, shortcode: string, account_type: string, merchant_name: string}
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
        $sandbox = $this->isSandboxConfig($config);
        $transaction = MpesaTransaction::create([
            'business_id' => $business->id,
            'user_id' => $user?->id,
            'reference' => $billRef,
            'phone' => 'qr',
            'amount' => (int) round($amount),
            'checkout_request_id' => 'qr_'.Str::uuid(),
            'status' => MpesaTransactionStatus::Pending,
            'metadata' => ['channel' => 'qr', 'sandbox' => $sandbox],
            'result_description' => $sandbox
                ? 'Sandbox QR — a real M-Pesa phone cannot pay 174379. Confirm with a test receipt, or use STK.'
                : 'Waiting for the customer to scan the QR in M-Pesa.',
        ]);

        $qrCode = '';
        $qrPayload = $this->sandboxQrPayload($transaction, $config, $business);
        try {
            $qrCode = $this->sendDarajaDynamicQr($transaction, $config, $business);
        } catch (ValidationException $e) {
            if (! $sandbox) {
                $transaction->update([
                    'status' => MpesaTransactionStatus::Failed,
                    'result_description' => collect($e->errors())->flatten()->first() ?: 'QR generate failed',
                ]);
                throw $e;
            }

            Log::warning('Sandbox Dynamic QR unavailable, using local QR', [
                'business_id' => $business->id,
                'error' => collect($e->errors())->flatten()->first(),
            ]);
        }

        $transaction->update([
            'metadata' => [
                'channel' => 'qr',
                'sandbox' => $sandbox,
                'qr_code' => $qrCode,
                'qr_payload' => $qrPayload,
            ],
        ]);

        return [
            'transaction' => $transaction->fresh(),
            'qr_code' => $qrCode,
            'qr_payload' => $qrPayload,
            'sandbox' => $sandbox,
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
        $ageSeconds = $transaction?->created_at === null
            ? 0
            : now()->getTimestamp() - $transaction->created_at->getTimestamp();
        // The handset often receives the PIN prompt 15–40s after Safaricom accepts
        // the request. Querying sooner returns a false timeout or cancel, and the
        // cashier screen closes before the customer can enter a PIN.
        if (
            $transaction
            && $transaction->status === MpesaTransactionStatus::Pending
            && $ageSeconds >= 45
            && ! str_starts_with((string) $transaction->checkout_request_id, 'qr_')
            && Cache::add('mpesa.stk.query.'.$transaction->id, true, now()->addSeconds(20))
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
            $config->shortcode = trim((string) $data['shortcode']);
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
                $config->{$secret} = trim((string) $data[$secret]);
            }
        }

        $config->save();
        $this->forgetAccessToken($config);

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

        $shortcode = $this->normalizedShortcode($config);
        $timestamp = now('Africa/Nairobi')->format('YmdHis');
        $password = base64_encode($shortcode.$this->normalizedPasskey($config).$timestamp);

        $response = Http::timeout(20)
            ->withToken($this->getAccessToken($config))
            ->acceptJson()
            ->asJson()
            ->post($this->darajaBaseUrl($config).'/mpesa/stkpushquery/v1/query', [
                'BusinessShortCode' => $shortcode,
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
        $ageSeconds = $transaction->created_at === null
            ? 0
            : now()->getTimestamp() - $transaction->created_at->getTimestamp();

        if ($this->stkQueryStillInFlight($resultCode, $resultDesc, $ageSeconds)) {
            Log::info('Daraja STK query still in flight', [
                'checkout_request_id' => $transaction->checkout_request_id,
                'result_code' => $resultCode,
                'result_desc' => $resultDesc,
                'age_seconds' => $ageSeconds,
            ]);

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

        Log::info('Daraja STK query failed', [
            'checkout_request_id' => $transaction->checkout_request_id,
            'result_code' => $resultCode,
            'result_desc' => $resultDesc,
            'age_seconds' => $ageSeconds,
        ]);

        $transaction->update([
            'status' => MpesaTransactionStatus::Failed,
            'result_description' => $resultDesc,
        ]);
        $transaction->order?->update(['payment_status' => 'failed']);
    }

    /**
     * Query codes that mean "the prompt is not finished yet". Daraja often
     * returns 1032/1037 within the first minute even though the PIN screen
     * has not reached the phone.
     */
    private function stkQueryStillInFlight(int $resultCode, string $resultDesc, int $ageSeconds): bool
    {
        if ($resultCode === 4999) {
            return true;
        }

        $desc = strtolower($resultDesc);
        if (str_contains($desc, 'being processed') || str_contains($desc, 'still under processing')) {
            return true;
        }

        return in_array($resultCode, [1001, 1019, 1025, 1032, 1037], true) && $ageSeconds < 80;
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
            ->post($this->darajaBaseUrl($config).'/mpesa/qrcode/v1/generate', [
                'MerchantName' => $this->merchantName($business),
                'RefNo' => $transaction->reference,
                'Amount' => (int) $transaction->amount,
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
            Log::warning('Daraja Dynamic QR failed', [
                'status' => $response->status(),
                'body' => $payload,
                'shortcode' => $config->shortcode,
            ]);

            throw ValidationException::withMessages([
                'mpesa' => [$this->qrFailureMessage($payload, $response->status(), $config)],
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
                ->post($this->darajaBaseUrl($config).'/mpesa/c2b/v1/registerurl', [
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

    private function isSandboxConfig(MpesaConfig $config): bool
    {
        return trim((string) $config->shortcode) === '174379';
    }

    private function sandboxQrPayload(
        MpesaTransaction $transaction,
        MpesaConfig $config,
        Business $business,
    ): string {
        $type = $config->account_type?->label() ?? 'Paybill';
        if (trim((string) $config->shortcode) === '174379') {
            $type = 'Paybill';
        }

        return implode("\n", array_filter([
            $this->merchantName($business),
            'Lipa na M-Pesa '.$type.' '.$config->shortcode,
            'KES '.$transaction->amount,
            'Ref '.$transaction->reference,
        ]));
    }

    private function qrFailureMessage(mixed $payload, int $status, MpesaConfig $config): string
    {
        $message = $this->darajaErrorMessage($payload, $status, $config);
        $lower = strtolower($message);

        if ($message === '' || str_contains($lower, 'stk')) {
            return 'Safaricom did not return a Lipa na M-Pesa QR (HTTP '.$status.'). '
                .'Enable the QR Code product on this Daraja app. Sandbox 174379 cannot be paid by a real phone — use STK, or switch to a live Till/Paybill.';
        }

        return $message;
    }

    private function sendDarajaStkPush(MpesaTransaction $transaction, MpesaConfig $config): void
    {
        try {
            $token = $this->getAccessToken($config);
        } catch (ValidationException $e) {
            $message = collect($e->errors())->flatten()->first() ?: 'Could not authenticate with Safaricom.';
            $transaction->update([
                'status' => MpesaTransactionStatus::Failed,
                'result_description' => $message,
            ]);
            throw $e;
        }

        $shortcode = $this->normalizedShortcode($config);
        $timestamp = now('Africa/Nairobi')->format('YmdHis');
        $password = base64_encode($shortcode.$this->normalizedPasskey($config).$timestamp);
        $phone = $this->requireMsisdn((string) $transaction->phone);
        $stk = $this->resolveStkPushParameters($config);
        $baseUrl = $this->darajaBaseUrl($config);

        $response = Http::timeout(30)
            ->withToken($token)
            ->acceptJson()
            ->asJson()
            ->post($baseUrl.'/mpesa/stkpush/v1/processrequest', [
                'BusinessShortCode' => $shortcode,
                'Password' => $password,
                'Timestamp' => $timestamp,
                'TransactionType' => $stk['transaction_type'],
                'Amount' => (int) $transaction->amount,
                'PartyA' => $phone,
                'PartyB' => $stk['party_b'],
                'PhoneNumber' => $phone,
                'CallBackURL' => $this->resolveCallbackUrl(),
                'AccountReference' => $this->stkAccountReference($transaction->reference),
                'TransactionDesc' => 'Sale payment',
            ]);

        $payload = $this->decodeDarajaPayload($response);

        if ($response->failed()) {
            $message = $this->darajaErrorMessage($payload, $response->status(), $config, $response->body());

            Log::warning('Daraja STK push rejected', [
                'status' => $response->status(),
                'host' => parse_url($baseUrl, PHP_URL_HOST),
                'shortcode' => $shortcode,
                'account_type' => $config->account_type?->value,
                'transaction_type' => $stk['transaction_type'],
                'error' => $message,
            ]);

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
            $this->tokenCacheKey($config),
            now()->addMinutes(50),
            function () use ($config) {
                $baseUrl = $this->darajaBaseUrl($config);
                $response = Http::timeout(20)
                    ->withBasicAuth(
                        trim((string) $config->consumer_key),
                        trim((string) $config->consumer_secret),
                    )
                    ->acceptJson()
                    ->get($baseUrl.'/oauth/v1/generate', [
                        'grant_type' => 'client_credentials',
                    ]);

                $payload = $this->decodeDarajaPayload($response);
                $token = $payload['access_token'] ?? null;
                if ($response->failed() || ! is_string($token) || $token === '') {
                    $message = $this->darajaErrorMessage($payload, $response->status(), $config, $response->body(), 'oauth');

                    Log::warning('Daraja OAuth rejected', [
                        'status' => $response->status(),
                        'host' => parse_url($baseUrl, PHP_URL_HOST),
                        'shortcode' => $this->normalizedShortcode($config),
                        'error' => $message,
                    ]);

                    throw ValidationException::withMessages([
                        'mpesa' => [$message],
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
        $shortcode = $this->normalizedShortcode($config);
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

    /**
     * Sandbox Paybill 174379 stays on the sandbox host. A real till or paybill
     * is sent to production even when MPESA_BASE_URL is still the sandbox URL.
     */
    private function darajaBaseUrl(MpesaConfig $config): string
    {
        if ($this->isSandboxConfig($config)) {
            return 'https://sandbox.safaricom.co.ke';
        }

        $live = rtrim((string) config('services.mpesa.live_base_url'), '/');
        if ($live === '' || str_contains($live, 'sandbox.safaricom.co.ke')) {
            return 'https://api.safaricom.co.ke';
        }

        return $live;
    }

    private function normalizedShortcode(MpesaConfig $config): string
    {
        return trim((string) $config->shortcode);
    }

    private function normalizedPasskey(MpesaConfig $config): string
    {
        return trim((string) $config->passkey);
    }

    private function stkAccountReference(?string $reference): string
    {
        $clean = strtoupper(preg_replace('/[^A-Za-z0-9]/', '', (string) $reference) ?? '');
        if ($clean === '') {
            $clean = 'AKIRAFLOW';
        }

        return substr($clean, 0, 12);
    }

    private function requireMsisdn(string $phone): string
    {
        $normalized = $this->normalizePhone($phone);
        if (! preg_match('/^254\d{9}$/', $normalized)) {
            throw ValidationException::withMessages([
                'phone' => ['Enter a valid M-Pesa number, for example 0712345678.'],
            ]);
        }

        return $normalized;
    }

    /**
     * @param  \Illuminate\Http\Client\Response  $response
     * @return array<string, mixed>
     */
    private function decodeDarajaPayload($response): array
    {
        $payload = $response->json();
        if (is_array($payload)) {
            return $payload;
        }

        $decoded = json_decode(ltrim((string) $response->body(), "\xEF\xBB\xBF"), true);

        return is_array($decoded) ? $decoded : [];
    }

    private function darajaErrorMessage(
        mixed $payload,
        int $status,
        ?MpesaConfig $config = null,
        ?string $rawBody = null,
        string $context = 'stk',
    ): string {
        $message = null;
        $errorCode = null;

        if (is_array($payload)) {
            foreach (['errorMessage', 'ResponseDescription', 'CustomerMessage', 'error_description'] as $key) {
                if (isset($payload[$key]) && is_string($payload[$key]) && $payload[$key] !== '') {
                    $message = $payload[$key];
                    break;
                }
            }

            if (isset($payload['fault']) && is_array($payload['fault'])) {
                $fault = $payload['fault']['faultstring'] ?? null;
                if ($message === null && is_string($fault) && $fault !== '') {
                    $message = $fault;
                }
                $detailCode = $payload['fault']['detail']['errorcode'] ?? null;
                if (is_string($detailCode) && $detailCode !== '') {
                    $errorCode = $detailCode;
                }
            }

            if (isset($payload['errorCode']) && is_string($payload['errorCode']) && $payload['errorCode'] !== '') {
                $errorCode = $payload['errorCode'];
            }
        }

        if ($message === null && is_string($rawBody)) {
            $raw = trim(preg_replace('/\s+/', ' ', strip_tags($rawBody)) ?? '');
            if ($raw !== '' && strlen($raw) <= 240 && ! str_starts_with($raw, '<')) {
                $message = $raw;
            }
        }

        $live = $config !== null && ! $this->isSandboxConfig($config);
        $shortcode = $config ? $this->normalizedShortcode($config) : '?';
        $haystack = strtolower(($message ?? '').' '.($errorCode ?? ''));
        $compact = str_replace([' ', '_', '-', '.'], '', $haystack);

        if (str_contains($haystack, 'invalid callback')) {
            return 'Invalid M-Pesa callback URL. Safaricom rejects URLs containing "mpesa" in the path. '
                .'Set MPESA_CALLBACK_URL to https://YOUR-DOMAIN/api/payments/stk-callback on the server.';
        }

        if (str_contains($compact, 'invalidapikey') || str_contains($haystack, 'invalid authentication')) {
            return $live
                ? 'Safaricom rejected the production consumer key or secret for till/paybill '.$shortcode.'. Use the key and secret from the Daraja app after Go Live, not the sandbox app.'
                : 'Safaricom rejected the sandbox consumer key or secret. Sandbox STK only works with Paybill 174379 and the sandbox app keys.';
        }

        if ($message !== null && (stripos($message, 'invalid password') !== false || stripos($message, 'invalid businessshortcode') !== false)) {
            return $live
                ? 'Safaricom rejected shortcode '.$shortcode.' or its Lipa Na M-Pesa passkey. Use the passkey issued for this exact shortcode when the Daraja app went live.'
                : 'Safaricom rejected the sandbox password. Use Paybill 174379 and the Lipa Na M-Pesa Online passkey from the sandbox app.';
        }

        if ($message !== null && stripos($message, 'invalid party') !== false) {
            $typeLabel = $config?->account_type?->label() ?? 'account';

            return 'Safaricom rejected '.$typeLabel.' shortcode '.$shortcode.' as the receiving account. '
                .'Till payments must use account type Till number. Paybill payments must use account type Paybill.';
        }

        if ($message !== null && (stripos($message, 'product') !== false || stripos($message, 'not authorized') !== false)) {
            return 'This Daraja app is not allowed to use that M-Pesa product. On the production app, enable Lipa Na M-Pesa Online for the till, then try again.';
        }

        if ($message !== null && stripos($message, 'invalid transaction type') !== false) {
            $typeLabel = $config?->account_type?->label() ?? 'unknown';

            return $live
                ? 'Invalid M-Pesa transaction type for '.$typeLabel.' shortcode '.$shortcode.'. Set account type to Till number for a Buy Goods till, or Paybill for a paybill.'
                : 'Invalid M-Pesa transaction type for '.$typeLabel.' shortcode '.$shortcode.'. Sandbox STK uses Paybill 174379 and the Lipa Na M-Pesa Online passkey.';
        }

        if ($message !== null) {
            if (is_string($errorCode) && $errorCode !== '' && ! str_contains($message, $errorCode)) {
                return $message.' ('.$errorCode.')';
            }

            return $message;
        }

        $code = is_string($errorCode) && $errorCode !== '' ? ' Safaricom code: '.$errorCode.'.' : '';

        if ($context === 'oauth') {
            return $live
                ? 'Could not sign in to Safaricom production (HTTP '.$status.').'.$code.' Use the consumer key and secret from the Daraja app after Go Live.'
                : 'Could not sign in to the Safaricom sandbox (HTTP '.$status.').'.$code.' Use the sandbox app key and secret with Paybill 174379.';
        }

        if ($live) {
            return 'Safaricom rejected the live STK Push (HTTP '.$status.').'.$code
                .' Check the till number, the production consumer key and secret, and the Lipa Na M-Pesa passkey from Go Live.';
        }

        return 'Safaricom rejected the STK Push (HTTP '.$status.'). Use sandbox Paybill 174379 and the Lipa Na M-Pesa Online passkey.';
    }

    private function forgetAccessToken(MpesaConfig $config): void
    {
        Cache::forget('mpesa.oauth.'.$config->business_id);
        Cache::forget($this->tokenCacheKey($config));
        Cache::forget('mpesa.oauth.'.$config->business_id.'.sandbox.safaricom.co.ke');
        Cache::forget('mpesa.oauth.'.$config->business_id.'.api.safaricom.co.ke');
    }

    private function tokenCacheKey(MpesaConfig $config): string
    {
        $host = parse_url($this->darajaBaseUrl($config), PHP_URL_HOST) ?: 'daraja';

        return 'mpesa.oauth.'.$config->business_id.'.'.$host;
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
