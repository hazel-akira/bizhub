<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Concerns\RespondsWithJson;
use App\Http\Controllers\Controller;
use App\Models\GlobalCategory;
use App\Services\GlobalCatalogService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class GlobalCategoryController extends Controller
{
    use RespondsWithJson;

    public function index(Request $request, GlobalCatalogService $catalog): JsonResponse
    {
        $user = $request->user()->loadMissing('business');
        $allowedNames = $catalog->allowedCategoryNamesForUser($user);

        $categories = GlobalCategory::query()
            ->when(
                $allowedNames !== [],
                fn ($q) => $q->whereIn('name', $allowedNames),
                fn ($q) => $q->whereRaw('1 = 0'),
            )
            ->withCount('globalProducts')
            ->orderBy('name')
            ->get()
            ->map(fn (GlobalCategory $c) => [
                'id' => $c->id,
                'name' => $c->name,
                'description' => $c->description,
                'products_count' => $c->global_products_count,
            ]);

        return $this->success([
            'business_type' => $user->business?->business_type,
            'allowed_categories' => $allowedNames,
            'categories' => $categories,
        ]);
    }
}
