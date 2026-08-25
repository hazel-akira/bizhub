<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use RuntimeException;

class GoogleTokenVerifier
{
    /**
     * @return array<string, mixed>
     */
    public function verify(string $idToken): array
    {
        $idToken = trim($idToken);
        if ($idToken === '') {
            throw new RuntimeException('Google ID token is required.');
        }

        $response = Http::timeout(10)->get(
            'https://oauth2.googleapis.com/tokeninfo',
            ['id_token' => $idToken],
        );

        if (! $response->ok()) {
            throw new RuntimeException('Invalid or expired Google sign-in token.');
        }

        /** @var array<string, mixed> $payload */
        $payload = $response->json();
        $audience = (string) ($payload['aud'] ?? '');
        $allowedAudiences = array_filter(array_map(
            'trim',
            explode(',', (string) config('services.google.client_ids', '')),
        ));

        if ($allowedAudiences === [] || ! in_array($audience, $allowedAudiences, true)) {
            throw new RuntimeException('Google token audience is not allowed for this app.');
        }

        $emailVerified = filter_var($payload['email_verified'] ?? false, FILTER_VALIDATE_BOOL);
        if (! $emailVerified) {
            throw new RuntimeException('Google account email is not verified.');
        }

        $expiresAt = (int) ($payload['exp'] ?? 0);
        if ($expiresAt > 0 && $expiresAt <= time()) {
            throw new RuntimeException('Google sign-in token has expired.');
        }

        if (empty($payload['sub']) || empty($payload['email'])) {
            throw new RuntimeException('Google token is missing required profile fields.');
        }

        return $payload;
    }
}
