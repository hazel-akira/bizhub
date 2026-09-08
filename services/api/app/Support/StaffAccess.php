<?php

namespace App\Support;

use Illuminate\Validation\ValidationException;

final class StaffAccess
{
    public const CASHIER = 'cashier';

    public const STOCK = 'stock';

    public const MANAGER = 'manager';

    public const OWNER = 'owner';

    public const ALL_ROLES = [
        self::CASHIER,
        self::STOCK,
        self::MANAGER,
        self::OWNER,
    ];

    public const PERMISSIONS = [
        'sell',
        'view_sales',
        'refund',
        'apply_discount',
        'edit_price',
        'manage_stock',
        'add_product',
        'view_profit',
        'view_reports',
        'manage_expenses',
        'manage_customers',
        'manage_staff',
        'manage_settings',
    ];

    /**
     * @param  list<mixed>  $roles
     * @return list<string>
     */
    public static function normalize(array $roles): array
    {
        $out = [];
        foreach ($roles as $role) {
            $value = strtolower(trim((string) $role));
            if ($value === 'admin') {
                $value = self::OWNER;
            }
            if (in_array($value, self::ALL_ROLES, true)) {
                $out[$value] = $value;
            }
        }

        return array_values($out);
    }

    /**
     * @param  list<mixed>  $roles
     */
    public static function assertCompatible(array $roles): void
    {
        $normalized = self::normalize($roles);
        if ($normalized === []) {
            throw ValidationException::withMessages([
                'roles' => ['Select at least one role.'],
            ]);
        }

        if (in_array(self::CASHIER, $normalized, true)
            && in_array(self::OWNER, $normalized, true)) {
            throw ValidationException::withMessages([
                'roles' => ['A cashier cannot also be an admin. Admin already has full access.'],
            ]);
        }
    }

    /**
     * @param  list<string>  $roles
     * @return list<string>
     */
    public static function permissionsFor(array $roles): array
    {
        $normalized = self::normalize($roles);
        if (in_array(self::OWNER, $normalized, true)) {
            return self::PERMISSIONS;
        }

        $permissions = [];
        foreach ($normalized as $role) {
            $permissions = array_merge($permissions, self::permissionsForRole($role));
        }

        return array_values(array_unique($permissions));
    }

    /**
     * @return list<string>
     */
    public static function permissionsForRole(string $role): array
    {
        return match (self::normalize([$role])[0] ?? '') {
            self::CASHIER => ['sell', 'view_sales'],
            self::STOCK => ['manage_stock', 'add_product'],
            self::MANAGER => [
                'sell',
                'view_sales',
                'refund',
                'apply_discount',
                'manage_stock',
                'add_product',
                'view_reports',
                'manage_customers',
            ],
            self::OWNER => self::PERMISSIONS,
            default => [],
        };
    }

    public static function primaryRole(array $roles): string
    {
        $normalized = self::normalize($roles);
        foreach ([self::OWNER, self::MANAGER, self::STOCK, self::CASHIER] as $role) {
            if (in_array($role, $normalized, true)) {
                return $role;
            }
        }

        return self::OWNER;
    }

    /**
     * @return list<array{id: string, label: string, summary: string}>
     */
    public static function catalog(): array
    {
        return [
            [
                'id' => self::CASHIER,
                'label' => 'Cashier / Teller',
                'summary' => 'Checkout, cash/M-Pesa, receipts. Cannot edit prices, refund, or see profit.',
            ],
            [
                'id' => self::STOCK,
                'label' => 'Stock / Inventory',
                'summary' => 'Add stock and products. Cannot take sales or see the books.',
            ],
            [
                'id' => self::MANAGER,
                'label' => 'Manager / Supervisor',
                'summary' => 'Refunds, discounts, stock, sales summaries. Cannot change base prices or net profit.',
            ],
            [
                'id' => self::OWNER,
                'label' => 'Owner / Admin',
                'summary' => 'Full access, including prices, profit, and staff roles.',
            ],
        ];
    }
}
