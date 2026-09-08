<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Concerns\RespondsWithJson;
use App\Http\Controllers\Controller;
use App\Services\DashboardService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    use RespondsWithJson;

    public function __construct(private readonly DashboardService $dashboard) {}

    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $summary = $this->dashboard->summary($user->business_id);

        if (! $user->hasPermission('view_profit')) {
            unset(
                $summary['today_cogs'],
                $summary['today_gross_profit'],
                $summary['today_operating_profit'],
                $summary['today_net_profit'],
                $summary['today_profit'],
                $summary['today_gross_margin'],
                $summary['today_net_margin'],
            );
        }

        if (! $user->hasPermission('manage_expenses') && ! $user->hasPermission('view_profit')) {
            unset($summary['today_expenses']);
        }

        if (! $user->hasPermission('view_sales') && ! $user->hasPermission('view_reports')) {
            unset(
                $summary['today_sales'],
                $summary['sales_count'],
                $summary['today_units_sold'],
                $summary['top_product_today'],
                $summary['pending_credit'],
            );
        }

        return $this->success($summary);
    }
}
