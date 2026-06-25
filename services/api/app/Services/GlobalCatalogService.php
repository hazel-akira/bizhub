<?php

namespace App\Services;

use App\Enums\BusinessType;
use App\Models\GlobalCategory;
use App\Models\GlobalProduct;
use App\Models\User;
use Illuminate\Database\Eloquent\Builder;

class GlobalCatalogService
{
    /** @return list<string> */
    public function allowedCategoryNamesForUser(?User $user): array
    {
        $type = BusinessType::tryFromString($user?->business?->business_type);

        if ($type === null) {
            return [];
        }

        return $type->allowedGlobalCatalogCategories();
    }

    /** @return list<int> */
    public function allowedCategoryIdsForUser(?User $user): array
    {
        $names = $this->allowedCategoryNamesForUser($user);

        if ($names === []) {
            return [];
        }

        return GlobalCategory::query()
            ->whereIn('name', $names)
            ->pluck('id')
            ->all();
    }

    /** @param Builder<GlobalProduct> $query */
    public function scopeProductsForUser(Builder $query, ?User $user): Builder
    {
        $categoryIds = $this->allowedCategoryIdsForUser($user);

        return $query->whereIn('global_category_id', $categoryIds);
    }

    /** @param Builder<GlobalCategory> $query */
    public function scopeCategoriesForUser(Builder $query, ?User $user): Builder
    {
        $names = $this->allowedCategoryNamesForUser($user);

        return $query->whereIn('name', $names);
    }

    public function userCanImportGlobalProduct(?User $user, GlobalProduct $globalProduct): bool
    {
        $allowedIds = $this->allowedCategoryIdsForUser($user);

        return in_array($globalProduct->global_category_id, $allowedIds, true);
    }
}
