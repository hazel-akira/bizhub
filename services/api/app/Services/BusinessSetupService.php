<?php

namespace App\Services;

use App\Enums\BusinessType;
use App\Models\Business;
use App\Models\Category;
use App\Models\ExpenseCategory;
use App\Models\Product;

class BusinessSetupService
{
    public function setup(Business $business, BusinessType $type): void
    {
        $categoryIds = $this->seedProductCategories($business, $type);
        $this->seedExpenseCategories($business, $type);
        $this->seedStarterProducts($business, $type, $categoryIds);
    }

    /** @return array<string, int> */
    private function seedProductCategories(Business $business, BusinessType $type): array
    {
        $ids = [];

        foreach ($type->defaultProductCategories() as $name) {
            $category = Category::create([
                'business_id' => $business->id,
                'name' => $name,
                'created_at' => now(),
            ]);
            $ids[$name] = $category->id;
        }

        return $ids;
    }

    private function seedExpenseCategories(Business $business, BusinessType $type): void
    {
        foreach ($type->defaultExpenseCategories() as $name) {
            ExpenseCategory::create([
                'business_id' => $business->id,
                'name' => $name,
            ]);
        }
    }

    /** @param array<string, int> $categoryIds */
    private function seedStarterProducts(
        Business $business,
        BusinessType $type,
        array $categoryIds,
    ): void {
        foreach ($type->starterProducts() as $product) {
            Product::create([
                'business_id' => $business->id,
                'category_id' => $categoryIds[$product['category']] ?? null,
                'name' => $product['name'],
                'cost_price' => $product['selling_price'] * 0.5,
                'selling_price' => $product['selling_price'],
                'stock_quantity' => 0,
                'is_active' => true,
            ]);
        }
    }
}
