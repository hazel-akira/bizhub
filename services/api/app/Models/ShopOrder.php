<?php

namespace App\Models;

use App\Models\Concerns\BelongsToBusiness;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ShopOrder extends Model
{
    use BelongsToBusiness;

    protected $fillable = [
        'business_id',
        'customer_id',
        'user_id',
        'ndengu_count',
        'meat_count',
        'status',
        'order_date',
    ];

    protected function casts(): array
    {
        return [
            'ndengu_count' => 'integer',
            'meat_count' => 'integer',
            'order_date' => 'datetime',
        ];
    }

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
