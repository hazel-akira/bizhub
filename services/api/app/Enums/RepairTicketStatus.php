<?php

namespace App\Enums;

enum RepairTicketStatus: string
{
    case Pending = 'pending';
    case Fixed = 'fixed';
    case Collected = 'collected';

    public function label(): string
    {
        return match ($this) {
            self::Pending => 'Pending',
            self::Fixed => 'Fixed',
            self::Collected => 'Collected',
        };
    }
}
