<?php

namespace App\Models\Concerns;

use Illuminate\Database\Eloquent\Builder;

trait BelongsToBusiness
{
    public function scopeForBusiness(Builder $query, int $businessId): Builder
    {
        return $query->where($this->getTable().'.business_id', $businessId);
    }
}
