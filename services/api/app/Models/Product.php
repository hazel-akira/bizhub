<?php

namespace App\Models;

use App\Models\Concerns\BelongsToBusiness;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Product extends Model
{
    use BelongsToBusiness;

    protected $fillable = [
        'business_id',
        'category_id',
        'global_product_id',
        'name',
        'description',
        'cost_price',
        'selling_price',
        'stock_quantity',
        'reorder_level',
        'barcode',
        'image_path',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'cost_price' => 'decimal:2',
            'selling_price' => 'decimal:2',
            'is_active' => 'boolean',
        ];
    }

    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class);
    }

    public function globalProduct(): BelongsTo
    {
        return $this->belongsTo(GlobalProduct::class, 'global_product_id');
    }

    public function isFromGlobalCatalog(): bool
    {
        return $this->global_product_id !== null;
    }

    public function orderItems(): HasMany
    {
        return $this->hasMany(OrderItem::class);
    }

    /** Price exposed to the web client API. */
    public function getPriceAttribute(): int
    {
        return (int) $this->selling_price;
    }
}
