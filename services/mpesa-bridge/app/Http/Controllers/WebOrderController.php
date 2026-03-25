<?php

namespace App\Http\Controllers;

use Illuminate\View\View;

/**
 * Serves the customer web ordering UI (Blade views).
 */
class WebOrderController extends Controller
{
    public function splash(): View
    {
        return view('order.splash');
    }

    public function menu(): View
    {
        return view('order.menu');
    }

    public function cart(): View
    {
        return view('order.cart');
    }

    public function checkout(): View
    {
        return view('order.checkout');
    }

    public function orderStatus(int $id): View
    {
        return view('order.status', ['orderId' => $id]);
    }
}
