<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('orders', function (Blueprint $table) {
            $table->id();
            $table->json('items'); // [{product_id, name, price, quantity}]
            $table->unsignedInteger('total_amount');
            $table->string('phone_number');
            $table->string('payment_status')->default('pending'); // pending, paid, failed
            $table->string('mpesa_receipt')->nullable();
            $table->string('checkout_request_id')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('orders');
    }
};
