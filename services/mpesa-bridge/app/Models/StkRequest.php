<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class StkRequest extends Model
{
    protected $fillable = [
        'checkout_request_id',
        'reference',
        'status',
        'mpesa_receipt_number',
        'order_id',
    ];

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }
}
