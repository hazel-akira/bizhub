<?php

namespace Database\Seeders;

use App\Models\Product;
use Illuminate\Database\Seeder;

class ProductSeeder extends Seeder
{
    public function run(): void
    {
        $products = [
            ['name' => 'Beef Samosa', 'price' => 40, 'image_path' => '/assets/images/beef_samosa.png'],
            ['name' => 'Ndengu Samosa', 'price' => 20, 'image_path' => '/assets/images/ndengu_samosa.png'],
            ['name' => 'Chicken Samosa', 'price' => 50, 'image_path' => '/assets/images/chicken_samosa.png'],
        ];

        foreach ($products as $p) {
            Product::updateOrCreate(
                ['name' => $p['name']],
                ['price' => $p['price'], 'image_path' => $p['image_path']]
            );
        }
    }
}
