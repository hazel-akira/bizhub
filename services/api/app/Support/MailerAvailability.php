<?php

namespace App\Support;

class MailerAvailability
{
    public static function configure(): void
    {
        $resend = self::secret('RESEND_API_KEY', config('services.resend.key'));
        if ($resend !== '') {
            config([
                'mail.default' => 'resend',
                'services.resend.key' => $resend,
            ]);

            return;
        }

        $host = self::secret('MAIL_HOST', config('mail.mailers.smtp.host')) ?: '127.0.0.1';
        $user = self::secret('MAIL_USERNAME', config('mail.mailers.smtp.username'), ['mail_username']);
        $pass = self::secret('MAIL_PASSWORD', config('mail.mailers.smtp.password'), ['mail_password']);
        $port = self::secret('MAIL_PORT', config('mail.mailers.smtp.port')) ?: '587';
        $scheme = self::secret('MAIL_SCHEME', config('mail.mailers.smtp.scheme'))
            ?: self::secret('MAIL_ENCRYPTION', null)
            ?: 'tls';

        if ($user === '' || $pass === '' || self::isLocalHost($host)) {
            return;
        }

        config([
            'mail.default' => 'smtp',
            'mail.mailers.smtp.host' => $host,
            'mail.mailers.smtp.username' => $user,
            'mail.mailers.smtp.password' => $pass,
            'mail.mailers.smtp.port' => (int) $port,
            'mail.mailers.smtp.scheme' => $scheme,
        ]);
    }

    public static function canDeliver(): bool
    {
        if (app()->environment('testing')) {
            return true;
        }

        self::configure();

        if ((string) config('mail.default') === 'resend' && filled(config('services.resend.key'))) {
            return true;
        }

        return (string) config('mail.default') === 'smtp'
            && (string) config('mail.mailers.smtp.username') !== ''
            && (string) config('mail.mailers.smtp.password') !== '';
    }

    private static function isLocalHost(string $host): bool
    {
        return in_array($host, ['', '127.0.0.1', 'localhost'], true);
    }

    /**
     * @param  list<string>  $aliases
     */
    private static function secret(string $key, mixed $configValue, array $aliases = []): string
    {
        foreach (array_merge([$key], $aliases) as $name) {
            foreach ([$name, strtoupper($name), strtolower($name)] as $candidate) {
                $fromEnv = $_ENV[$candidate] ?? $_SERVER[$candidate] ?? getenv($candidate);
                if (is_string($fromEnv) && trim($fromEnv) !== '') {
                    return trim($fromEnv);
                }
            }
        }

        if (is_string($configValue) && trim($configValue) !== '') {
            return trim($configValue);
        }

        return '';
    }
}
