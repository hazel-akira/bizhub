<?php

namespace App\Enums;

enum ProductDepartment: string
{
    case BabyShop = 'baby_shop';
    case Bakery = 'bakery';
    case PhoneRepair = 'phone_repair';

    public function label(): string
    {
        return match ($this) {
            self::BabyShop => 'Baby Shop',
            self::Bakery => 'Bakery',
            self::PhoneRepair => 'Phone Repair',
        };
    }

    public static function fromBusinessType(?string $type): ?self
    {
        return self::tryFrom((string) $type);
    }
}
