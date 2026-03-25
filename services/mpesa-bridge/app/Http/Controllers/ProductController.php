<?php

namespace App\Http\Controllers;

use App\Models\Product;

class ProductController extends Controller
{
    /**
     * List all products (menu items).
     */
    public function index()
    {
        $products = Product::orderBy('name')->get();

        return response()->json([
            'data' => $products->map(fn (Product $p) => [
                'id' => (string) $p->id,
                'name' => $p->name,
                'price' => $p->price,
                'image_path' => $p->image_path,
            ]),
        ]);
    }
}
