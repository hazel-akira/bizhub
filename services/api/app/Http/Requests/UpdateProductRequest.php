<?php

namespace App\Http\Requests;

use App\Enums\ProductDepartment;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateProductRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => ['sometimes', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'category_id' => ['nullable', 'integer', 'exists:categories,id'],
            'department' => ['nullable', Rule::enum(ProductDepartment::class)],
            'cost_price' => ['sometimes', 'required', 'numeric', 'min:0'],
            'selling_price' => ['sometimes', 'numeric', 'min:0.01'],
            'stock_quantity' => ['sometimes', 'integer', 'min:0'],
            'reorder_level' => ['nullable', 'integer', 'min:0'],
            'expiry_date' => ['nullable', 'date'],
            'barcode' => ['nullable', 'string', 'max:100'],
            'is_active' => ['nullable', 'boolean'],
        ];
    }
}
