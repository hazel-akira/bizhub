<?php

namespace App\Services;

use App\Models\Customer;
use App\Models\Product;
use App\Models\Sale;
use App\Models\User;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Validation\ValidationException;

class SaleService
{
    public function __construct(private readonly InventoryService $inventory) {}

    public function createSale(User $user, array $data): array
    {
        $sale = DB::transaction(function () use ($user, $data) {
            $businessId = $user->business_id;
            $method = $this->normalizePaymentMethod((string) ($data['payment_method'] ?? 'cash'));
            $customerId = isset($data['customer_id']) ? (int) $data['customer_id'] : null;

            if ($method === 'credit' && $customerId === null) {
                throw ValidationException::withMessages([
                    'customer_id' => ['Select a customer for unpaid / credit sales.'],
                ]);
            }

            if ($customerId !== null) {
                $customer = Customer::forBusiness($businessId)->find($customerId);
                if (! $customer) {
                    throw ValidationException::withMessages([
                        'customer_id' => ['Customer not found for your business.'],
                    ]);
                }
            }

            $canDiscount = $user->hasPermission('apply_discount') || $user->hasPermission('edit_price');
            $canOverridePrice = $canDiscount || $user->hasPermission('edit_price');
            $discount = $canDiscount ? (float) ($data['discount'] ?? 0) : 0;
            $tax = (float) ($data['tax'] ?? 0);
            $subtotal = 0;
            $lineItems = [];

            foreach ($data['items'] as $item) {
                $product = Product::forBusiness($businessId)
                    ->where('is_active', true)
                    ->find($item['product_id']);

                if (! $product) {
                    throw ValidationException::withMessages([
                        'items' => ['One or more products are invalid for your business.'],
                    ]);
                }

                $qty = (int) $item['quantity'];
                $unitPrice = (float) $product->selling_price;
                if ($canOverridePrice
                    && array_key_exists('unit_price', $item)
                    && $item['unit_price'] !== null) {
                    $unitPrice = (float) $item['unit_price'];
                }

                if ($unitPrice <= 0) {
                    throw ValidationException::withMessages([
                        'items' => ['Set a selling price for '.$product->name.' in Inventory first.'],
                    ]);
                }

                $lineTotal = $unitPrice * $qty;
                $subtotal += $lineTotal;

                $lineItems[] = [
                    'product' => $product,
                    'qty' => $qty,
                    'unitPrice' => $unitPrice,
                    'unitCost' => (float) $product->cost_price,
                    'lineTotal' => $lineTotal,
                ];
            }

            $total = max(0, $subtotal - $discount + $tax);

            $sale = Sale::create([
                'business_id' => $businessId,
                'customer_id' => $customerId,
                'user_id' => $user->id,
                'invoice_number' => 'INV-'.now()->format('YmdHis'),
                'subtotal' => $subtotal,
                'discount' => $discount,
                'tax' => $tax,
                'total_amount' => $total,
                'payment_method' => $method,
                'sale_date' => now(),
                'created_at' => now(),
            ]);

            foreach ($lineItems as $line) {
                $itemPayload = [
                    'product_id' => $line['product']->id,
                    'quantity' => $line['qty'],
                    'unit_price' => $line['unitPrice'],
                    'total_price' => $line['lineTotal'],
                ];
                if (Schema::hasColumn('sale_items', 'unit_cost')) {
                    $itemPayload['unit_cost'] = $line['unitCost'];
                }

                $sale->items()->create($itemPayload);

                $this->inventory->reduceStock($line['product'], $line['qty'], $user);
            }

            if ($this->isCollectedAtSale($method) && $total > 0) {
                $this->ensureImmediatePayment($sale, $method, $total, $user->id);
            }

            return $sale->load(['items.product', 'customer', 'user', 'payments']);
        });

        return $this->formatSale($sale);
    }

    public function listForBusiness(int $businessId): Collection
    {
        return Sale::forBusiness($businessId)
            ->with(['items.product', 'customer', 'payments'])
            ->orderByDesc('sale_date')
            ->get()
            ->map(fn (Sale $sale) => $this->formatSale($sale));
    }

    public function listUnpaidForBusiness(int $businessId): Collection
    {
        return $this->listForBusiness($businessId)
            ->filter(fn (array $sale) => ($sale['outstanding'] ?? 0) > 0.001)
            ->values();
    }

    public function unpaidTotalForBusiness(int $businessId): float
    {
        return (float) $this->listUnpaidForBusiness($businessId)->sum('outstanding');
    }

    public function findForBusiness(int $businessId, int $saleId): ?Sale
    {
        return Sale::forBusiness($businessId)
            ->with(['items.product', 'customer', 'user', 'payments'])
            ->find($saleId);
    }

    public function findFormattedForBusiness(int $businessId, int $saleId): ?array
    {
        $sale = $this->findForBusiness($businessId, $saleId);

        return $sale ? $this->formatSale($sale) : null;
    }

    public function recordPayment(User $user, Sale $sale, float $amount, string $method = 'cash'): array
    {
        $sale = DB::transaction(function () use ($user, $sale, $amount, $method) {
            $sale->loadMissing('payments');
            $outstanding = $this->outstandingForSale($sale);

            if ($outstanding <= 0.001) {
                throw ValidationException::withMessages([
                    'amount' => ['This sale is already fully paid.'],
                ]);
            }

            if ($amount > $outstanding + 0.001) {
                throw ValidationException::withMessages([
                    'amount' => ['Payment cannot exceed the outstanding balance.'],
                ]);
            }

            $sale->payments()->create([
                'business_id' => $sale->business_id,
                'user_id' => $user->id,
                'amount' => $amount,
                'payment_method' => $method,
                'created_at' => now(),
            ]);

            $sale->refresh()->load(['items.product', 'customer', 'payments']);

            if ($this->outstandingForSale($sale) <= 0.001 && $sale->payment_method === 'credit') {
                $sale->update(['payment_method' => $method]);
                $sale->refresh();
            }

            return $sale;
        });

        return $this->formatSale($sale);
    }

    public function formatSale(Sale $sale): array
    {
        $this->repairMissingImmediatePayment($sale);
        $sale->loadMissing(['items.product', 'customer', 'payments']);

        $amountPaid = (float) $sale->payments->sum('amount');
        $total = (float) $sale->total_amount;
        $outstanding = max(0, round($total - $amountPaid, 2));
        $method = $this->normalizePaymentMethod((string) $sale->payment_method);

        if ($this->isCollectedAtSale($method) && $sale->payments->isEmpty()) {
            $amountPaid = $total;
            $outstanding = 0;
        }

        return [
            'id' => $sale->id,
            'invoice_number' => $sale->invoice_number,
            'customer_id' => $sale->customer_id,
            'customer_name' => $sale->customer?->name,
            'payment_method' => $method,
            'subtotal' => (float) $sale->subtotal,
            'discount' => (float) $sale->discount,
            'tax' => (float) $sale->tax,
            'total_amount' => $total,
            'amount_paid' => round($amountPaid, 2),
            'outstanding' => $outstanding,
            'is_paid' => $outstanding <= 0.001,
            'sale_date' => $sale->sale_date?->toIso8601String(),
            'created_at' => $sale->created_at?->toIso8601String(),
            'items' => $sale->items->map(function ($item) {
                $unitCost = 0.0;
                if (Schema::hasColumn('sale_items', 'unit_cost') && $item->unit_cost !== null) {
                    $unitCost = (float) $item->unit_cost;
                } elseif ($item->product) {
                    $unitCost = (float) $item->product->cost_price;
                }

                return [
                    'id' => $item->id,
                    'product_id' => $item->product_id,
                    'quantity' => $item->quantity,
                    'unit_price' => (float) $item->unit_price,
                    'unit_cost' => $unitCost,
                    'total_price' => (float) $item->total_price,
                    'line_profit' => round(((float) $item->unit_price - $unitCost) * (int) $item->quantity, 2),
                    'product' => $item->product ? [
                        'id' => $item->product->id,
                        'name' => $item->product->name,
                    ] : null,
                ];
            })->values()->all(),
        ];
    }

    private function outstandingForSale(Sale $sale): float
    {
        $sale->loadMissing('payments');

        return max(0, round((float) $sale->total_amount - (float) $sale->payments->sum('amount'), 2));
    }

    private function normalizePaymentMethod(string $method): string
    {
        $compact = strtolower(str_replace([' ', '-', '_'], '', trim($method)));

        return match ($compact) {
            'mpesa', 'mpesastk' => 'mpesa',
            'credit', 'unpaid', 'debt' => 'credit',
            'card' => 'card',
            default => $compact === '' ? 'cash' : ($compact === 'cash' ? 'cash' : strtolower(trim($method))),
        };
    }

    private function isCollectedAtSale(string $method): bool
    {
        return in_array($this->normalizePaymentMethod($method), ['cash', 'mpesa', 'card'], true);
    }

    private function ensureImmediatePayment(Sale $sale, string $method, float $total, ?int $userId): void
    {
        if (! $this->isCollectedAtSale($method) || $total <= 0) {
            return;
        }
        if (! Schema::hasTable('sale_payments')) {
            return;
        }

        $sale->payments()->create([
            'business_id' => $sale->business_id,
            'user_id' => $userId,
            'amount' => $total,
            'payment_method' => $this->normalizePaymentMethod($method),
            'created_at' => now(),
        ]);
    }

    /** Cash / M-Pesa sales created before payments were snapshotted still look unpaid. */
    private function repairMissingImmediatePayment(Sale $sale): void
    {
        $method = $this->normalizePaymentMethod((string) $sale->payment_method);
        if (! $this->isCollectedAtSale($method)) {
            return;
        }

        $sale->loadMissing('payments');
        $total = (float) $sale->total_amount;
        if ($total <= 0 || $sale->payments->isNotEmpty()) {
            return;
        }

        try {
            $sale->payments()->create([
                'business_id' => $sale->business_id,
                'user_id' => $sale->user_id,
                'amount' => $total,
                'payment_method' => $method,
                'created_at' => $sale->sale_date ?? now(),
            ]);
            $sale->unsetRelation('payments');
        } catch (\Throwable) {
            // Listing must still work if an older API database cannot store payments.
        }
    }
}
