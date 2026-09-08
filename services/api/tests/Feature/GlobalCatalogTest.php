<?php

namespace Tests\Feature;

use App\Enums\BusinessType;
use App\Models\Business;
use App\Models\Category;
use App\Models\Product;
use App\Models\User;
use App\Services\BusinessSetupService;
use Database\Seeders\GlobalCategorySeeder;
use Database\Seeders\GlobalProductSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class GlobalCatalogTest extends TestCase
{
    use RefreshDatabase;

    private function actingAsBusiness(string $businessType, string $name = 'Test Shop'): User
    {
        $business = Business::create([
            'name' => $name,
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

    private function seedCatalog(): void
    {
        $this->seed(GlobalCategorySeeder::class);
        $this->seed(GlobalProductSeeder::class);
    }

    public function test_authenticated_business_sees_global_products_after_seed(): void
    {
        $this->seedCatalog();
        $this->actingAsBusiness('beauty_shop', 'Beauty Shop');

        $this->getJson('/api/global-categories')
            ->assertOk()
            ->assertJsonPath('data.categories.0.name', 'Beauty & Cosmetics');

        $response = $this->getJson('/api/global-products')->assertOk();
        $names = collect($response->json('data'))->pluck('name')->all();
        $this->assertNotEmpty($names);
        $this->assertContains('Hair Gel', $names);
        $this->assertContains('Perfume', $names);
    }

    public function test_business_types_include_butchery(): void
    {
        $this->getJson('/api/business-types')
            ->assertOk()
            ->assertJsonFragment([
                'id' => 'butchery',
                'label' => 'Butchery',
            ]);
    }

    public function test_food_vendor_allowed_catalog_includes_snacks_and_meals(): void
    {
        $allowed = BusinessType::FoodVendor->allowedGlobalCatalogCategories();
        $this->assertContains('Food & Snacks', $allowed);
        $this->assertContains('Beverages', $allowed);

        $catalog = require database_path('data/global_product_catalog.php');
        $names = array_column($catalog['Food & Snacks'], 'name');
        $this->assertContains('Ndengu Samosa', $names);
        $this->assertContains('Meat Samosa', $names);
        $this->assertContains('Mandazi', $names);
        $this->assertContains('Ugali', $names);
        $this->assertContains('Nyama Choma', $names);
    }

    public function test_small_restaurant_allowed_catalog_includes_menu_and_meat(): void
    {
        $allowed = BusinessType::SmallRestaurant->allowedGlobalCatalogCategories();
        $this->assertContains('Food & Snacks', $allowed);
        $this->assertContains('Meat & Poultry', $allowed);

        $catalog = require database_path('data/global_product_catalog.php');
        $food = array_column($catalog['Food & Snacks'], 'name');
        $meat = array_column($catalog['Meat & Poultry'], 'name');
        $this->assertContains('Rice Plate', $food);
        $this->assertContains('Beef Stew', $food);
        $this->assertContains('Beef', $meat);
        $this->assertContains('Chicken', $meat);
    }

    public function test_butchery_allowed_catalog_includes_meat_types(): void
    {
        $this->getJson('/api/business-types')
            ->assertOk()
            ->assertJsonFragment(['id' => 'butchery']);

        $allowed = BusinessType::Butchery->allowedGlobalCatalogCategories();
        $this->assertContains('Meat & Poultry', $allowed);

        $catalog = require database_path('data/global_product_catalog.php');
        $names = array_column($catalog['Meat & Poultry'], 'name');
        foreach (['Beef', 'Pork', 'Mutton', 'Chicken', 'Fish', 'Other meat'] as $cut) {
            $this->assertContains($cut, $names);
        }
    }

    public function test_food_vendor_setup_does_not_seed_priced_samosas(): void
    {
        $business = Business::create([
            'name' => 'Street Bites',
            'business_type' => 'food_vendor',
            'is_active' => true,
        ]);

        (new BusinessSetupService())->setup($business, BusinessType::FoodVendor);

        $this->assertSame(0, Product::query()->where('business_id', $business->id)->count());
        $this->assertTrue(
            Category::query()->where('business_id', $business->id)->where('name', 'Snacks')->exists()
        );
    }

    public function test_business_types_include_kenyan_retail_categories(): void
    {
        $this->getJson('/api/business-types')
            ->assertOk()
            ->assertJsonFragment(['id' => 'mama_mboga', 'label' => 'Fresh Foods (Mama Mboga)'])
            ->assertJsonFragment(['id' => 'dairy_shop'])
            ->assertJsonFragment(['id' => 'poultry_shop'])
            ->assertJsonFragment(['id' => 'wholesale'])
            ->assertJsonFragment(['id' => 'liquor_store'])
            ->assertJsonFragment(['id' => 'gas_water'])
            ->assertJsonFragment(['id' => 'shoe_store'])
            ->assertJsonFragment(['id' => 'salon'])
            ->assertJsonFragment(['id' => 'agrovet'])
            ->assertJsonFragment(['id' => 'grocery_shop', 'label' => 'General Retail Kiosk']);
    }

    public function test_mama_mboga_catalog_includes_fresh_produce(): void
    {
        $allowed = BusinessType::MamaMboga->allowedGlobalCatalogCategories();
        $this->assertContains('Fresh Produce', $allowed);

        $catalog = require database_path('data/global_product_catalog.php');
        $names = array_column($catalog['Fresh Produce'], 'name');
        $this->assertContains('Sukuma wiki', $names);
        $this->assertContains('Hoho (capsicum)', $names);
        $this->assertContains('Dhania', $names);
    }

    public function test_butchery_setup_seeds_meat_types_without_prices(): void
    {
        $business = Business::create([
            'name' => 'Westlands Butchery',
            'business_type' => 'butchery',
            'is_active' => true,
        ]);

        (new BusinessSetupService())->setup($business, BusinessType::Butchery);

        foreach (['Beef', 'Goat', 'Pork', 'Chicken', 'Offal', 'Processed'] as $category) {
            $this->assertTrue(
                Category::query()
                    ->where('business_id', $business->id)
                    ->where('name', $category)
                    ->exists(),
                "Missing butchery category {$category}"
            );
        }

        foreach (['Beef with bone', 'Goat meat (mbuzi)', 'Matumbo', 'Sausages / smokies'] as $name) {
            $this->assertDatabaseHas('products', [
                'business_id' => $business->id,
                'name' => $name,
                'selling_price' => 0,
            ]);
        }
    }
}
