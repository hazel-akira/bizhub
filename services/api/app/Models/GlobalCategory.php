<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class GlobalCategory extends Model
{
    protected $fillable = [
        'name',
        'description',
    ];

    public function globalProducts(): HasMany
    {
        return $this->hasMany(GlobalProduct::class);
    }
}
