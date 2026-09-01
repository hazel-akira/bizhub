<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Concerns\RespondsWithJson;
use App\Http\Controllers\Controller;
use App\Http\Requests\InitiateStkPushRequest;
use App\Http\Requests\UpdateMpesaConfigRequest;
use App\Models\MpesaConfig;
use App\Models\Order;
use App\Services\MpesaService;
use Illuminate\Database\QueryException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class MpesaController extends Controller
{
    use RespondsWithJson;

    public function __construct(private readonly MpesaService $mpesa) {}

    public function config(Request $request): JsonResponse
    {
        $businessId = $request->user()->business_id;
        $config = $businessId
            ? MpesaConfig::query()->where('business_id', $businessId)->first()
            : null;

        return $this->success(
            $config?->toPublicArray() ?? [
                'configured' => false,
                'shortcode' => null,
                'account_type' => 'paybill',
                'account_type_label' => 'Paybill',
            ]
        );
    }

    public function updateConfig(UpdateMpesaConfigRequest $request): JsonResponse
    {
        if (blank(config('app.key'))) {
            return $this->error(
                'Server encryption key (APP_KEY) is missing. Set it in Render environment variables.',
                503,
            );
        }

        $user = $request->user()->loadMissing('business');
        $business = $user->business;
        if (! $business) {
            return $this->error('Complete business setup before saving M-Pesa credentials.', 422);
        }

        try {
            $config = $this->mpesa->upsertConfig(
                $business,
                $request->validated(),
            );

            return $this->success($config->toPublicArray(), 200, 'M-Pesa credentials saved');
        } catch (QueryException $e) {
            Log::error('M-Pesa config save failed (database)', [
                'business_id' => $business->id,
                'error' => $e->getMessage(),
            ]);

            return $this->error(
                'M-Pesa storage is not ready on the server. Redeploy the API so migrations can run.',
                503,
            );
        } catch (\Throwable $e) {
            Log::error('M-Pesa config save failed', [
                'business_id' => $business->id,
                'error' => $e->getMessage(),
            ]);

            $message = config('app.debug')
                ? $e->getMessage()
                : 'Could not save M-Pesa credentials. Check all fields and try again.';

            return $this->error($message, 500);
        }
    }

    /**
     * Cashier STK Push — uses the authenticated business (tenant) credentials.
     */
    public function stkPush(InitiateStkPushRequest $request): JsonResponse
    {
        $validated = $request->validated();
        $user = $request->user();
        $tenantId = $validated['business_id'] ?? $validated['tenant_id'] ?? $user->business_id;

        if ((int) $tenantId !== (int) $user->business_id) {
            return $this->error('Tenant does not match the signed-in business.', 403);
        }

        $transaction = $this->mpesa->initiateStkPush(
            $user->business,
            (float) $validated['amount'],
            $validated['phone'],
            $validated['reference'] ?? null,
            $validated['items'] ?? null,
            $user,
        );

        return $this->success([
            'id' => $transaction->id,
            'business_id' => $transaction->business_id,
            'checkout_request_id' => $transaction->checkout_request_id,
            'amount' => $transaction->amount,
            'phone' => $transaction->phone,
            'status' => $transaction->status?->value,
        ], 201);
    }

    /**
     * Online order STK Push (web shop checkout).
     */
    public function stkPushForOrder(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'order_id' => ['required', 'integer', 'exists:orders,id'],
        ]);

        $order = Order::findOrFail($validated['order_id']);

        if ($order->user_id !== $request->user()->id) {
            return $this->error('Order not found', 404);
        }

        if ($order->payment_status === 'paid') {
            return $this->error('Order is already paid');
        }

        $transaction = $this->mpesa->initiateStkForOrder($order);

        return $this->success([
            'checkout_request_id' => $transaction->checkout_request_id,
            'status' => $transaction->status?->value,
        ]);
    }

    /**
     * Flutter unpaid-screen compatibility endpoint.
     */
    public function stk(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'amount' => ['required', 'numeric', 'min:1'],
            'phone' => ['required', 'string', 'max:20'],
            'reference' => ['required', 'string', 'max:100'],
        ]);

        $result = $this->mpesa->initiateStk(
            (float) $validated['amount'],
            $validated['phone'],
            $validated['reference'],
            $request->user(),
        );

        return response()->json($result, 201);
    }

    public function status(Request $request, string $checkoutRequestId): JsonResponse
    {
        $transaction = $this->mpesa->getStatus(
            $checkoutRequestId,
            $request->user()?->business_id,
        );

        if (! $transaction) {
            return $this->error('Unknown checkout request', 404);
        }

        return $this->success([
            'id' => $transaction->id,
            'status' => $transaction->status?->value,
            'reference' => $transaction->reference,
            'mpesa_receipt_number' => $transaction->mpesa_receipt_number,
            'amount' => $transaction->amount,
        ]);
    }

    public function callback(Request $request): JsonResponse
    {
        $this->mpesa->handleCallback($request->all());

        return response()->json(['ResultCode' => 0, 'ResultDesc' => 'Accepted']);
    }
}
