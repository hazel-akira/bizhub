<?php

namespace Tests\Feature;

use App\Models\Business;
use App\Models\Product;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AssistantChatTest extends TestCase
{
    use RefreshDatabase;

    private function actingAsShop(): User
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

        Sanctum::actingAs($user);

        return $user;
    }

    public function test_keyword_fallback_answers_today_summary_without_openai(): void
    {
        config(['services.openai.key' => '']);
        $this->actingAsShop();

        $response = $this->postJson('/api/assistant/chat', ['message' => 'today summary'])
            ->assertOk()
            ->assertJsonPath('data.ai', false);

        $this->assertStringContainsString(
            'today snapshot',
            (string) $response->json('data.reply')
        );
    }

    public function test_openai_tool_adds_a_product(): void
    {
        config([
            'services.openai.key' => 'test-key',
            'services.openai.model' => 'gpt-4o-mini',
            'services.openai.base_url' => 'https://api.openai.com/v1',
        ]);
        $this->actingAsShop();

        $calls = 0;
        Http::fake(function () use (&$calls) {
            $calls++;
            if ($calls === 1) {
                return Http::response([
                    'choices' => [[
                        'message' => [
                            'role' => 'assistant',
                            'content' => null,
                            'tool_calls' => [[
                                'id' => 'call_1',
                                'type' => 'function',
                                'function' => [
                                    'name' => 'add_product',
                                    'arguments' => json_encode([
                                        'name' => 'Fresh milk 500ml',
                                        'selling_price' => 60,
                                        'cost_price' => 45,
                                        'stock_quantity' => 12,
                                        'subcategory' => 'Dairy',
                                    ]),
                                ],
                            ]],
                        ],
                    ]],
                ]);
            }

            return Http::response([
                'choices' => [[
                    'message' => [
                        'role' => 'assistant',
                        'content' => 'Added Fresh milk 500ml at KES 60, stock 12, subcategory Dairy.',
                    ],
                ]],
            ]);
        });

        $this->postJson('/api/assistant/chat', [
            'message' => 'add fresh milk 500ml selling 60 buying 45 stock 12 subcategory dairy',
        ])
            ->assertOk()
            ->assertJsonPath('data.ai', true)
            ->assertJsonPath('data.actions.0', 'product_created')
            ->assertJsonFragment(['reply' => 'Added Fresh milk 500ml at KES 60, stock 12, subcategory Dairy.']);

        $this->assertDatabaseHas('products', [
            'name' => 'Fresh milk 500ml',
            'stock_quantity' => 12,
        ]);
        $this->assertDatabaseHas('categories', [
            'name' => 'Dairy',
        ]);
        $this->assertTrue(Product::query()->where('name', 'Fresh milk 500ml')->exists());
    }

    public function test_message_is_required(): void
    {
        $this->actingAsShop();

        $this->postJson('/api/assistant/chat', [])
            ->assertStatus(422);
    }
}
