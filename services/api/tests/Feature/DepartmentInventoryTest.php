<?php

namespace Tests\Feature;

use App\Models\Business;
use App\Models\Product;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class DepartmentInventoryTest extends TestCase
{
    use RefreshDatabase;

    private function actingAsShop(string $businessType = 'grocery_shop'): User
    {
        $business = Business::create([
            'name' => 'Test Shop',
            'business_type' => $businessType,
            'is_active' => true,
        ]);

        $user = User::factory()->create([
            'business_id' => $business->id,
            'role' => 'owner',
            'is_active' => true,
        ]);

        Sanctum::actingAs($user);

        return $user;
    }

    public function test_custom_product_saves_department_and_expiry(): void
    {
        $this->actingAsShop();

        $this->postJson('/api/products/custom', [
            'name' => 'Queen cake',
            'cost_price' => 40,
            'selling_price' => 80,
            'stock_quantity' => 12,
            'department' => 'bakery',
            'expiry_date' => '2026-09-16',
        ])
            ->assertCreated()
            ->assertJsonPath('data.name', 'Queen cake')
            ->assertJsonPath('data.department', 'bakery')
            ->assertJsonPath('data.department_label', 'Bakery')
            ->assertJsonPath('data.expiry_date', '2026-09-16');

        $this->assertDatabaseHas('products', [
            'name' => 'Queen cake',
            'department' => 'bakery',
        ]);
        $saved = Product::query()->where('name', 'Queen cake')->first();
        $this->assertSame('2026-09-16', $saved?->expiry_date?->toDateString());
    }

    public function test_bakery_business_defaults_department(): void
    {
        $this->actingAsShop('bakery');

        $this->postJson('/api/products/custom', [
            'name' => 'Mandazi',
            'cost_price' => 5,
            'selling_price' => 10,
            'stock_quantity' => 20,
        ])
            ->assertCreated()
            ->assertJsonPath('data.department', 'bakery');
    }

    public function test_product_update_can_change_department(): void
    {
        $user = $this->actingAsShop();
        $product = Product::create([
            'business_id' => $user->business_id,
            'name' => 'Pampers',
            'cost_price' => 200,
            'selling_price' => 350,
            'stock_quantity' => 8,
            'department' => 'baby_shop',
            'is_active' => true,
        ]);

        $this->putJson('/api/products/'.$product->id, [
            'department' => 'phone_repair',
            'selling_price' => 350,
            'cost_price' => 200,
            'stock_quantity' => 8,
        ])
            ->assertOk()
            ->assertJsonPath('data.department', 'phone_repair');
    }

    public function test_business_types_include_new_departments(): void
    {
        $this->getJson('/api/business-types')
            ->assertOk()
            ->assertJsonFragment(['id' => 'baby_shop', 'label' => 'Baby Shop'])
            ->assertJsonFragment(['id' => 'bakery', 'label' => 'Bakery'])
            ->assertJsonFragment(['id' => 'phone_repair']);
    }
}
