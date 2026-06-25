<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Concerns\RespondsWithJson;
use App\Http\Controllers\Controller;
use App\Enums\BusinessType;
use App\Http\Requests\LoginRequest;
use App\Http\Requests\RegisterRequest;
use App\Models\Business;
use App\Models\User;
use App\Services\BusinessSetupService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
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

        if (! $user || ! Hash::check($validated['password'], $user->password)) {
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
