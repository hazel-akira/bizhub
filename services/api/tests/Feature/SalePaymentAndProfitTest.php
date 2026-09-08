<?php

namespace Tests\Feature;

use App\Models\Business;
use App\Models\Customer;
use App\Models\Expense;
use App\Models\Product;
use App\Models\Sale;
use App\Models\User;
use App\Services\DashboardService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class SalePaymentAndProfitTest extends TestCase
{
    use RefreshDatabase;

    private function shopSetup(): array
    {
        $business = Business::create([
            'name' => 'Test Shop',
            'business_type' => 'grocery_shop',
            'is_active' => true,
        ]);

        $user = User::factory()->create([
            'business_id' => $business->id,
            'role' => 'owner',
            'is_active' => true,
        ]);

        $customer = Customer::create([
            'business_id' => $business->id,
            'name' => 'Amina',
            'phone' => '254700000001',
        ]);

        $product = Product::create([
            'business_id' => $business->id,
            'name' => 'Rice 1kg',
            'cost_price' => 80,
            'selling_price' => 120,
            'stock_quantity' => 50,
            'is_active' => true,
        ]);

        Sanctum::actingAs($user);

        return compact('business', 'user', 'customer', 'product');
    }

    public function test_cash_sale_is_fully_paid_and_not_listed_as_unpaid(): void
    {
        ['product' => $product] = $this->shopSetup();

        $this->postJson('/api/sales', [
            'payment_method' => 'cash',
            'items' => [['product_id' => $product->id, 'quantity' => 2]],
        ])
            ->assertCreated()
            ->assertJsonPath('data.total_amount', 240)
            ->assertJsonPath('data.is_paid', true)
            ->assertJsonPath('data.outstanding', 0);

        $this->getJson('/api/sales/unpaid')
            ->assertOk()
            ->assertJsonCount(0, 'data');
    }

    public function test_credit_sale_requires_a_customer_and_appears_unpaid(): void
    {
        ['product' => $product, 'customer' => $customer] = $this->shopSetup();

        $this->postJson('/api/sales', [
            'payment_method' => 'credit',
            'items' => [['product_id' => $product->id, 'quantity' => 1]],
        ])->assertStatus(422);

        $this->postJson('/api/sales', [
            'payment_method' => 'credit',
            'customer_id' => $customer->id,
            'items' => [['product_id' => $product->id, 'quantity' => 1]],
        ])
            ->assertCreated()
            ->assertJsonPath('data.is_paid', false)
            ->assertJsonPath('data.outstanding', 120)
            ->assertJsonPath('data.customer_name', 'Amina');

        $this->getJson('/api/sales/unpaid')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.customer_name', 'Amina');
    }

    public function test_credit_sale_can_use_custom_unit_price(): void
    {
        ['product' => $product, 'customer' => $customer] = $this->shopSetup();

        $this->postJson('/api/sales', [
            'payment_method' => 'credit',
            'customer_id' => $customer->id,
            'items' => [[
                'product_id' => $product->id,
                'quantity' => 2,
                'unit_price' => 100,
            ]],
        ])
            ->assertCreated()
            ->assertJsonPath('data.total_amount', 200)
            ->assertJsonPath('data.outstanding', 200);
    }

    public function test_mpesa_sale_is_fully_paid(): void
    {
        ['product' => $product] = $this->shopSetup();

        $this->postJson('/api/sales', [
            'payment_method' => 'M-Pesa',
            'items' => [['product_id' => $product->id, 'quantity' => 1]],
        ])
            ->assertCreated()
            ->assertJsonPath('data.payment_method', 'mpesa')
            ->assertJsonPath('data.is_paid', true)
            ->assertJsonPath('data.outstanding', 0);
    }

    public function test_legacy_cash_sale_without_payment_row_is_repaired(): void
    {
        ['business' => $business, 'user' => $user, 'product' => $product] = $this->shopSetup();

        $sale = Sale::create([
            'business_id' => $business->id,
            'user_id' => $user->id,
            'invoice_number' => 'INV-LEGACY',
            'subtotal' => 120,
            'discount' => 0,
            'tax' => 0,
            'total_amount' => 120,
            'payment_method' => 'cash',
            'sale_date' => now(),
            'created_at' => now(),
        ]);
        $sale->items()->create([
            'product_id' => $product->id,
            'quantity' => 1,
            'unit_price' => 120,
            'total_price' => 120,
        ]);

        $this->getJson('/api/sales')
            ->assertOk()
            ->assertJsonPath('data.0.is_paid', true)
            ->assertJsonPath('data.0.outstanding', 0)
            ->assertJsonPath('data.0.payment_method', 'cash');

        $this->getJson('/api/sales/unpaid')
            ->assertOk()
            ->assertJsonCount(0, 'data');
    }

    public function test_dashboard_computes_gross_and_net_profit(): void
    {
        ['business' => $business, 'product' => $product] = $this->shopSetup();

        $this->postJson('/api/sales', [
            'payment_method' => 'cash',
            'items' => [['product_id' => $product->id, 'quantity' => 2]],
        ])->assertCreated();

        Expense::create([
            'business_id' => $business->id,
            'title' => 'Rent',
            'amount' => 50,
            'expense_date' => now(),
        ]);

        $summary = (new DashboardService())->summary($business->id);

        // Revenue 240, COGS 160, expenses 50
        $this->assertEquals(240.0, $summary['today_sales']);
        $this->assertEquals(160.0, $summary['today_cogs']);
        $this->assertEquals(80.0, $summary['today_gross_profit']);
        $this->assertEquals(30.0, $summary['today_operating_profit']);
        $this->assertEquals(30.0, $summary['today_net_profit']);
        $this->assertEquals(33.3, $summary['today_gross_margin']);
        $this->assertEquals(12.5, $summary['today_net_margin']);
    }
}
