<?php

namespace App\Services;

use App\Models\Product;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;

class ProductImageService
{
    public function store(Product $product, UploadedFile $file): string
    {
        $extension = $file->getClientOriginalExtension() ?: $file->extension() ?: 'jpg';
        $path = sprintf(
            'products/%d/%d.%s',
            $product->business_id,
            $product->id,
            strtolower($extension),
        );

        if ($product->image_path) {
            Storage::disk('public')->delete($product->image_path);
        }

        Storage::disk('public')->putFileAs(
            dirname($path),
            $file,
            basename($path),
        );

        $product->update(['image_path' => $path]);

        return $this->publicUrl($path) ?? '';
    }

    public function publicUrl(?string $path): ?string
    {
        if ($path === null || $path === '') {
            return null;
        }

        return asset('storage/' . ltrim($path, '/'));
    }
}
