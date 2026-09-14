<?php

namespace App\Http\Requests;

use App\Enums\ProductDepartment;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreCustomProductRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $businessId = $this->user()->business_id;

        return [
            'name' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'category_id' => [
                'nullable',
                'integer',
                Rule::exists('categories', 'id')->where('business_id', $businessId),
            ],
            'department' => ['nullable', Rule::enum(ProductDepartment::class)],
            'cost_price' => ['required', 'numeric', 'min:0'],
            'selling_price' => ['required', 'numeric', 'min:0.01'],
            'stock_quantity' => ['nullable', 'integer', 'min:0'],
            'reorder_level' => ['nullable', 'integer', 'min:0'],
            'expiry_date' => ['nullable', 'date'],
            'barcode' => ['nullable', 'string', 'max:100'],
            'is_active' => ['nullable', 'boolean'],
        ];
    }
}
