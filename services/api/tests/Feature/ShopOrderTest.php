<?php

namespace Tests\Feature;

use App\Models\Business;
use App\Models\Customer;
use App\Models\Product;
use App\Models\Sale;
use App\Models\ShopOrder;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ShopOrderTest extends TestCase
{
    use RefreshDatabase;

    private function foodVendorSetup(): array
    {
        $business = Business::create([
            'name' => 'Samosa Spot',
            'business_type' => 'food_vendor',
            'is_active' => true,
        ]);

        $user = User::factory()->create([
            'business_id' => $business->id,
            'role' => 'owner',
            'is_active' => true,
        ]);

        $customer = Customer::create([
            'business_id' => $business->id,
            'name' => 'Jane Doe',
            'phone' => '254712345678',
        ]);

        Product::create([
            'business_id' => $business->id,
            'name' => 'Ndengu Samosa',
            'cost_price' => 10,
            'selling_price' => 20,
            'stock_quantity' => 100,
            'is_active' => true,
        ]);

        Product::create([
            'business_id' => $business->id,
            'name' => 'Meat Samosa',
            'cost_price' => 15,
            'selling_price' => 30,
            'stock_quantity' => 100,
            'is_active' => true,
        ]);

        Sanctum::actingAs($user);

        return compact('business', 'user', 'customer');
    }

    public function test_can_create_and_list_pending_shop_orders(): void
    {
        ['customer' => $customer] = $this->foodVendorSetup();

        $this->postJson('/api/shop-orders', [
            'customer_id' => $customer->id,
            'ndengu_count' => 2,
            'meat_count' => 1,
        ])
            ->assertCreated()
            ->assertJsonPath('data.customer_name', 'Jane Doe')
            ->assertJsonPath('data.ndengu_count', 2)
            ->assertJsonPath('data.meat_count', 1)
            ->assertJsonPath('data.status', 'pending');

        $this->getJson('/api/shop-orders')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.customer_name', 'Jane Doe');
    }

    public function test_fulfilling_order_creates_credit_sale_and_marks_completed(): void
    {
        ['business' => $business, 'customer' => $customer] = $this->foodVendorSetup();

        $orderId = ShopOrder::create([
            'business_id' => $business->id,
            'customer_id' => $customer->id,
            'ndengu_count' => 3,
            'meat_count' => 0,
            'status' => 'pending',
            'order_date' => now(),
        ])->id;

        $this->postJson("/api/shop-orders/{$orderId}/fulfill")
            ->assertOk()
            ->assertJsonPath('data.order.status', 'completed')
            ->assertJsonPath('data.sale.payment_method', 'credit');

        $this->assertDatabaseHas('shop_orders', [
            'id' => $orderId,
            'status' => 'completed',
        ]);

        $this->assertSame(1, Sale::where('business_id', $business->id)->count());
    }
}
