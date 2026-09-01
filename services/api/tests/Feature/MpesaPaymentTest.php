<?php

namespace Tests\Feature;

use App\Enums\MpesaTransactionStatus;
use App\Events\MpesaPaymentReceived;
use App\Models\Business;
use App\Models\MpesaTransaction;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Event;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class MpesaPaymentTest extends TestCase
{
    use RefreshDatabase;

    public function test_callback_is_public_and_completes_pending_transaction(): void
    {
        Event::fake([MpesaPaymentReceived::class]);

        $business = Business::create([
            'name' => 'Test Shop',
            'business_type' => 'grocery_shop',
            'is_active' => true,
        ]);

        $transaction = MpesaTransaction::create([
            'business_id' => $business->id,
            'phone' => '254712345678',
            'amount' => 150,
            'checkout_request_id' => 'ws_CO_test_123',
            'status' => MpesaTransactionStatus::Pending,
        ]);

        $response = $this->postJson('/api/payments/stk-callback', [
            'Body' => [
                'stkCallback' => [
                    'MerchantRequestID' => 'm-1',
                    'CheckoutRequestID' => 'ws_CO_test_123',
                    'ResultCode' => 0,
                    'ResultDesc' => 'The service request is processed successfully.',
                    'CallbackMetadata' => [
                        'Item' => [
                            ['Name' => 'Amount', 'Value' => 150],
                            ['Name' => 'MpesaReceiptNumber', 'Value' => 'NLJ7RT61SV'],
                            ['Name' => 'PhoneNumber', 'Value' => 254712345678],
                        ],
                    ],
                ],
            ],
        ]);

        $response->assertOk()->assertJson([
            'ResultCode' => 0,
        ]);

        $transaction->refresh();
        $this->assertSame(MpesaTransactionStatus::Completed, $transaction->status);
        $this->assertSame('NLJ7RT61SV', $transaction->mpesa_receipt_number);

        Event::assertDispatched(MpesaPaymentReceived::class);
    }

    public function test_callback_marks_transaction_failed_when_result_code_is_not_zero(): void
    {
        Event::fake([MpesaPaymentReceived::class]);

        $business = Business::create([
            'name' => 'Test Shop',
            'business_type' => 'grocery_shop',
            'is_active' => true,
        ]);

        $transaction = MpesaTransaction::create([
            'business_id' => $business->id,
            'phone' => '254712345678',
            'amount' => 150,
            'checkout_request_id' => 'ws_CO_test_fail',
            'status' => MpesaTransactionStatus::Pending,
        ]);

        $this->postJson('/api/payments/stk-callback', [
            'Body' => [
                'stkCallback' => [
                    'CheckoutRequestID' => 'ws_CO_test_fail',
                    'ResultCode' => 1032,
                    'ResultDesc' => 'Request cancelled by user',
                ],
            ],
        ])->assertOk();

        $transaction->refresh();
        $this->assertSame(MpesaTransactionStatus::Failed, $transaction->status);
        Event::assertNotDispatched(MpesaPaymentReceived::class);
    }

    public function test_stk_push_requires_authentication(): void
    {
        $this->postJson('/api/mpesa/stk-push', [
            'phone' => '0712345678',
            'amount' => 100,
        ])->assertUnauthorized();
    }

    public function test_stk_push_requires_mpesa_config(): void
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

        $this->postJson('/api/mpesa/stk-push', [
            'business_id' => $business->id,
            'phone' => '0712345678',
            'amount' => 100,
        ])->assertStatus(422);
    }

    public function test_owner_can_save_mpesa_config(): void
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

        $this->putJson('/api/mpesa/config', [
            'shortcode' => '174379',
            'consumer_key' => 'test-consumer-key',
            'consumer_secret' => 'test-consumer-secret',
            'passkey' => 'test-passkey',
            'account_type' => 'paybill',
        ])
            ->assertOk()
            ->assertJsonPath('data.configured', true)
            ->assertJsonPath('data.shortcode', '174379');

        $this->getJson('/api/mpesa/config')
            ->assertOk()
            ->assertJsonPath('data.configured', true);
    }

    public function test_sandbox_paybill_shortcode_forces_paybill_account_type_on_save(): void
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

        $this->putJson('/api/mpesa/config', [
            'shortcode' => '174379',
            'consumer_key' => 'test-consumer-key',
            'consumer_secret' => 'test-consumer-secret',
            'passkey' => 'test-passkey',
            'account_type' => 'till',
        ])
            ->assertOk()
            ->assertJsonPath('data.account_type', 'paybill');
    }

    public function test_callback_url_with_mpesa_in_path_is_rejected(): void
    {
        config([
            'services.mpesa.callback_url' => 'https://example.com/api/mpesa/callback',
        ]);

        $info = app(\App\Services\MpesaService::class)->publicCallbackUrl();

        $this->assertFalse($info['valid']);
        $this->assertStringContainsString('mpesa', strtolower($info['error'] ?? ''));
    }

    public function test_valid_callback_url_is_accepted(): void
    {
        config([
            'services.mpesa.callback_url' => 'https://example.com/api/payments/stk-callback',
        ]);

        $info = app(\App\Services\MpesaService::class)->publicCallbackUrl();

        $this->assertTrue($info['valid']);
        $this->assertSame('https://example.com/api/payments/stk-callback', $info['url']);
    }
}
