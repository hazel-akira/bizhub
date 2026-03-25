<?php

namespace App\Support;

final class PhoneNormalizer
{
    public static function toMpesaMsisdn(string $phone): string
    {
        $digits = preg_replace('/\D/', '', $phone) ?? '';
        if ($digits === '') {
            return '';
        }
        if (str_starts_with($digits, '0')) {
            return '254'.substr($digits, 1);
        }
        if (! str_starts_with($digits, '254')) {
            return '254'.$digits;
        }

        return $digits;
    }
}
