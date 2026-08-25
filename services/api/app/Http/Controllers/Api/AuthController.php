<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Concerns\RespondsWithJson;
use App\Http\Controllers\Controller;
use App\Enums\BusinessType;
use App\Http\Requests\GoogleAuthRequest;
use App\Http\Requests\LoginRequest;
use App\Http\Requests\RegisterRequest;
use App\Models\Business;
use App\Models\User;
use App\Services\BusinessSetupService;
use App\Services\GoogleTokenVerifier;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    use RespondsWithJson;

    public function register(RegisterRequest $request, BusinessSetupService $setup): JsonResponse
    {
        $validated = $request->validated();
        $businessType = BusinessType::from($validated['business_type']);

        $user = DB::transaction(function () use ($validated, $businessType, $setup) {
            $business = Business::create([
                'name' => $validated['business_name'],
                'business_type' => $businessType->value,
                'email' => $validated['email'],
                'is_active' => true,
            ]);

            $setup->setup($business, $businessType);

            return User::create([
                'business_id' => $business->id,
                'name' => $validated['name'],
                'email' => $validated['email'],
                'password' => $validated['password'],
                'role' => 'owner',
                'is_active' => true,
            ]);
        });

        return $this->tokenResponse($user, 201);
    }

    public function login(LoginRequest $request): JsonResponse
    {
        $validated = $request->validated();

        $user = User::with('business')->where('email', $validated['email'])->first();

        if (! $user || ! $user->password || ! Hash::check($validated['password'], $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['The provided credentials are incorrect.'],
            ]);
        }

        if ($user->is_active === false) {
            throw ValidationException::withMessages([
                'email' => ['This account has been deactivated.'],
            ]);
        }

        return $this->tokenResponse($user);
    }

    public function google(
        GoogleAuthRequest $request,
        GoogleTokenVerifier $verifier,
        BusinessSetupService $setup,
    ): JsonResponse {
        $validated = $request->validated();
        $payload = $verifier->verify($validated['id_token']);

        $googleId = (string) $payload['sub'];
        $email = strtolower((string) $payload['email']);
        $profileName = trim((string) ($validated['name'] ?? $payload['name'] ?? ''));
        $displayName = $profileName !== '' ? $profileName : Str::before($email, '@');

        $user = User::with('business')->where('google_id', $googleId)->first();

        if (! $user) {
            $user = User::with('business')->where('email', $email)->first();
            if ($user) {
                if ($user->google_id !== null && $user->google_id !== $googleId) {
                    throw ValidationException::withMessages([
                        'email' => ['This email is linked to a different Google account.'],
                    ]);
                }

                $user->update(['google_id' => $googleId]);
                $user->refresh()->load('business');
            }
        }

        if ($user) {
            if ($user->is_active === false) {
                throw ValidationException::withMessages([
                    'email' => ['This account has been deactivated.'],
                ]);
            }

            return $this->tokenResponse($user);
        }

        $businessName = trim((string) ($validated['business_name'] ?? ''));
        $businessTypeValue = $validated['business_type'] ?? null;

        if ($businessName === '' || $businessTypeValue === null) {
            return $this->error(
                'Complete your business setup to create an account with Google.',
                422,
                ['needs_registration' => ['true']],
            );
        }

        $businessType = BusinessType::from($businessTypeValue);

        $user = DB::transaction(function () use (
            $displayName,
            $email,
            $googleId,
            $businessName,
            $businessType,
            $setup,
        ) {
            $business = Business::create([
                'name' => $businessName,
                'business_type' => $businessType->value,
                'email' => $email,
                'is_active' => true,
            ]);

            $setup->setup($business, $businessType);

            return User::create([
                'business_id' => $business->id,
                'name' => $displayName,
                'email' => $email,
                'google_id' => $googleId,
                'password' => Hash::make(Str::password(32)),
                'role' => 'owner',
                'is_active' => true,
            ]);
        });

        return $this->tokenResponse($user, 201);
    }

    public function profile(Request $request): JsonResponse
    {
        return $this->success($this->formatUser($request->user()->load('business')));
    }

    /** @deprecated Use profile() — kept for Flutter compatibility */
    public function me(Request $request): JsonResponse
    {
        return $this->profile($request);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()?->currentAccessToken()?->delete();

        return $this->success(null, 200, 'Logged out');
    }

    private function tokenResponse(User $user, int $status = 200): JsonResponse
    {
        $user->load('business');
        $token = $user->createToken('akira-bites')->plainTextToken;

        return $this->success([
            'access_token' => $token,
            'user' => $this->formatUser($user),
        ], $status);
    }

    private function formatUser(User $user): array
    {
        $type = BusinessType::tryFromString($user->business?->business_type);

        return [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'role' => $user->role,
            'business_id' => $user->business_id,
            'business_name' => $user->business?->name,
            'business_type' => $type?->value ?? $user->business?->business_type,
            'business_type_label' => $type?->label(),
            'is_active' => (bool) $user->is_active,
        ];
    }
}
