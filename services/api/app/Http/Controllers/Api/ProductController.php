<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Concerns\RespondsWithJson;
use App\Http\Controllers\Controller;
use App\Http\Requests\StoreCustomProductRequest;
use App\Http\Requests\StoreProductFromGlobalRequest;
use App\Http\Requests\StoreProductRequest;
use App\Http\Requests\UpdateProductRequest;
use App\Models\GlobalProduct;
use App\Models\Product;
use App\Services\GlobalCatalogService;
use App\Services\ProductImageService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProductController extends Controller
{
    use RespondsWithJson;

    public function index(Request $request): JsonResponse
    {
        $products = Product::forBusiness($request->user()->business_id)
            ->with(['category', 'globalProduct'])
            ->orderBy('name')
            ->get()
            ->map(fn (Product $p) => $this->format($p));

        return $this->success($products);
    }

    /** Public menu for web client (no auth). */
    public function publicMenu(ProductImageService $images): JsonResponse
    {
        $products = Product::query()
            ->where('is_active', true)
            ->orderBy('id')
            ->get()
            ->map(fn (Product $p) => [
                'id' => $p->id,
                'name' => $p->name,
                'price' => (int) $p->selling_price,
                'image_path' => $images->publicUrl($p->image_path),
            ]);

        return $this->success($products);
    }

    public function show(Request $request, Product $product): JsonResponse
    {
        $this->authorizeProduct($request, $product);

        return $this->success($this->format($product->load(['category', 'globalProduct'])));
    }

    public function store(StoreProductRequest $request): JsonResponse
    {
        $product = Product::create([
            ...$request->validated(),
            'business_id' => $request->user()->business_id,
            'global_product_id' => null,
            'is_active' => $request->boolean('is_active', true),
        ]);

        return $this->success(
            $this->format($product->load(['category', 'globalProduct'])),
            201
        );
    }

    public function storeFromGlobal(
        StoreProductFromGlobalRequest $request,
        GlobalCatalogService $catalog,
    ): JsonResponse {
        $businessId = $request->user()->business_id;
        $user = $request->user()->loadMissing('business');
        $validated = $request->validated();
        $global = GlobalProduct::with('category')->findOrFail($validated['global_product_id']);

        if (! $catalog->userCanImportGlobalProduct($user, $global)) {
            return response()->json([
                'message' => 'This product is not available for your business type.',
            ], 403);
        }

        $exists = Product::forBusiness($businessId)
            ->where('global_product_id', $global->id)
            ->exists();

        if ($exists) {
            return response()->json([
                'message' => 'This product is already in your inventory.',
            ], 422);
        }

        $product = Product::create([
            'business_id' => $businessId,
            'global_product_id' => $global->id,
            'category_id' => $validated['category_id'] ?? null,
            'name' => $global->name,
            'description' => $global->description,
            'barcode' => $validated['barcode'] ?? $global->barcode,
            'cost_price' => $validated['cost_price'] ?? 0,
            'selling_price' => $validated['selling_price'],
            'stock_quantity' => $validated['stock_quantity'] ?? 0,
            'reorder_level' => $validated['reorder_level'] ?? 5,
            'is_active' => true,
        ]);

        return $this->success(
            $this->format($product->load(['category', 'globalProduct'])),
            201
        );
    }

    public function storeCustom(StoreCustomProductRequest $request): JsonResponse
    {
        $validated = $request->validated();

        $product = Product::create([
            ...$validated,
            'business_id' => $request->user()->business_id,
            'global_product_id' => null,
            'is_active' => $request->boolean('is_active', true),
        ]);

        return $this->success(
            $this->format($product->load(['category', 'globalProduct'])),
            201
        );
    }

    public function update(UpdateProductRequest $request, Product $product): JsonResponse
    {
        $this->authorizeProduct($request, $product);
        $product->update($request->validated());

        return $this->success($this->format($product->fresh(['category', 'globalProduct'])));
    }

    public function destroy(Request $request, Product $product): JsonResponse
    {
        $this->authorizeProduct($request, $product);
        $product->delete();

        return $this->success(null, 200, 'Product deleted');
    }

    public function uploadImage(
        Request $request,
        Product $product,
        ProductImageService $images,
    ): JsonResponse {
        $this->authorizeProduct($request, $product);

        $validated = $request->validate([
            'image' => ['required', 'image', 'max:5120'],
        ]);

        $url = $images->store($product, $validated['image']);

        return $this->success([
            'product' => $this->format($product->fresh(['category', 'globalProduct']), $images),
            'image_url' => $url,
        ]);
    }

    private function authorizeProduct(Request $request, Product $product): void
    {
        abort_if(
            $product->business_id !== $request->user()->business_id,
            404,
            'Product not found'
        );
    }

    private function format(Product $product, ?ProductImageService $images = null): array
    {
        $images ??= app(ProductImageService::class);

        return [
            'id' => $product->id,
            'global_product_id' => $product->global_product_id,
            'is_from_global_catalog' => $product->isFromGlobalCatalog(),
            'name' => $product->name,
            'description' => $product->description,
            'category_id' => $product->category_id,
            'cost_price' => $product->cost_price,
            'selling_price' => $product->selling_price,
            'price' => (int) $product->selling_price,
            'stock_quantity' => $product->stock_quantity,
            'reorder_level' => $product->reorder_level,
            'barcode' => $product->barcode,
            'unit' => $product->globalProduct?->unit,
            'is_active' => (bool) $product->is_active,
            'global_product' => $product->globalProduct ? [
                'id' => $product->globalProduct->id,
                'name' => $product->globalProduct->name,
                'unit' => $product->globalProduct->unit,
                'category_name' => $product->globalProduct->category?->name,
            ] : null,
            'image_path' => $images->publicUrl($product->image_path),
        ];
    }
}
