<?php

namespace App\Services;

use App\Models\Customer;
use App\Models\Product;
use App\Models\ShopOrder;
use App\Models\User;
use Illuminate\Support\Collection;
use Illuminate\Validation\ValidationException;

class ShopOrderService
{
    public function __construct(private readonly SaleService $sales) {}

    public function listPendingForBusiness(int $businessId): Collection
    {
        return ShopOrder::forBusiness($businessId)
            ->where('status', 'pending')
            ->with('customer')
            ->orderByDesc('order_date')
            ->get()
            ->map(fn (ShopOrder $order) => $this->format($order));
    }

    public function create(User $user, array $data): array
    {
        $businessId = $user->business_id;
        $customer = Customer::forBusiness($businessId)->find($data['customer_id']);

        if (! $customer) {
            throw ValidationException::withMessages([
                'customer_id' => ['Customer not found for your business.'],
            ]);
        }

        $ndengu = (int) ($data['ndengu_count'] ?? 0);
        $meat = (int) ($data['meat_count'] ?? 0);

        if ($ndengu <= 0 && $meat <= 0) {
            throw ValidationException::withMessages([
                'ndengu_count' => ['Enter at least one samosa quantity.'],
            ]);
        }

        $order = ShopOrder::create([
            'business_id' => $businessId,
            'customer_id' => $customer->id,
            'user_id' => $user->id,
            'ndengu_count' => $ndengu,
            'meat_count' => $meat,
            'status' => 'pending',
            'order_date' => now(),
        ]);

        return $this->format($order->load('customer'));
    }

    public function fulfill(User $user, ShopOrder $order): array
    {
        if ($order->status !== 'pending') {
            throw ValidationException::withMessages([
                'order' => ['This order is already completed.'],
            ]);
        }

        if ($order->business_id !== $user->business_id) {
            throw ValidationException::withMessages([
                'order' => ['Order not found.'],
            ]);
        }

        $items = $this->buildSaleItems($user->business_id, $order);

        $sale = $this->sales->createSale($user, [
            'customer_id' => $order->customer_id,
            'payment_method' => 'credit',
            'items' => $items,
        ]);

        $order->update(['status' => 'completed']);

        return [
            'order' => $this->format($order->fresh()->load('customer')),
            'sale' => $sale,
        ];
    }

    public function findForBusiness(int $businessId, int $orderId): ?ShopOrder
    {
        return ShopOrder::forBusiness($businessId)
            ->with('customer')
            ->find($orderId);
    }

    /** @return list<array{product_id: int, quantity: int}> */
    private function buildSaleItems(int $businessId, ShopOrder $order): array
    {
        $products = Product::forBusiness($businessId)
            ->where('is_active', true)
            ->get();

        $ndengu = $products->first(
            fn (Product $p) => str_contains(strtolower($p->name), 'ndengu')
        );
        $meat = $products->first(
            fn (Product $p) => str_contains(strtolower($p->name), 'meat')
        );

        $items = [];

        if ($order->ndengu_count > 0) {
            if (! $ndengu) {
                throw ValidationException::withMessages([
                    'items' => ['Ndengu Samosa product not found. Complete business setup or add products.'],
                ]);
            }
            $items[] = ['product_id' => $ndengu->id, 'quantity' => $order->ndengu_count];
        }

        if ($order->meat_count > 0) {
            if (! $meat) {
                throw ValidationException::withMessages([
                    'items' => ['Meat Samosa product not found. Complete business setup or add products.'],
                ]);
            }
            $items[] = ['product_id' => $meat->id, 'quantity' => $order->meat_count];
        }

        return $items;
    }

    public function format(ShopOrder $order): array
    {
        $order->loadMissing('customer');

        return [
            'id' => $order->id,
            'customer_id' => $order->customer_id,
            'customer_name' => $order->customer?->name,
            'ndengu_count' => $order->ndengu_count,
            'meat_count' => $order->meat_count,
            'status' => $order->status,
            'order_date' => $order->order_date?->toIso8601String(),
            'created_at' => $order->created_at?->toIso8601String(),
        ];
    }
}
