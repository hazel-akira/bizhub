<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Concerns\RespondsWithJson;
use App\Http\Controllers\Controller;
use App\Models\Customer;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CustomerController extends Controller
{
    use RespondsWithJson;

    public function index(Request $request): JsonResponse
    {
        $customers = Customer::forBusiness($request->user()->business_id)
            ->orderBy('name')
            ->get();

        return $this->success($customers);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'phone' => ['nullable', 'string', 'max:30'],
            'email' => ['nullable', 'email', 'max:255'],
            'address' => ['nullable', 'string'],
        ]);

        $customer = Customer::create([
            ...$validated,
            'business_id' => $request->user()->business_id,
        ]);

        return $this->success($customer, 201);
    }

    public function update(Request $request, Customer $customer): JsonResponse
    {
        $this->authorizeCustomer($request, $customer);

        $validated = $request->validate([
            'name' => ['sometimes', 'string', 'max:255'],
            'phone' => ['nullable', 'string', 'max:30'],
            'email' => ['nullable', 'email', 'max:255'],
            'address' => ['nullable', 'string'],
        ]);

        $customer->update($validated);

        return $this->success($customer->fresh());
    }

    public function destroy(Request $request, Customer $customer): JsonResponse
    {
        $this->authorizeCustomer($request, $customer);
        $customer->delete();

        return $this->success(null, 200, 'Customer deleted');
    }

    private function authorizeCustomer(Request $request, Customer $customer): void
    {
        abort_if(
            $customer->business_id !== $request->user()->business_id,
            404,
            'Customer not found'
        );
    }
}
