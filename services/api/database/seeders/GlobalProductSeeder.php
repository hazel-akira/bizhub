<?php

namespace Database\Seeders;

use App\Models\GlobalCategory;
use App\Models\GlobalProduct;
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
    }
}
