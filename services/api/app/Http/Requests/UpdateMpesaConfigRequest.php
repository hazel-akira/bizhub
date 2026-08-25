<?php

namespace App\Http\Requests;

use App\Enums\MpesaAccountType;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateMpesaConfigRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->business_id !== null;
    }

    public function rules(): array
    {
        $hasConfig = $this->user()?->business?->mpesaConfig !== null;

        return [
            'shortcode' => [Rule::requiredIf(! $hasConfig), 'nullable', 'string', 'max:20'],
            'consumer_key' => [Rule::requiredIf(! $hasConfig), 'nullable', 'string', 'max:1000'],
            'consumer_secret' => [Rule::requiredIf(! $hasConfig), 'nullable', 'string', 'max:1000'],
            'passkey' => [Rule::requiredIf(! $hasConfig), 'nullable', 'string', 'max:1000'],
            'account_type' => ['nullable', Rule::enum(MpesaAccountType::class)],
        ];
    }
}
