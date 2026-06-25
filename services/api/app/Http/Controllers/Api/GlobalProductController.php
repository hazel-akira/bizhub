<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Concerns\RespondsWithJson;
use App\Http\Controllers\Controller;
use App\Models\GlobalProduct;
use App\Services\GlobalCatalogService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class GlobalProductController extends Controller
{
    use RespondsWithJson;

    public function index(Request $request, GlobalCatalogService $catalog): JsonResponse
    {
        $user = $request->user()->loadMissing('business');
        $query = GlobalProduct::query()->with('category');
        $catalog->scopeProductsForUser($query, $user);

        if ($request->filled('global_category_id')) {
            $categoryId = $request->integer('global_category_id');
            $allowedIds = $catalog->allowedCategoryIdsForUser($user);

            if (! in_array($categoryId, $allowedIds, true)) {
                return response()->json([
                    'message' => 'That category is not available for your business type.',
                ], 403);
            }

            $query->where('global_category_id', $categoryId);
        }

        $products = $query
            ->orderBy('name')
            ->get()
            ->map(fn (GlobalProduct $p) => $this->format($p));

        return $this->success($products);
    }

    public function search(Request $request, GlobalCatalogService $catalog): JsonResponse
    {
        $q = trim($request->string('q')->toString());

        if (strlen($q) < 2) {
            return response()->json([
                'message' => 'Search query must be at least 2 characters.',
            ], 422);
        }

        $user = $request->user()->loadMissing('business');
        $query = GlobalProduct::query()->with('category');
        $catalog->scopeProductsForUser($query, $user);

        $products = $query
            ->where(function ($query) use ($q) {
                $query->where('name', 'ilike', "%{$q}%")
                    ->orWhere('barcode', 'ilike', "%{$q}%")
                    ->orWhere('description', 'ilike', "%{$q}%");
            })
            ->orderBy('name')
            ->limit(50)
            ->get()
            ->map(fn (GlobalProduct $p) => $this->format($p));

        return $this->success($products);
    }

    private function format(GlobalProduct $product): array
    {
        return [
            'id' => $product->id,
            'name' => $product->name,
            'description' => $product->description,
            'barcode' => $product->barcode,
            'unit' => $product->unit,
            'global_category_id' => $product->global_category_id,
            'category_name' => $product->category?->name,
        ];
    }
}
