<?php

namespace App\Services;

use App\Models\Product;
use App\Models\User;
use Illuminate\Support\Facades\DB;

class InventoryService
{
    public function reduceStock(Product $product, int $quantity, User $user, string $notes = 'Sale'): void
    {
        DB::table('products')
            ->where('id', $product->id)
            ->where('business_id', $user->business_id)
            ->decrement('stock_quantity', $quantity);

        DB::table('inventory_transactions')->insert([
            'business_id' => $user->business_id,
            'product_id' => $product->id,
            'type' => 'out',
            'quantity' => $quantity,
            'notes' => $notes,
            'created_by' => $user->id,
            'created_at' => now(),
        ]);
    }
}
