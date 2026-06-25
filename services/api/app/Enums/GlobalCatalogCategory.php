<?php

namespace App\Enums;

/**
 * Platform-wide global catalog category names (Akira Bites SaaS catalog).
 */
enum GlobalCatalogCategory: string
{
    case FoodAndSnacks = 'Food & Snacks';
    case Beverages = 'Beverages';
    case DairyProducts = 'Dairy Products';
    case Groceries = 'Groceries';
    case HouseholdItems = 'Household Items';
    case Stationery = 'Stationery';
    case ElectronicsAndAccessories = 'Electronics & Accessories';
    case Fashion = 'Fashion';
    case BeautyAndCosmetics = 'Beauty & Cosmetics';
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
