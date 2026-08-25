<?php

namespace App\Enums;

enum MpesaAccountType: string
{
    case Paybill = 'paybill';
    case Till = 'till';

    public function transactionType(): string
    {
        return match ($this) {
            self::Paybill => 'CustomerPayBillOnline',
            self::Till => 'CustomerBuyGoodsOnline',
        };
    }

    public function label(): string
    {
        return match ($this) {
            self::Paybill => 'Paybill',
            self::Till => 'Till number',
        };
    }
}
