<?php

namespace App\Enums;

enum BusinessType: string
{
    case MamaMboga = 'mama_mboga';
    case Butchery = 'butchery';
    case DairyShop = 'dairy_shop';
    case PoultryShop = 'poultry_shop';
    case GroceryShop = 'grocery_shop';
    case Wholesale = 'wholesale';
    case LiquorStore = 'liquor_store';
    case GasWater = 'gas_water';
    case Boutique = 'boutique';
    case BeautyShop = 'beauty_shop';
    case ShoeStore = 'shoe_store';
    case Salon = 'salon';
    case Cybercafe = 'cybercafe';
    case Agrovet = 'agrovet';
    case HardwareStore = 'hardware_store';
    case FoodVendor = 'food_vendor';
    case SmallRestaurant = 'small_restaurant';
    case Pharmacy = 'pharmacy';
    case ElectronicsShop = 'electronics_shop';

    public function label(): string
    {
        return match ($this) {
            self::MamaMboga => 'Fresh Foods (Mama Mboga)',
            self::Butchery => 'Butchery',
            self::DairyShop => 'Milk Bar / Dairy',
            self::PoultryShop => 'Poultry & Egg Supply',
            self::GroceryShop => 'General Retail Kiosk',
            self::Wholesale => 'Wholesale Store',
            self::LiquorStore => 'Wines & Spirits',
            self::GasWater => 'Gas & Water Refill',
            self::Boutique => 'Clothing Boutique',
            self::BeautyShop => 'Cosmetics Shop',
            self::ShoeStore => 'Shoe Store',
            self::Salon => 'Salon / Kinyozi',
            self::Cybercafe => 'Cyber Cafe',
            self::Agrovet => 'Agrovets',
            self::HardwareStore => 'Hardware Store',
            self::FoodVendor => 'Food Vendors',
            self::SmallRestaurant => 'Small Restaurant',
            self::Pharmacy => 'Pharmacies',
            self::ElectronicsShop => 'Electronic Shop',
        };
    }

    public function description(): string
    {
        return match ($this) {
            self::MamaMboga => 'Sukuma, tomatoes, onions, potatoes, bananas, and other fresh produce.',
            self::Butchery => 'Beef, goat, pork, chicken, matumbo, sausages, and other cuts.',
            self::DairyShop => 'Raw and packet milk, mala, yogurt, cheese, and local butter.',
            self::PoultryShop => 'Egg trays, kienyeji eggs, live birds, broilers, and chick mash.',
            self::GroceryShop => 'Unga, oil, soap, sugar, milk packets, tea, salt, and kiosk staples.',
            self::Wholesale => 'Bales, cartons, crates, and sacks for shops that buy in bulk.',
            self::LiquorStore => 'Beers, gin, vodka, wines, ciders, and mixers.',
            self::GasWater => '6kg/13kg gas refills, cylinders, regulators, and water jerry cans.',
            self::Boutique => 'T-shirts, dresses, trousers, jeans, kidswear, jackets, and belts.',
            self::BeautyShop => 'Braids, lotions, wigs, makeup, nail polish, perfume, and hair oil.',
            self::ShoeStore => 'School shoes, sneakers, leather shoes, sandals, heels, and polish.',
            self::Salon => 'Haircuts, braiding, washing, facials, shaving cream, and aftershave.',
            self::Cybercafe => 'Printing, photocopy, laminating, binding, scanning, and flash disks.',
            self::Agrovet => 'Fertilizer, maize seed, dewormers, acaricides, vaccines, and sprayers.',
            self::HardwareStore => 'Cement, nails, iron sheets, paint, brushes, PVC pipes, locks, and tools.',
            self::FoodVendor => 'Street food, snacks, and quick bites.',
            self::SmallRestaurant => 'Sit-down meals, drinks, and table service.',
            self::Pharmacy => 'Medicines, health products, and personal care.',
            self::ElectronicsShop => 'Phones, computers, and electronic accessories.',
        };
    }

    public function emoji(): string
    {
        return match ($this) {
            self::MamaMboga => '🥦',
            self::Butchery => '🥩',
            self::DairyShop => '🥛',
            self::PoultryShop => '🥚',
            self::GroceryShop => '🏪',
            self::Wholesale => '🛍️',
            self::LiquorStore => '🍷',
            self::GasWater => '⛽',
            self::Boutique => '👗',
            self::BeautyShop => '💄',
            self::ShoeStore => '👟',
            self::Salon => '💇',
            self::Cybercafe => '🖨️',
            self::Agrovet => '🌾',
            self::HardwareStore => '⚒️',
            self::FoodVendor => '🍽️',
            self::SmallRestaurant => '🍛',
            self::Pharmacy => '💊',
            self::ElectronicsShop => '📱',
        };
    }

    public function group(): string
    {
        return match ($this) {
            self::MamaMboga, self::Butchery, self::DairyShop, self::PoultryShop => 'Fresh Foods & Perishables',
            self::GroceryShop, self::Wholesale, self::LiquorStore, self::GasWater => 'Retail & FMCG',
            self::Boutique, self::BeautyShop, self::ShoeStore => 'Fashion & Lifestyle',
            self::Salon, self::Cybercafe, self::Agrovet, self::HardwareStore => 'Service & Artisan',
            self::FoodVendor, self::SmallRestaurant => 'Food Service',
            self::Pharmacy, self::ElectronicsShop => 'Other',
        };
    }

    /** @return list<string> */
    public function defaultProductCategories(): array
    {
        return match ($this) {
            self::MamaMboga => ['Greens', 'Vegetables', 'Fruits', 'Roots'],
            self::Butchery => ['Beef', 'Goat', 'Pork', 'Chicken', 'Offal', 'Processed'],
            self::DairyShop => ['Milk', 'Fermented', 'Yogurt', 'Cheese & Butter'],
            self::PoultryShop => ['Eggs', 'Live Birds', 'Dressed Chicken', 'Feeds'],
            self::GroceryShop => ['Dry Goods', 'Oil & Fat', 'Household', 'Dairy'],
            self::Wholesale => ['Bales', 'Cartons', 'Crates', 'Sacks'],
            self::LiquorStore => ['Beer', 'Spirits', 'Wine', 'Mixers'],
            self::GasWater => ['Gas', 'Cylinders & Parts', 'Water'],
            self::Boutique => ['Clothing', 'Kidswear', 'Accessories'],
            self::BeautyShop => ['Hair', 'Skin', 'Makeup', 'Fragrance'],
            self::ShoeStore => ['School', 'Casual', 'Official', 'Care'],
            self::Salon => ['Hair Services', 'Barber', 'Retail'],
            self::Cybercafe => ['Printing', 'Binding', 'Stationery', 'Accessories'],
            self::Agrovet => ['Fertilizer', 'Seeds', 'Livestock', 'Equipment'],
            self::HardwareStore => ['Building', 'Paint', 'Plumbing', 'Tools'],
            self::FoodVendor => ['Snacks', 'Beverages', 'Ready Meals'],
            self::SmallRestaurant => ['Appetizers', 'Main Course', 'Drinks', 'Desserts'],
            self::Pharmacy => ['Medicines', 'OTC', 'Personal Care', 'Supplements'],
            self::ElectronicsShop => ['Phones', 'Computers', 'Accessories', 'Appliances'],
        };
    }

    /** @return list<string> */
    public function defaultExpenseCategories(): array
    {
        return match ($this) {
            self::MamaMboga => ['Produce', 'Transport', 'Market fee', 'Packaging'],
            self::Butchery => ['Livestock', 'Ice', 'Transport', 'Rent', 'Labour'],
            self::DairyShop => ['Milk supply', 'Packaging', 'Rent', 'Utilities'],
            self::PoultryShop => ['Birds', 'Feeds', 'Transport', 'Rent'],
            self::GroceryShop => ['Stock', 'Transport', 'Rent', 'Utilities'],
            self::Wholesale => ['Stock', 'Transport', 'Warehouse', 'Labour'],
            self::LiquorStore => ['Stock', 'Licenses', 'Rent', 'Security'],
            self::GasWater => ['Gas stock', 'Water', 'Transport', 'Rent'],
            self::Boutique => ['Stock', 'Rent', 'Marketing', 'Packaging'],
            self::BeautyShop => ['Stock', 'Rent', 'Marketing', 'Packaging'],
            self::ShoeStore => ['Stock', 'Rent', 'Marketing', 'Packaging'],
            self::Salon => ['Products', 'Rent', 'Utilities', 'Labour'],
            self::Cybercafe => ['Paper', 'Ink', 'Internet', 'Rent', 'Equipment'],
            self::Agrovet => ['Stock', 'Licenses', 'Rent', 'Transport'],
            self::HardwareStore => ['Stock', 'Rent', 'Transport', 'Utilities'],
            self::FoodVendor => ['Ingredients', 'Transport', 'Gas', 'Labour'],
            self::SmallRestaurant => ['Ingredients', 'Gas', 'Rent', 'Labour'],
            self::Pharmacy => ['Stock', 'Licenses', 'Rent', 'Utilities'],
            self::ElectronicsShop => ['Stock', 'Rent', 'Warranty', 'Utilities'],
        };
    }

    public function isFoodBusiness(): bool
    {
        return in_array($this, [self::FoodVendor, self::SmallRestaurant], true);
    }

    /**
     * Optional starter products. Prices stay 0 so the owner sets them in Inventory.
     *
     * @return list<array{name: string, selling_price: float, category: string}>
     */
    public function starterProducts(): array
    {
        $item = static fn (string $name, string $category): array => [
            'name' => $name,
            'selling_price' => 0.0,
            'category' => $category,
        ];

        return match ($this) {
            self::MamaMboga => [
                $item('Sukuma wiki', 'Greens'),
                $item('Spinach', 'Greens'),
                $item('Tomatoes', 'Vegetables'),
                $item('Onions', 'Vegetables'),
                $item('Hoho (capsicum)', 'Vegetables'),
                $item('Dhania', 'Vegetables'),
                $item('Potatoes', 'Roots'),
                $item('Avocados', 'Fruits'),
                $item('Bananas', 'Fruits'),
            ],
            self::Butchery => [
                $item('Beef with bone', 'Beef'),
                $item('Beef without bone', 'Beef'),
                $item('Goat meat (mbuzi)', 'Goat'),
                $item('Pork chops', 'Pork'),
                $item('Minced meat', 'Beef'),
                $item('Matumbo', 'Offal'),
                $item('Chicken (full)', 'Chicken'),
                $item('Chicken pieces', 'Chicken'),
                $item('Sausages / smokies', 'Processed'),
            ],
            self::DairyShop => [
                $item('Raw milk 500ml', 'Milk'),
                $item('Raw milk 1L', 'Milk'),
                $item('Pasteurized milk packet', 'Milk'),
                $item('Mala', 'Fermented'),
                $item('Yogurt cup', 'Yogurt'),
                $item('Cheese block', 'Cheese & Butter'),
                $item('Local butter', 'Cheese & Butter'),
            ],
            self::PoultryShop => [
                $item('Eggs tray (large)', 'Eggs'),
                $item('Eggs tray (medium)', 'Eggs'),
                $item('Kienyeji eggs tray', 'Eggs'),
                $item('Live chicken', 'Live Birds'),
                $item('Broiler (dressed)', 'Dressed Chicken'),
                $item('Chick mash', 'Feeds'),
            ],
            default => [],
        };
    }

    /** @return list<array{id: string, label: string, description: string, group: string, emoji: string}> */
    public static function catalog(): array
    {
        return array_map(
            fn (self $type) => [
                'id' => $type->value,
                'label' => $type->label(),
                'description' => $type->description(),
                'group' => $type->group(),
                'emoji' => $type->emoji(),
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
            self::MamaMboga => [
                GlobalCatalogCategory::FreshProduce->value,
                GlobalCatalogCategory::Groceries->value,
            ],
            self::Butchery => [
                GlobalCatalogCategory::MeatAndPoultry->value,
                GlobalCatalogCategory::FoodAndSnacks->value,
                GlobalCatalogCategory::RestaurantSupplies->value,
            ],
            self::DairyShop => [
                GlobalCatalogCategory::DairyProducts->value,
            ],
            self::PoultryShop => [
                GlobalCatalogCategory::PoultryAndEggs->value,
                GlobalCatalogCategory::MeatAndPoultry->value,
                GlobalCatalogCategory::Agriculture->value,
            ],
            self::GroceryShop => [
                GlobalCatalogCategory::Groceries->value,
                GlobalCatalogCategory::Beverages->value,
                GlobalCatalogCategory::DairyProducts->value,
                GlobalCatalogCategory::FoodAndSnacks->value,
                GlobalCatalogCategory::HouseholdItems->value,
                GlobalCatalogCategory::FreshProduce->value,
            ],
            self::Wholesale => [
                GlobalCatalogCategory::WholesalePacks->value,
                GlobalCatalogCategory::Groceries->value,
                GlobalCatalogCategory::Beverages->value,
                GlobalCatalogCategory::HouseholdItems->value,
            ],
            self::LiquorStore => [
                GlobalCatalogCategory::WinesAndSpirits->value,
                GlobalCatalogCategory::Beverages->value,
            ],
            self::GasWater => [
                GlobalCatalogCategory::GasAndWater->value,
            ],
            self::Boutique => [
                GlobalCatalogCategory::Fashion->value,
            ],
            self::BeautyShop => [
                GlobalCatalogCategory::BeautyAndCosmetics->value,
            ],
            self::ShoeStore => [
                GlobalCatalogCategory::Footwear->value,
                GlobalCatalogCategory::Fashion->value,
            ],
            self::Salon => [
                GlobalCatalogCategory::SalonAndBarber->value,
                GlobalCatalogCategory::BeautyAndCosmetics->value,
            ],
            self::Cybercafe => [
                GlobalCatalogCategory::Services->value,
                GlobalCatalogCategory::Stationery->value,
                GlobalCatalogCategory::ElectronicsAndAccessories->value,
            ],
            self::Agrovet => [
                GlobalCatalogCategory::Agriculture->value,
            ],
            self::HardwareStore => [
                GlobalCatalogCategory::Hardware->value,
            ],
            self::FoodVendor => [
                GlobalCatalogCategory::FoodAndSnacks->value,
                GlobalCatalogCategory::Beverages->value,
                GlobalCatalogCategory::DairyProducts->value,
                GlobalCatalogCategory::RestaurantSupplies->value,
            ],
            self::SmallRestaurant => [
                GlobalCatalogCategory::FoodAndSnacks->value,
                GlobalCatalogCategory::Beverages->value,
                GlobalCatalogCategory::DairyProducts->value,
                GlobalCatalogCategory::Groceries->value,
                GlobalCatalogCategory::RestaurantSupplies->value,
                GlobalCatalogCategory::MeatAndPoultry->value,
            ],
            self::Pharmacy => [
                GlobalCatalogCategory::HouseholdItems->value,
            ],
            self::ElectronicsShop => [
                GlobalCatalogCategory::ElectronicsAndAccessories->value,
            ],
        };
    }
}
