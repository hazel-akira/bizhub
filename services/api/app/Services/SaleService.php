<?php

namespace App\Services;

use App\Models\Product;
use App\Models\Sale;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class SaleService
{
    public function __construct(private readonly InventoryService $inventory) {}

    public function createSale(User $user, array $data): Sale
    {
        return DB::transaction(function () use ($user, $data) {
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

            return $sale->load(['items.product', 'customer', 'user']);
        });
    }

    public function listForBusiness(int $businessId)
    {
        return Sale::forBusiness($businessId)
            ->with(['items.product', 'customer'])
            ->orderByDesc('sale_date')
            ->get();
    }

    public function findForBusiness(int $businessId, int $saleId): ?Sale
    {
        return Sale::forBusiness($businessId)
            ->with(['items.product', 'customer', 'user'])
            ->find($saleId);
    }
}
