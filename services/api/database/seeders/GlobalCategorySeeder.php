<?php

namespace Database\Seeders;

use App\Enums\GlobalCatalogCategory;
use App\Models\GlobalCategory;
use App\Models\GlobalProduct;
use Illuminate\Database\Seeder;

class GlobalCategorySeeder extends Seeder
{
    public function run(): void
    {
        $renameMap = [
            'Food' => GlobalCatalogCategory::FoodAndSnacks->value,
            'Electronics' => GlobalCatalogCategory::ElectronicsAndAccessories->value,
            'Pharmacy' => GlobalCatalogCategory::HouseholdItems->value,
        ];

        foreach ($renameMap as $old => $new) {
            GlobalCategory::query()->where('name', $old)->update(['name' => $new]);
        }

        foreach (GlobalCatalogCategory::cases() as $category) {
            GlobalCategory::updateOrCreate(
                ['name' => $category->value],
                ['description' => 'Akira Bites platform catalog — '.$category->value],
            );
        }

        $validNames = GlobalCatalogCategory::names();
        GlobalCategory::query()
            ->whereNotIn('name', $validNames)
            ->each(function (GlobalCategory $orphan) use ($validNames) {
                $replacement = GlobalCategory::query()
                    ->whereIn('name', $validNames)
                    ->where('name', GlobalCatalogCategory::Groceries->value)
                    ->first();

                if ($replacement && $orphan->id !== $replacement->id) {
                    GlobalProduct::query()
                        ->where('global_category_id', $orphan->id)
                        ->update(['global_category_id' => $replacement->id]);
                    $orphan->delete();
                }
            });
    }
}
