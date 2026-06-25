<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class SchemaOverviewService
{
    /** @var list<array{from: string, from_col: string, to: string, to_col: string}> */
    private const RELATIONSHIPS = [
        ['from' => 'users', 'from_col' => 'business_id', 'to' => 'businesses', 'to_col' => 'id'],
        ['from' => 'categories', 'from_col' => 'business_id', 'to' => 'businesses', 'to_col' => 'id'],
        ['from' => 'products', 'from_col' => 'business_id', 'to' => 'businesses', 'to_col' => 'id'],
        ['from' => 'products', 'from_col' => 'category_id', 'to' => 'categories', 'to_col' => 'id'],
        ['from' => 'products', 'from_col' => 'global_product_id', 'to' => 'global_products', 'to_col' => 'id'],
        ['from' => 'global_products', 'from_col' => 'global_category_id', 'to' => 'global_categories', 'to_col' => 'id'],
        ['from' => 'customers', 'from_col' => 'business_id', 'to' => 'businesses', 'to_col' => 'id'],
        ['from' => 'suppliers', 'from_col' => 'business_id', 'to' => 'businesses', 'to_col' => 'id'],
        ['from' => 'sales', 'from_col' => 'business_id', 'to' => 'businesses', 'to_col' => 'id'],
        ['from' => 'sales', 'from_col' => 'customer_id', 'to' => 'customers', 'to_col' => 'id'],
        ['from' => 'sales', 'from_col' => 'user_id', 'to' => 'users', 'to_col' => 'id'],
        ['from' => 'sale_items', 'from_col' => 'sale_id', 'to' => 'sales', 'to_col' => 'id'],
        ['from' => 'sale_items', 'from_col' => 'product_id', 'to' => 'products', 'to_col' => 'id'],
        ['from' => 'purchases', 'from_col' => 'business_id', 'to' => 'businesses', 'to_col' => 'id'],
        ['from' => 'purchases', 'from_col' => 'supplier_id', 'to' => 'suppliers', 'to_col' => 'id'],
        ['from' => 'purchase_items', 'from_col' => 'purchase_id', 'to' => 'purchases', 'to_col' => 'id'],
        ['from' => 'purchase_items', 'from_col' => 'product_id', 'to' => 'products', 'to_col' => 'id'],
        ['from' => 'expenses', 'from_col' => 'business_id', 'to' => 'businesses', 'to_col' => 'id'],
        ['from' => 'expenses', 'from_col' => 'category_id', 'to' => 'expense_categories', 'to_col' => 'id'],
        ['from' => 'expenses', 'from_col' => 'created_by', 'to' => 'users', 'to_col' => 'id'],
        ['from' => 'expense_categories', 'from_col' => 'business_id', 'to' => 'businesses', 'to_col' => 'id'],
        ['from' => 'inventory_transactions', 'from_col' => 'business_id', 'to' => 'businesses', 'to_col' => 'id'],
        ['from' => 'inventory_transactions', 'from_col' => 'product_id', 'to' => 'products', 'to_col' => 'id'],
        ['from' => 'inventory_transactions', 'from_col' => 'created_by', 'to' => 'users', 'to_col' => 'id'],
        ['from' => 'business_subscriptions', 'from_col' => 'business_id', 'to' => 'businesses', 'to_col' => 'id'],
        ['from' => 'business_subscriptions', 'from_col' => 'plan_id', 'to' => 'subscription_plans', 'to_col' => 'id'],
        ['from' => 'orders', 'from_col' => 'user_id', 'to' => 'users', 'to_col' => 'id'],
        ['from' => 'order_items', 'from_col' => 'order_id', 'to' => 'orders', 'to_col' => 'id'],
        ['from' => 'order_items', 'from_col' => 'product_id', 'to' => 'products', 'to_col' => 'id'],
        ['from' => 'mpesa_transactions', 'from_col' => 'order_id', 'to' => 'orders', 'to_col' => 'id'],
    ];

    /** @var list<string> */
    private const BUSINESS_TABLES = [
        'businesses',
        'subscription_plans',
        'business_subscriptions',
        'users',
        'categories',
        'global_categories',
        'global_products',
        'products',
        'customers',
        'suppliers',
        'sales',
        'sale_items',
        'purchases',
        'purchase_items',
        'expense_categories',
        'expenses',
        'inventory_transactions',
        'orders',
        'order_items',
        'mpesa_transactions',
    ];

    /** @var array<string, string> */
    private const TABLE_DESCRIPTIONS = [
        'businesses' => 'Top-level tenant. Every shop / samosa business lives here.',
        'subscription_plans' => 'Available SaaS plans (pricing tiers).',
        'business_subscriptions' => 'Links a business to its active plan.',
        'users' => 'Staff accounts scoped to a business (owner, cashier, etc.).',
        'categories' => 'Product groupings per business (e.g. Samosas, Drinks).',
        'global_categories' => 'Platform-wide product categories shared by all businesses.',
        'global_products' => 'Shared catalog items (Coca Cola, Rice, etc.) managed by the platform.',
        'products' => 'Business inventory — may link to global_products or be fully custom.',
        'customers' => 'People who buy from the business (in-store or online).',
        'suppliers' => 'Vendors you purchase stock from.',
        'sales' => 'A completed or pending in-store sale (invoice header).',
        'sale_items' => 'Line items inside a sale — links products to quantities sold.',
        'purchases' => 'Stock bought from a supplier.',
        'purchase_items' => 'Line items inside a purchase.',
        'expense_categories' => 'Buckets for expenses (rent, transport, gas…).',
        'expenses' => 'Money spent, recorded by a user under a category.',
        'inventory_transactions' => 'Stock in/out audit trail per product.',
        'orders' => 'Online customer orders (web client checkout).',
        'order_items' => 'Products in an online order.',
        'mpesa_transactions' => 'M-Pesa STK push records tied to online orders.',
    ];

    public function overview(): array
    {
        return [
            'database' => config('database.connections.pgsql.database', config('database.default')),
            'tables' => $this->tableStats(),
            'relationships' => self::RELATIONSHIPS,
            'flows' => $this->dataFlows(),
            'mermaid' => $this->mermaidDiagram(),
        ];
    }

    /** @return list<array{name: string, rows: int, description: string, links_to: list<string>, linked_from: list<string>}> */
    private function tableStats(): array
    {
        $stats = [];

        foreach (self::BUSINESS_TABLES as $table) {
            if (! Schema::hasTable($table)) {
                continue;
            }

            $linksTo = [];
            $linkedFrom = [];

            foreach (self::RELATIONSHIPS as $rel) {
                if ($rel['from'] === $table) {
                    $linksTo[] = "{$rel['from_col']} → {$rel['to']}";
                }
                if ($rel['to'] === $table) {
                    $linkedFrom[] = "{$rel['from']}.{$rel['from_col']}";
                }
            }

            $stats[] = [
                'name' => $table,
                'rows' => (int) DB::table($table)->count(),
                'description' => self::TABLE_DESCRIPTIONS[$table] ?? '',
                'links_to' => array_values(array_unique($linksTo)),
                'linked_from' => array_values(array_unique($linkedFrom)),
            ];
        }

        return $stats;
    }

    /** @return list<array{title: string, steps: list<string>}> */
    private function dataFlows(): array
    {
        return [
            [
                'title' => 'In-store sale (Flutter POS)',
                'steps' => [
                    'businesses — identifies which shop',
                    'users — cashier records the sale',
                    'customers — optional buyer',
                    'sales — invoice header (total, payment method)',
                    'sale_items — each samosa line links to products',
                    'inventory_transactions — stock reduced (optional)',
                ],
            ],
            [
                'title' => 'Online order (web client)',
                'steps' => [
                    'users — customer logs in',
                    'products — menu items added to cart',
                    'orders — checkout creates an order + phone number',
                    'order_items — snapshot of product, price, quantity',
                    'mpesa_transactions — STK push initiated',
                    'orders.payment_status — updated to paid on M-Pesa callback',
                ],
            ],
            [
                'title' => 'Stock purchase',
                'steps' => [
                    'suppliers — who you buy from',
                    'purchases — purchase header',
                    'purchase_items — products and quantities received',
                    'products.stock_quantity — increased',
                    'inventory_transactions — audit entry',
                ],
            ],
            [
                'title' => 'Expense tracking',
                'steps' => [
                    'expense_categories — e.g. Gas, Transport',
                    'users — who recorded it',
                    'expenses — amount linked to business + category',
                ],
            ],
        ];
    }

    private function mermaidDiagram(): string
    {
        return <<<'MERMAID'
erDiagram
    businesses ||--o{ users : has
    businesses ||--o{ categories : has
    businesses ||--o{ products : has
    businesses ||--o{ customers : has
    businesses ||--o{ suppliers : has
    businesses ||--o{ sales : has
    businesses ||--o{ purchases : has
    businesses ||--o{ expenses : has
    businesses ||--o{ business_subscriptions : has
    subscription_plans ||--o{ business_subscriptions : offers
    categories ||--o{ products : groups
    customers ||--o{ sales : places
    users ||--o{ sales : records
    users ||--o{ expenses : creates
    users ||--o{ orders : places
    sales ||--|{ sale_items : contains
    products ||--o{ sale_items : sold_in
    purchases ||--|{ purchase_items : contains
    products ||--o{ purchase_items : received_in
    suppliers ||--o{ purchases : supplies
    expense_categories ||--o{ expenses : categorizes
    products ||--o{ inventory_transactions : tracks
    orders ||--|{ order_items : contains
    products ||--o{ order_items : ordered_as
    orders ||--o| mpesa_transactions : paid_via
MERMAID;
    }
}
