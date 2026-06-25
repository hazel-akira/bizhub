<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Concerns\RespondsWithJson;
use App\Http\Controllers\Controller;
use App\Models\Category;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CategoryController extends Controller
{
    use RespondsWithJson;

    public function index(Request $request): JsonResponse
    {
        $categories = Category::forBusiness($request->user()->business_id)
            ->orderBy('name')
            ->get();

        return $this->success($categories);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
        ]);

        $category = Category::create([
            ...$validated,
            'business_id' => $request->user()->business_id,
            'created_at' => now(),
        ]);

        return $this->success($category, 201);
    }

    public function update(Request $request, Category $category): JsonResponse
    {
        $this->authorizeCategory($request, $category);

        $validated = $request->validate([
            'name' => ['sometimes', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
        ]);

        $category->update($validated);

        return $this->success($category->fresh());
    }

    public function destroy(Request $request, Category $category): JsonResponse
    {
        $this->authorizeCategory($request, $category);
        $category->delete();

        return $this->success(null, 200, 'Category deleted');
    }

    private function authorizeCategory(Request $request, Category $category): void
    {
        abort_if(
            $category->business_id !== $request->user()->business_id,
            404,
            'Category not found'
        );
    }
}
