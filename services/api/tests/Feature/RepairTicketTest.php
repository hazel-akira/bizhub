<?php

namespace Tests\Feature;

use App\Models\Business;
use App\Models\RepairTicket;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class RepairTicketTest extends TestCase
{
    use RefreshDatabase;

    private function actingAsShop(): User
    {
        $business = Business::create([
            'name' => 'Fundi Shop',
            'business_type' => 'phone_repair',
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

    public function test_can_create_and_list_repair_tickets(): void
    {
        $this->actingAsShop();

        $this->postJson('/api/repair-tickets', [
            'customer_name' => 'Amina Otieno',
            'customer_phone' => '254712345678',
            'phone_model' => 'Tecno Spark 10',
            'issue_description' => 'Screen cracked after a drop',
            'spare_parts_used' => 'Phone screen',
            'labor_cost' => 500,
        ])
            ->assertCreated()
            ->assertJsonPath('data.customer_name', 'Amina Otieno')
            ->assertJsonPath('data.phone_model', 'Tecno Spark 10')
            ->assertJsonPath('data.status', 'pending')
            ->assertJsonPath('data.status_label', 'Pending');

        $this->getJson('/api/repair-tickets')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.issue_description', 'Screen cracked after a drop');
    }

    public function test_can_move_ticket_from_pending_to_collected(): void
    {
        $user = $this->actingAsShop();
        $ticket = RepairTicket::create([
            'business_id' => $user->business_id,
            'user_id' => $user->id,
            'ticket_number' => 'RT-TEST-0001',
            'customer_name' => 'John Mwangi',
            'phone_model' => 'Samsung A14',
            'issue_description' => 'No charging',
            'spare_parts_used' => 'Charging port',
            'labor_cost' => 300,
            'status' => 'pending',
        ]);

        $this->putJson('/api/repair-tickets/'.$ticket->id, [
            'status' => 'fixed',
            'spare_parts_used' => 'Charging port, charging cable',
            'labor_cost' => 400,
        ])
            ->assertOk()
            ->assertJsonPath('data.status', 'fixed');

        $this->putJson('/api/repair-tickets/'.$ticket->id, [
            'status' => 'collected',
        ])
            ->assertOk()
            ->assertJsonPath('data.status', 'collected')
            ->assertJsonPath('data.status_label', 'Collected');
    }
}
