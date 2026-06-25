<?php

namespace App\Services;

use App\Models\Expense;
use App\Models\Product;
use App\Models\Sale;
use App\Models\SaleItem;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

class DashboardService
{
    public function summary(int $businessId): array
    {
        $today = Carbon::today();

        $todaySales = (float) Sale::forBusiness($businessId)
            ->whereDate('sale_date', $today)
            ->sum('total_amount');

        $todayExpenses = (float) Expense::forBusiness($businessId)
            ->whereDate('expense_date', $today)
            ->sum('amount');

        $todaySaleIds = Sale::forBusiness($businessId)
            ->whereDate('sale_date', $today)
            ->pluck('id');

        $todayUnitsSold = (int) SaleItem::query()
            ->whereIn('sale_id', $todaySaleIds)
            ->sum('quantity');

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

        return [
            'today_sales' => $todaySales,
            'today_expenses' => $todayExpenses,
            'today_profit' => $todaySales - $todayExpenses,
            'products_count' => Product::forBusiness($businessId)->count(),
            'sales_count' => Sale::forBusiness($businessId)->count(),
            'today_units_sold' => $todayUnitsSold,
            'top_product_today' => $topProductToday?->product?->name,
            'low_stock_count' => $lowStockCount,
        ];
    }
}
