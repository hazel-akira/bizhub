<?php

use App\Http\Controllers\MpesaCallbackController;
use App\Http\Controllers\MpesaStatusController;
use App\Http\Controllers\MpesaStkController;
use App\Http\Controllers\OrderController;
use App\Http\Controllers\ProductController;
use App\Http\Controllers\Api\CustomerAuthController;
use Illuminate\Support\Facades\Route;

Route::get('/products', [ProductController::class, 'index']);
Route::post('/orders', [OrderController::class, 'store']);
Route::get('/orders/{id}', [OrderController::class, 'show']);

// Token auth (Sanctum) for standalone frontend deployments
Route::post('/auth/register', [CustomerAuthController::class, 'register']);
Route::post('/auth/login', [CustomerAuthController::class, 'login']);
Route::post('/auth/logout', [CustomerAuthController::class, 'logout']);
Route::get('/account/orders', [CustomerAuthController::class, 'myOrders']);

// STK Push endpoints (keep old route for compatibility)
Route::post('/mpesa/stk', MpesaStkController::class);
Route::post('/mpesa/stkpush', MpesaStkController::class);
Route::get('/mpesa/status/{checkoutRequestId}', MpesaStatusController::class);
Route::post('/mpesa/callback', MpesaCallbackController::class);
