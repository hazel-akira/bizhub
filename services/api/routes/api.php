<?php

use App\Http\Controllers\Api\AccountController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\BusinessController;
use App\Http\Controllers\Api\BusinessTypeController;
use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\CustomerController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\ExpenseController;
use App\Http\Controllers\Api\GlobalCategoryController;
use App\Http\Controllers\Api\GlobalProductController;
use App\Http\Controllers\Api\MpesaController;
use App\Http\Controllers\Api\OrderController;
use App\Http\Controllers\Api\ProductController;
use App\Http\Controllers\Api\SaleController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Akira Bites — Business Platform API
|--------------------------------------------------------------------------
| Flutter app → Laravel API → PostgreSQL (AkiraSaaS)
| Every business route is scoped to auth()->user()->business_id
*/

Route::get('/health', fn () => response()->json([
    'ok' => true,
    'service' => 'Akira Bites API',
    'database' => config('database.connections.pgsql.database'),
]));

// ── Platform (public) ─────────────────────────────────────────────────────
Route::get('/business-types', [BusinessTypeController::class, 'index']);

// ── Auth (public) ──────────────────────────────────────────────────────────
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

Route::prefix('auth')->group(function () {
    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/login', [AuthController::class, 'login']);
    Route::post('/google', [AuthController::class, 'google']);
    Route::middleware('auth:sanctum')->group(function () {
        Route::get('/me', [AuthController::class, 'profile']);
        Route::post('/logout', [AuthController::class, 'logout']);
    });
});

// ── Web shop (public menu — no business auth) ──────────────────────────────
Route::get('/shop/products', [ProductController::class, 'publicMenu']);

// ── Authenticated ──────────────────────────────────────────────────────────
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/profile', [AuthController::class, 'profile']);

    // Business platform (multi-tenant)
    Route::middleware('business')->group(function () {
        Route::get('/dashboard', [DashboardController::class, 'index']);

        Route::get('/business', [BusinessController::class, 'show']);
        Route::put('/business', [BusinessController::class, 'update']);

        Route::get('/global-categories', [GlobalCategoryController::class, 'index']);
        Route::get('/global-products', [GlobalProductController::class, 'index']);
        Route::get('/global-products/search', [GlobalProductController::class, 'search']);

        Route::get('/categories', [CategoryController::class, 'index']);
        Route::post('/categories', [CategoryController::class, 'store']);
        Route::put('/categories/{category}', [CategoryController::class, 'update']);
        Route::delete('/categories/{category}', [CategoryController::class, 'destroy']);

        Route::get('/products', [ProductController::class, 'index']);
        Route::get('/products/{product}', [ProductController::class, 'show']);
        Route::post('/products/from-global', [ProductController::class, 'storeFromGlobal']);
        Route::post('/products/custom', [ProductController::class, 'storeCustom']);
        Route::post('/products/{product}/image', [ProductController::class, 'uploadImage']);
        Route::post('/products', [ProductController::class, 'store']);
        Route::put('/products/{product}', [ProductController::class, 'update']);
        Route::delete('/products/{product}', [ProductController::class, 'destroy']);

        Route::get('/sales', [SaleController::class, 'index']);
        Route::get('/sales/{id}', [SaleController::class, 'show']);
        Route::post('/sales', [SaleController::class, 'store']);

        Route::get('/expenses', [ExpenseController::class, 'index']);
        Route::post('/expenses', [ExpenseController::class, 'store']);
        Route::put('/expenses/{expense}', [ExpenseController::class, 'update']);
        Route::delete('/expenses/{expense}', [ExpenseController::class, 'destroy']);

        Route::get('/customers', [CustomerController::class, 'index']);
        Route::post('/customers', [CustomerController::class, 'store']);
        Route::put('/customers/{customer}', [CustomerController::class, 'update']);
        Route::delete('/customers/{customer}', [CustomerController::class, 'destroy']);
    });

    // Online orders (web client checkout)
    Route::post('/orders', [OrderController::class, 'store']);
    Route::get('/orders/{order}', [OrderController::class, 'show']);
    Route::get('/account/orders', [AccountController::class, 'orders']);
    Route::post('/mpesa/stkpush', [MpesaController::class, 'stkPush']);
});

Route::prefix('mpesa')->group(function () {
    Route::post('/stk', [MpesaController::class, 'stk']);
    Route::get('/status/{checkoutRequestId}', [MpesaController::class, 'status']);
    Route::post('/callback', [MpesaController::class, 'callback']);
});
