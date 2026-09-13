<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Concerns\RespondsWithJson;
use App\Http\Controllers\Controller;
use App\Enums\BusinessType;
use App\Http\Requests\ForgotPasswordRequest;
use App\Http\Requests\GoogleAuthRequest;
use App\Http\Requests\LoginRequest;
use App\Http\Requests\RegisterRequest;
use App\Http\Requests\ResetPasswordRequest;
use App\Models\Business;
use App\Models\User;
use App\Notifications\PasswordResetCodeNotification;
use App\Services\BusinessSetupService;
use App\Services\GoogleTokenVerifier;
use App\Support\StaffAccess;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\RateLimiter;
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
                'roles' => ['owner'],
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
        try {
            $payload = $verifier->verify($validated['id_token']);
        } catch (\RuntimeException $e) {
            throw ValidationException::withMessages([
                'id_token' => [$e->getMessage()],
            ]);
        }

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
                'roles' => ['owner'],
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

    public function forgotPassword(ForgotPasswordRequest $request): JsonResponse
    {
        $email = strtolower($request->validated()['email']);
        $rateKey = 'password-reset:'.$request->ip().':'.$email;

        if (RateLimiter::tooManyAttempts($rateKey, 5)) {
            throw ValidationException::withMessages([
                'email' => ['Please wait a minute before requesting another code.'],
            ]);
        }

        RateLimiter::hit($rateKey, 60);

        $user = User::query()->whereRaw('LOWER(email) = ?', [$email])->first();
        if ($user && $user->is_active !== false) {
            $code = str_pad((string) random_int(0, 999999), 6, '0', STR_PAD_LEFT);

            DB::table('password_reset_tokens')->updateOrInsert(
                ['email' => $user->email],
                [
                    'token' => Hash::make($code),
                    'created_at' => now(),
                ],
            );

            $user->notify(new PasswordResetCodeNotification($code));
        }

        return $this->success(
            null,
            200,
            'If that email is registered, we sent a 6-digit reset code.',
        );
    }

    public function resetPassword(ResetPasswordRequest $request): JsonResponse
    {
        $validated = $request->validated();
        $email = strtolower($validated['email']);
        $user = User::query()->whereRaw('LOWER(email) = ?', [$email])->first();
        $row = $user
            ? DB::table('password_reset_tokens')->where('email', $user->email)->first()
            : null;
        $expiresMinutes = (int) config('auth.passwords.users.expire', 60);
        $createdAt = $row?->created_at ? \Illuminate\Support\Carbon::parse($row->created_at) : null;

        $valid = $row
            && $createdAt
            && $createdAt->greaterThan(now()->subMinutes($expiresMinutes))
            && Hash::check($validated['code'], $row->token);

        if (! $valid) {
            throw ValidationException::withMessages([
                'code' => ['That reset code is invalid or has expired.'],
            ]);
        }
        if (! $user || $user->is_active === false) {
            throw ValidationException::withMessages([
                'email' => ['This account cannot reset its password.'],
            ]);
        }

        $user->update(['password' => $validated['password']]);
        $user->tokens()->delete();
        DB::table('password_reset_tokens')->where('email', $user->email)->delete();

        return $this->success(null, 200, 'Password updated. You can sign in now.');
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

        $roles = $user->staffRoles();

        return [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'role' => StaffAccess::primaryRole($roles),
            'roles' => $roles,
            'permissions' => StaffAccess::permissionsFor($roles),
            'business_id' => $user->business_id,
            'business_name' => $user->business?->name,
            'business_type' => $type?->value ?? $user->business?->business_type,
            'business_type_label' => $type?->label(),
            'is_active' => (bool) $user->is_active,
        ];
    }
}
