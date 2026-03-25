<?php

use App\Http\Controllers\AdminOrderController;
use App\Http\Controllers\CustomerAuthController;
use App\Http\Controllers\CustomerOrdersController;
use App\Http\Controllers\WebOrderController;
use Illuminate\Support\Facades\Route;

// AkiraBites customer web ordering
Route::get('/', [WebOrderController::class, 'splash'])->name('order.splash');
Route::get('/menu', [WebOrderController::class, 'menu'])->name('order.menu');
Route::get('/cart', [WebOrderController::class, 'cart'])->name('order.cart');
Route::get('/checkout', [WebOrderController::class, 'checkout'])->name('order.checkout');
Route::get('/order/{id}/status', [WebOrderController::class, 'orderStatus'])->name('order.status');

// Admin: view orders
Route::get('/admin/orders', [AdminOrderController::class, 'index'])->name('admin.orders');
Route::get('/api/admin/orders', [AdminOrderController::class, 'list']);

// Customer authentication (simple, no extra scaffolding)
Route::middleware('guest')->group(function () {
    Route::get('/login', [CustomerAuthController::class, 'showLogin'])->name('login');
    Route::post('/login', [CustomerAuthController::class, 'login']);

    Route::get('/register', [CustomerAuthController::class, 'showRegister'])->name('register');
    Route::post('/register', [CustomerAuthController::class, 'register']);
});

Route::post('/logout', [CustomerAuthController::class, 'logout'])->middleware('auth')->name('logout');

// Customer orders history
Route::get('/account/orders', [CustomerOrdersController::class, 'index'])
    ->middleware('auth')
    ->name('account.orders');

Route::get('/welcome', function () {
    return view('welcome');
});
