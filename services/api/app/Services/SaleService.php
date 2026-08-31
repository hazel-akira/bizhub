<?php

namespace App\Services;

use App\Models\Product;
use App\Models\Sale;
use App\Models\User;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class SaleService
{
    public function __construct(private readonly InventoryService $inventory) {}

    public function createSale(User $user, array $data): array
    {
        $sale = DB::transaction(function () use ($user, $data) {
            $businessId = $user->business_id;
            $discount = (float) ($data['discount'] ?? 0);
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
                $lineTotal = $unitPrice * $qty;
                $subtotal += $lineTotal;

                $lineItems[] = compact('product', 'qty', 'unitPrice', 'lineTotal');
            }

            $total = max(0, $subtotal - $discount + $tax);

            $sale = Sale::create([
                'business_id' => $businessId,
                'customer_id' => $data['customer_id'] ?? null,
                'user_id' => $user->id,
                'invoice_number' => 'INV-'.now()->format('YmdHis'),
                'subtotal' => $subtotal,
                'discount' => $discount,
                'tax' => $tax,
                'total_amount' => $total,
                'payment_method' => $data['payment_method'] ?? 'cash',
                'sale_date' => now(),
                'created_at' => now(),
            ]);

            foreach ($lineItems as $line) {
                $sale->items()->create([
                    'product_id' => $line['product']->id,
                    'quantity' => $line['qty'],
                    'unit_price' => $line['unitPrice'],
                    'total_price' => $line['lineTotal'],
                ]);

                $this->inventory->reduceStock($line['product'], $line['qty'], $user);
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
        $sale->loadMissing(['items.product', 'customer', 'payments']);

        $amountPaid = (float) $sale->payments->sum('amount');
        $total = (float) $sale->total_amount;
        $outstanding = max(0, round($total - $amountPaid, 2));

        return [
            'id' => $sale->id,
            'invoice_number' => $sale->invoice_number,
            'customer_id' => $sale->customer_id,
            'customer_name' => $sale->customer?->name,
            'payment_method' => $sale->payment_method,
            'subtotal' => (float) $sale->subtotal,
            'discount' => (float) $sale->discount,
            'tax' => (float) $sale->tax,
            'total_amount' => $total,
            'amount_paid' => round($amountPaid, 2),
            'outstanding' => $outstanding,
            'is_paid' => $outstanding <= 0.001,
            'sale_date' => $sale->sale_date?->toIso8601String(),
            'created_at' => $sale->created_at?->toIso8601String(),
            'items' => $sale->items->map(fn ($item) => [
                'id' => $item->id,
                'product_id' => $item->product_id,
                'quantity' => $item->quantity,
                'unit_price' => (float) $item->unit_price,
                'total_price' => (float) $item->total_price,
                'product' => $item->product ? [
                    'id' => $item->product->id,
                    'name' => $item->product->name,
                ] : null,
            ])->values()->all(),
        ];
    }

    private function outstandingForSale(Sale $sale): float
    {
        $sale->loadMissing('payments');

        return max(0, round((float) $sale->total_amount - (float) $sale->payments->sum('amount'), 2));
    }
}
