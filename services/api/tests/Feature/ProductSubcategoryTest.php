<?php

namespace Tests\Feature;

use App\Models\Business;
use App\Models\Category;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ProductSubcategoryTest extends TestCase
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

    public function test_custom_product_saves_existing_subcategory(): void
    {
        $user = $this->actingAsShop();
        $category = Category::create([
            'business_id' => $user->business_id,
            'name' => 'Dry Goods',
            'created_at' => now(),
        ]);

        $this->postJson('/api/products/custom', [
            'name' => 'Pishori rice 1kg',
            'cost_price' => 150,
            'selling_price' => 200,
            'stock_quantity' => 10,
            'category_id' => $category->id,
        ])
            ->assertCreated()
            ->assertJsonPath('data.name', 'Pishori rice 1kg')
            ->assertJsonPath('data.category_id', $category->id)
            ->assertJsonPath('data.category_name', 'Dry Goods')
            ->assertJsonPath('data.subcategory', 'Dry Goods');
    }

    public function test_custom_product_creates_subcategory_from_name(): void
    {
        $this->actingAsShop();

        $this->postJson('/api/products/custom', [
            'name' => 'Fresh milk 500ml',
            'cost_price' => 40,
            'selling_price' => 55,
            'stock_quantity' => 8,
            'subcategory' => 'Fresh',
        ])
            ->assertCreated()
            ->assertJsonPath('data.category_name', 'Fresh')
            ->assertJsonPath('data.subcategory', 'Fresh');

        $this->assertDatabaseHas('categories', [
            'name' => 'Fresh',
        ]);
    }

    public function test_update_product_reuses_existing_subcategory_name(): void
    {
        $user = $this->actingAsShop();
        $category = Category::create([
            'business_id' => $user->business_id,
            'name' => 'Household',
            'created_at' => now(),
        ]);

        $create = $this->postJson('/api/products/custom', [
            'name' => 'Bar soap',
            'cost_price' => 30,
            'selling_price' => 50,
            'stock_quantity' => 20,
        ])->assertCreated();

        $productId = $create->json('data.id');

        $this->putJson('/api/products/'.$productId, [
            'selling_price' => 50,
            'cost_price' => 30,
            'stock_quantity' => 20,
            'subcategory' => 'household',
        ])
            ->assertOk()
            ->assertJsonPath('data.category_id', $category->id)
            ->assertJsonPath('data.subcategory', 'Household');
    }
}
