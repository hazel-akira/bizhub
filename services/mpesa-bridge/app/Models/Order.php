<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Order extends Model
{
    protected $fillable = [
        'items',
        'total_amount',
        'phone_number',
        'user_id',
        'payment_status',
        'mpesa_receipt',
        'checkout_request_id',
    ];

    protected $casts = [
        'items' => 'array',
        'total_amount' => 'integer',
    ];
}
