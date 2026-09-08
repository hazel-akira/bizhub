<?php

namespace App\Enums;

/**
 * Platform-wide global catalog category names (Akira Flow SaaS catalog).
 */
enum GlobalCatalogCategory: string
{
    case FreshProduce = 'Fresh Produce';
    case FoodAndSnacks = 'Food & Snacks';
    case Beverages = 'Beverages';
    case DairyProducts = 'Dairy Products';
    case PoultryAndEggs = 'Poultry & Eggs';
    case MeatAndPoultry = 'Meat & Poultry';
    case Groceries = 'Groceries';
    case WholesalePacks = 'Wholesale Packs';
    case HouseholdItems = 'Household Items';
    case WinesAndSpirits = 'Wines & Spirits';
    case GasAndWater = 'Gas & Water';
    case Fashion = 'Fashion';
    case Footwear = 'Footwear';
    case BeautyAndCosmetics = 'Beauty & Cosmetics';
    case SalonAndBarber = 'Salon & Barber';
    case Stationery = 'Stationery';
    case ElectronicsAndAccessories = 'Electronics & Accessories';
    case Agriculture = 'Agriculture';
    case Hardware = 'Hardware';
    case RestaurantSupplies = 'Restaurant Supplies';
    case Services = 'Services';

    /** @return list<string> */
    public static function names(): array
    {
        return array_map(fn (self $c) => $c->value, self::cases());
    }
}
