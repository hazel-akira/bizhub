<?php

namespace Tests\Unit;

use App\Support\MailerAvailability;
use Tests\TestCase;

class MailerAvailabilityTest extends TestCase
{
    public function test_switches_from_log_to_smtp_when_credentials_exist(): void
    {
        config([
            'mail.default' => 'log',
            'services.resend.key' => null,
            'mail.mailers.smtp.host' => 'smtp.gmail.com',
            'mail.mailers.smtp.username' => 'owner@example.com',
            'mail.mailers.smtp.password' => 'app-password',
        ]);

        MailerAvailability::configure();

        $this->assertSame('smtp', config('mail.default'));
        $this->assertTrue(MailerAvailability::canDeliver());
    }

    public function test_switches_from_log_to_resend_when_api_key_exists(): void
    {
        config([
            'mail.default' => 'log',
            'services.resend.key' => 're_test_key',
            'mail.mailers.smtp.host' => '127.0.0.1',
            'mail.mailers.smtp.username' => '',
            'mail.mailers.smtp.password' => '',
        ]);

        MailerAvailability::configure();

        $this->assertSame('resend', config('mail.default'));
    }
}
