<?php

namespace App\Enums;

enum BusinessType: string
{
    case FoodVendor = 'food_vendor';
    case GroceryShop = 'grocery_shop';
    case Boutique = 'boutique';
    case HardwareStore = 'hardware_store';
    case Pharmacy = 'pharmacy';
    case ElectronicsShop = 'electronics_shop';
    case Cybercafe = 'cybercafe';
    case SmallRestaurant = 'small_restaurant';
    case BeautyShop = 'beauty_shop';

    public function label(): string
    {
        return match ($this) {
            self::FoodVendor => 'Food Vendors',
            self::GroceryShop => 'Grocery Shop',
            self::Boutique => 'Boutiques',
            self::HardwareStore => 'Hardware Stores',
            self::Pharmacy => 'Pharmacies',
            self::ElectronicsShop => 'Electronic Shop',
            self::Cybercafe => 'Cybercafe',
            self::SmallRestaurant => 'Small Restaurant',
            self::BeautyShop => 'Beauty & Cosmetics',
        };
    }

    public function description(): string
    {
        return match ($this) {
            self::FoodVendor => 'Street food, snacks, and quick bites.',
            self::GroceryShop => 'Groceries, household items, and daily essentials.',
            self::Boutique => 'Clothing, accessories, and fashion retail.',
            self::HardwareStore => 'Tools, building materials, and hardware supplies.',
            self::Pharmacy => 'Medicines, health products, and personal care.',
            self::ElectronicsShop => 'Phones, computers, and electronic accessories.',
            self::Cybercafe => 'Internet, printing, and computer services.',
            self::SmallRestaurant => 'Sit-down meals, drinks, and table service.',
            self::BeautyShop => 'Skincare, makeup, and personal beauty products.',
        };
    }

    /** @return list<string> */
    public function defaultProductCategories(): array
    {
        return match ($this) {
            self::FoodVendor => ['Snacks', 'Beverages', 'Ready Meals'],
            self::GroceryShop => ['Fresh Produce', 'Dry Goods', 'Dairy', 'Household'],
            self::Boutique => ['Clothing', 'Accessories', 'Shoes'],
            self::HardwareStore => ['Tools', 'Building Materials', 'Paint', 'Electrical'],
            self::Pharmacy => ['Medicines', 'OTC', 'Personal Care', 'Supplements'],
            self::ElectronicsShop => ['Phones', 'Computers', 'Accessories', 'Appliances'],
            self::Cybercafe => ['Printing', 'Internet', 'Computer Services'],
            self::SmallRestaurant => ['Appetizers', 'Main Course', 'Drinks', 'Desserts'],
            self::BeautyShop => ['Skincare', 'Makeup', 'Hair Care', 'Fragrances'],
        };
    }

    /** @return list<string> */
    public function defaultExpenseCategories(): array
    {
        return match ($this) {
            self::FoodVendor => ['Ingredients', 'Transport', 'Gas', 'Labour'],
            self::GroceryShop => ['Stock', 'Transport', 'Rent', 'Utilities'],
            self::Boutique => ['Stock', 'Rent', 'Marketing', 'Packaging'],
            self::HardwareStore => ['Stock', 'Rent', 'Transport', 'Utilities'],
            self::Pharmacy => ['Stock', 'Licenses', 'Rent', 'Utilities'],
            self::ElectronicsShop => ['Stock', 'Rent', 'Warranty', 'Utilities'],
            self::Cybercafe => ['Internet', 'Rent', 'Equipment', 'Utilities'],
            self::SmallRestaurant => ['Ingredients', 'Gas', 'Rent', 'Labour'],
            self::BeautyShop => ['Stock', 'Rent', 'Marketing', 'Packaging'],
        };
    }

    public function isFoodBusiness(): bool
    {
        return in_array($this, [self::FoodVendor, self::SmallRestaurant], true);
    }

    /**
     * Starter products for food businesses (name, selling_price, category name).
     *
     * @return list<array{name: string, selling_price: float, category: string}>
     */
    public function starterProducts(): array
    {
        if (! $this->isFoodBusiness()) {
            return [];
        }

        return [
            ['name' => 'Ndengu Samosa', 'selling_price' => 40.0, 'category' => 'Snacks'],
            ['name' => 'Meat Samosa', 'selling_price' => 50.0, 'category' => 'Snacks'],
        ];
    }

    /** @return list<array{id: string, label: string, description: string}> */
    public static function catalog(): array
    {
        return array_map(
            fn (self $type) => [
                'id' => $type->value,
                'label' => $type->label(),
                'description' => $type->description(),
            ],
            self::cases(),
        );
    }

    public static function tryFromString(?string $value): ?self
    {
        if ($value === null || $value === '') {
            return null;
        }

        return self::tryFrom($value);
    }

    /**
     * Global catalog categories this business type may browse and import.
     *
     * @return list<string>
     */
    public function allowedGlobalCatalogCategories(): array
    {
        return match ($this) {
            self::FoodVendor => [
                GlobalCatalogCategory::FoodAndSnacks->value,
                GlobalCatalogCategory::Beverages->value,
            ],
            self::SmallRestaurant => [
                GlobalCatalogCategory::FoodAndSnacks->value,
                GlobalCatalogCategory::Beverages->value,
                GlobalCatalogCategory::DairyProducts->value,
                GlobalCatalogCategory::Groceries->value,
                GlobalCatalogCategory::RestaurantSupplies->value,
            ],
            self::GroceryShop => [
                GlobalCatalogCategory::Groceries->value,
                GlobalCatalogCategory::Beverages->value,
                GlobalCatalogCategory::DairyProducts->value,
                GlobalCatalogCategory::FoodAndSnacks->value,
                GlobalCatalogCategory::HouseholdItems->value,
                GlobalCatalogCategory::Agriculture->value,
            ],
            self::Boutique => [
                GlobalCatalogCategory::Fashion->value,
            ],
            self::HardwareStore => [
                GlobalCatalogCategory::Hardware->value,
            ],
            self::Pharmacy => [
                GlobalCatalogCategory::HouseholdItems->value,
            ],
            self::ElectronicsShop => [
                GlobalCatalogCategory::ElectronicsAndAccessories->value,
            ],
            self::Cybercafe => [
                GlobalCatalogCategory::Services->value,
                GlobalCatalogCategory::Stationery->value,
                GlobalCatalogCategory::ElectronicsAndAccessories->value,
            ],
            self::BeautyShop => [
                GlobalCatalogCategory::BeautyAndCosmetics->value,
            ],
        };
    }
}
