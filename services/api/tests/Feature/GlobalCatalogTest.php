<?php

namespace Tests\Feature;

use App\Models\Business;
use App\Models\User;
use Database\Seeders\GlobalCategorySeeder;
use Database\Seeders\GlobalProductSeeder;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class GlobalCatalogTest extends TestCase
{
    public function test_authenticated_business_sees_global_products_after_seed(): void
    {
        $this->seed(GlobalCategorySeeder::class);
        $this->seed(GlobalProductSeeder::class);

        $business = Business::create([
            'name' => 'Beauty Shop',
            'business_type' => 'beauty_shop',
            'is_active' => true,
        ]);

        $user = User::factory()->create([
            'business_id' => $business->id,
            'role' => 'owner',
            'is_active' => true,
        ]);

        Sanctum::actingAs($user);

        $this->getJson('/api/global-categories')
            ->assertOk()
            ->assertJsonPath('data.categories.0.name', 'Beauty & Cosmetics');

        $response = $this->getJson('/api/global-products')->assertOk();
        $names = collect($response->json('data'))->pluck('name')->all();
        $this->assertNotEmpty($names);
        $this->assertContains('Hair Gel', $names);
        $this->assertContains('Perfume', $names);
    }
}
