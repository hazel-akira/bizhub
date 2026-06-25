<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class GlobalProduct extends Model
{
    protected $fillable = [
        'global_category_id',
        'name',
        'description',
        'barcode',
        'unit',
    ];

    public function category(): BelongsTo
    {
        return $this->belongsTo(GlobalCategory::class, 'global_category_id');
    }

    public function businessProducts(): HasMany
    {
        return $this->hasMany(Product::class, 'global_product_id');
    }
}
