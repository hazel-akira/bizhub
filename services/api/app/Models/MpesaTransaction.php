<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class MpesaTransaction extends Model
{
    protected $fillable = [
        'order_id',
        'reference',
        'phone',
        'amount',
        'checkout_request_id',
        'merchant_request_id',
        'status',
        'mpesa_receipt_number',
        'result_description',
    ];

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }
}
