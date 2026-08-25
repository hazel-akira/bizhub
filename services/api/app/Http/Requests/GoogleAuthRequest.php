<?php

namespace App\Http\Requests;

use App\Enums\BusinessType;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class GoogleAuthRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'id_token' => ['required', 'string'],
            'name' => ['sometimes', 'nullable', 'string', 'max:255'],
            'business_name' => ['sometimes', 'nullable', 'string', 'max:255'],
            'business_type' => ['sometimes', 'nullable', Rule::enum(BusinessType::class)],
        ];
    }
}
