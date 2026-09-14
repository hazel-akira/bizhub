<?php

namespace App\Support;

class MailerAvailability
{
    public static function configure(): void
    {
        $current = (string) config('mail.default');
        if (! in_array($current, ['log', 'array', ''], true)) {
            return;
        }

        if (filled(config('services.resend.key'))) {
            config(['mail.default' => 'resend']);

            return;
        }

        $host = (string) config('mail.mailers.smtp.host');
        $user = (string) config('mail.mailers.smtp.username');
        $pass = (string) config('mail.mailers.smtp.password');
        $local = in_array($host, ['', '127.0.0.1', 'localhost'], true);

        if ($user !== '' && $pass !== '' && ! $local) {
            config(['mail.default' => 'smtp']);
        }
    }

    public static function canDeliver(): bool
    {
        if (app()->environment('testing')) {
            return true;
        }

        return ! in_array((string) config('mail.default'), ['log', 'array', ''], true);
    }
}
