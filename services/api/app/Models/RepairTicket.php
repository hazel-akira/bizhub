<?php

namespace App\Models;

use App\Enums\RepairTicketStatus;
use App\Models\Concerns\BelongsToBusiness;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class RepairTicket extends Model
{
    use BelongsToBusiness;

    protected $fillable = [
        'business_id',
        'user_id',
        'ticket_number',
        'customer_name',
        'customer_phone',
        'phone_model',
        'issue_description',
        'spare_parts_used',
        'labor_cost',
        'status',
    ];

    protected function casts(): array
    {
        return [
            'labor_cost' => 'decimal:2',
            'status' => RepairTicketStatus::class,
        ];
    }

    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
