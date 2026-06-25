<?php

namespace Database\Seeders;

use App\Models\Product;
use Illuminate\Database\Seeder;

class ProductSeeder extends Seeder
{
    public function run(): void
    {
        $products = [
            [
                'name' => 'Ndengu Samosa',
                'price' => 20,
                'image_path' => null,
            ],
            [
                'name' => 'Meat Samosa',
                'price' => 40,
                'image_path' => null,
            ],
        ];

        foreach ($products as $product) {
            Product::updateOrCreate(
                ['name' => $product['name']],
                $product + ['is_active' => true],
            );
        }
    }
}
