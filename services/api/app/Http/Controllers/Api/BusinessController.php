<?php

namespace App\Http\Controllers\Api;

use App\Enums\BusinessType;
use App\Http\Controllers\Concerns\RespondsWithJson;
use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class BusinessController extends Controller
{
    use RespondsWithJson;

    public function show(Request $request): JsonResponse
    {
        $business = $request->user()->business;

        $type = BusinessType::tryFromString($business->business_type);

        return $this->success([
            'id' => $business->id,
            'name' => $business->name,
            'business_type' => $type?->value ?? $business->business_type,
            'business_type_label' => $type?->label(),
            'phone' => $business->phone,
            'email' => $business->email,
            'address' => $business->address,
            'subscription_plan' => $business->subscription_plan,
            'is_active' => (bool) $business->is_active,
        ]);
    }

    public function update(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['sometimes', 'string', 'max:255'],
            'business_type' => ['sometimes', Rule::enum(BusinessType::class)],
            'phone' => ['nullable', 'string', 'max:20'],
            'email' => ['nullable', 'email', 'max:255'],
            'address' => ['nullable', 'string'],
        ]);

        $business = $request->user()->business;
        $business->update($validated);

        return $this->success($business->fresh());
    }
}
