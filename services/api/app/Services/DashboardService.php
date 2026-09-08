<?php

namespace App\Services;

use App\Models\Expense;
use App\Models\Product;
use App\Models\Sale;
use App\Models\SaleItem;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class DashboardService
{
    public function summary(int $businessId): array
    {
        $today = Carbon::today();

        $todaySalesQuery = Sale::forBusiness($businessId)->whereDate('sale_date', $today);

        $todaySales = (float) (clone $todaySalesQuery)->sum('total_amount');

        $todayExpenses = (float) Expense::forBusiness($businessId)
            ->whereDate('expense_date', $today)
            ->sum('amount');

        $todaySaleIds = (clone $todaySalesQuery)->pluck('id');

        $todayUnitsSold = (int) SaleItem::query()
            ->whereIn('sale_id', $todaySaleIds)
            ->sum('quantity');

        $cogs = $this->costOfGoodsSold($todaySaleIds);
        $grossProfit = $todaySales - $cogs;
        $operatingProfit = $grossProfit - $todayExpenses;
        $netProfit = $todaySales - $cogs - $todayExpenses;

        $topProductToday = SaleItem::query()
            ->whereIn('sale_id', $todaySaleIds)
            ->select('product_id', DB::raw('SUM(quantity) as total_qty'))
            ->groupBy('product_id')
            ->orderByDesc('total_qty')
            ->with('product')
            ->first();

        $lowStockCount = Product::forBusiness($businessId)
            ->where('is_active', true)
            ->where('stock_quantity', '<=', 5)
            ->count();

        $pendingCredit = app(SaleService::class)->unpaidTotalForBusiness($businessId);

        return [
            'today_sales' => round($todaySales, 2),
            'today_expenses' => round($todayExpenses, 2),
            'today_cogs' => round($cogs, 2),
            'today_gross_profit' => round($grossProfit, 2),
            'today_operating_profit' => round($operatingProfit, 2),
            'today_net_profit' => round($netProfit, 2),
            'today_profit' => round($netProfit, 2),
            'today_gross_margin' => $this->margin($grossProfit, $todaySales),
            'today_net_margin' => $this->margin($netProfit, $todaySales),
            'products_count' => Product::forBusiness($businessId)->count(),
            'sales_count' => Sale::forBusiness($businessId)->count(),
            'today_units_sold' => $todayUnitsSold,
            'top_product_today' => $topProductToday?->product?->name,
            'low_stock_count' => $lowStockCount,
            'pending_credit' => $pendingCredit,
        ];
    }

    /** @param \Illuminate\Support\Collection<int, int>|list<int> $saleIds */
    private function costOfGoodsSold($saleIds): float
    {
        if (collect($saleIds)->isEmpty()) {
            return 0;
        }

        $hasUnitCost = Schema::hasColumn('sale_items', 'unit_cost');

        $query = SaleItem::query()
            ->whereIn('sale_items.sale_id', $saleIds)
            ->leftJoin('products', 'products.id', '=', 'sale_items.product_id');

        if ($hasUnitCost) {
            return (float) $query->selectRaw(
                'COALESCE(SUM(sale_items.quantity * COALESCE(sale_items.unit_cost, products.cost_price, 0)), 0) as cogs'
            )->value('cogs');
        }

        return (float) $query->selectRaw(
            'COALESCE(SUM(sale_items.quantity * COALESCE(products.cost_price, 0)), 0) as cogs'
        )->value('cogs');
    }

    private function margin(float $profit, float $revenue): float
    {
        if ($revenue <= 0) {
            return 0;
        }

        return round(($profit / $revenue) * 100, 1);
    }
}
