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

    public function test_bakery_saves_expiry_and_forces_bakery_department(): void
    {
        $this->actingAsShop('bakery');

        $this->postJson('/api/products/custom', [
            'name' => 'Queen cake',
            'cost_price' => 40,
            'selling_price' => 80,
            'stock_quantity' => 12,
            'department' => 'phone_repair',
            'expiry_date' => '2026-09-16',
        ])
            ->assertCreated()
            ->assertJsonPath('data.name', 'Queen cake')
            ->assertJsonPath('data.department', 'bakery')
            ->assertJsonPath('data.department_label', 'Bakery')
            ->assertJsonPath('data.expiry_date', '2026-09-16');
    }

    public function test_grocery_cannot_save_bakery_department_or_expiry(): void
    {
        $this->actingAsShop('grocery_shop');

        $this->postJson('/api/products/custom', [
            'name' => 'Queen cake',
            'cost_price' => 40,
            'selling_price' => 80,
            'stock_quantity' => 12,
            'department' => 'bakery',
            'expiry_date' => '2026-09-16',
        ])
            ->assertCreated()
            ->assertJsonPath('data.department', null)
            ->assertJsonPath('data.department_label', null)
            ->assertJsonPath('data.expiry_date', null);

        $saved = Product::query()->where('name', 'Queen cake')->first();
        $this->assertNull($saved?->department);
        $this->assertNull($saved?->expiry_date);
    }

    public function test_phone_repair_ignores_expiry_and_forces_own_department(): void
    {
        $this->actingAsShop('phone_repair');

        $this->postJson('/api/products/custom', [
            'name' => 'Phone screen',
            'cost_price' => 800,
            'selling_price' => 1500,
            'stock_quantity' => 4,
            'department' => 'bakery',
            'expiry_date' => '2026-09-16',
        ])
            ->assertCreated()
            ->assertJsonPath('data.department', 'phone_repair')
            ->assertJsonPath('data.department_label', 'Phone Repair')
            ->assertJsonPath('data.expiry_date', null);

        $saved = Product::query()->where('name', 'Phone screen')->first();
        $this->assertSame('phone_repair', $saved?->department?->value);
        $this->assertNull($saved?->expiry_date);
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

    public function test_grocery_cannot_switch_product_into_another_department(): void
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
            ->assertJsonPath('data.department', null);

        $this->assertNull($product->fresh()?->department);
    }

    public function test_phone_repair_hides_leftover_bakery_expiry_on_read(): void
    {
        $user = $this->actingAsShop('phone_repair');
        $product = Product::create([
            'business_id' => $user->business_id,
            'name' => 'Charging port',
            'cost_price' => 100,
            'selling_price' => 300,
            'stock_quantity' => 2,
            'department' => 'bakery',
            'expiry_date' => '2026-09-16',
            'is_active' => true,
        ]);

        $this->getJson('/api/products/'.$product->id)
            ->assertOk()
            ->assertJsonPath('data.department', 'phone_repair')
            ->assertJsonPath('data.expiry_date', null);
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
