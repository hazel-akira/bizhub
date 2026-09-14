<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class ConfirmMpesaQrRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->business_id !== null;
    }

    public function rules(): array
    {
        return [
            'checkout_request_id' => ['required', 'string', 'max:80'],
            'mpesa_receipt_number' => ['required', 'string', 'min:6', 'max:20'],
        ];
    }
}
