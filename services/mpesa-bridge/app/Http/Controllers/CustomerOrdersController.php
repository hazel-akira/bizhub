<?php

namespace App\Http\Controllers;

use App\Models\Order;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\View\View;

class CustomerOrdersController extends Controller
{
    public function index(Request $request): View
    {
        $orders = Order::query()
            ->where('user_id', Auth::id())
            ->orderByDesc('created_at')
            ->limit(50)
            ->get();

        return view('account.orders', [
            'orders' => $orders,
        ]);
    }
}

