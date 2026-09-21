<?php

namespace Database\Seeders;

use App\Models\GlobalCategory;
use App\Models\GlobalProduct;
use App\Models\Product;
use Illuminate\Database\Seeder;

class GlobalProductSeeder extends Seeder
{
    public function run(): void
    {
        /** @var array<string, list<array{name: string, unit?: string}>> $catalog */
        $catalog = require database_path('data/global_product_catalog.php');

        foreach ($catalog as $categoryName => $products) {
            $category = GlobalCategory::where('name', $categoryName)->first();

            if ($category === null) {
                continue;
            }

            foreach ($products as $product) {
                GlobalProduct::updateOrCreate(
                    [
                        'global_category_id' => $category->id,
                        'name' => $product['name'],
                    ],
                    [
                        'unit' => $product['unit'] ?? 'piece',
                        'barcode' => null,
                        'description' => null,
                    ],
                );
            }
        }

        $bakery = GlobalCategory::query()->where('name', 'Bakery')->first();
        $snacks = GlobalCategory::query()->where('name', 'Food & Snacks')->first();
        if ($bakery && $snacks) {
            $bakeryNames = [
                'White Bread',
                'Brown Bread',
                'Mandazi',
                'Mahamri',
                'Doughnut',
                'Muffin',
                'Scones',
                'Cookies',
                'Queen cake',
                'Cake Slice',
                'Birthday cake',
                'Icing sugar',
            ];

            foreach ($bakeryNames as $name) {
                $fromSnacks = GlobalProduct::query()
                    ->where('global_category_id', $snacks->id)
                    ->where('name', $name)
                    ->first();
                $inBakery = GlobalProduct::query()
                    ->where('global_category_id', $bakery->id)
                    ->where('name', $name)
                    ->first();

                if ($fromSnacks && $inBakery && $fromSnacks->id !== $inBakery->id) {
                    Product::query()
                        ->where('global_product_id', $fromSnacks->id)
                        ->update(['global_product_id' => $inBakery->id]);
                    $fromSnacks->delete();
                } elseif ($fromSnacks && $inBakery === null) {
                    $fromSnacks->update(['global_category_id' => $bakery->id]);
                }
            }
        }
    }
}
