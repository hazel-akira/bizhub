<?php

namespace Tests\Feature;

use App\Models\User;
use App\Notifications\PasswordResetCodeNotification;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Notification;
use Tests\TestCase;

class PasswordResetTest extends TestCase
{
    use RefreshDatabase;

    public function test_forgot_password_emails_a_code_for_an_active_user(): void
    {
        Notification::fake();

        $user = User::factory()->create([
            'email' => 'owner@example.com',
            'is_active' => true,
        ]);

        $this->postJson('/api/auth/forgot-password', [
            'email' => 'Owner@example.com',
        ])
            ->assertOk()
            ->assertJsonPath(
                'message',
                'If that email is registered, we sent a 6-digit reset code.',
            );

        Notification::assertSentTo($user, PasswordResetCodeNotification::class);
        $this->assertDatabaseHas('password_reset_tokens', [
            'email' => 'owner@example.com',
        ]);
    }

    public function test_forgot_password_does_not_reveal_unknown_emails(): void
    {
        Notification::fake();

        $this->postJson('/api/auth/forgot-password', [
            'email' => 'missing@example.com',
        ])
            ->assertOk()
            ->assertJsonPath(
                'message',
                'If that email is registered, we sent a 6-digit reset code.',
            );

        Notification::assertNothingSent();
        $this->assertDatabaseCount('password_reset_tokens', 0);
    }

    public function test_reset_password_accepts_a_valid_code(): void
    {
        $user = User::factory()->create([
            'email' => 'owner@example.com',
            'password' => 'old-password',
        ]);

        \Illuminate\Support\Facades\DB::table('password_reset_tokens')->insert([
            'email' => $user->email,
            'token' => Hash::make('123456'),
            'created_at' => now(),
        ]);

        $this->postJson('/api/auth/reset-password', [
            'email' => 'owner@example.com',
            'code' => '123456',
            'password' => 'new-password',
            'password_confirmation' => 'new-password',
        ])
            ->assertOk()
            ->assertJsonPath('message', 'Password updated. You can sign in now.');

        $user->refresh();
        $this->assertTrue(Hash::check('new-password', $user->password));
        $this->assertDatabaseCount('password_reset_tokens', 0);
    }
}
