<?php

namespace App\Http\Requests;

use App\Enums\RepairTicketStatus;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateRepairTicketRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'customer_name' => ['sometimes', 'string', 'max:255'],
            'customer_phone' => ['nullable', 'string', 'max:30'],
            'phone_model' => ['sometimes', 'string', 'max:255'],
            'issue_description' => ['sometimes', 'string', 'max:2000'],
            'spare_parts_used' => ['nullable', 'string', 'max:2000'],
            'labor_cost' => ['sometimes', 'numeric', 'min:0'],
            'status' => ['sometimes', Rule::enum(RepairTicketStatus::class)],
        ];
    }
}
