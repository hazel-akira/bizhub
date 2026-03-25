<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('stk_requests')) {
            return;
        }
        Schema::create('stk_requests', function (Blueprint $table) {
            $table->id();
            $table->string('checkout_request_id')->unique();
            $table->string('reference'); // order_{id}
            $table->string('status')->default('pending'); // pending, completed, failed
            $table->string('mpesa_receipt_number')->nullable();
            $table->unsignedBigInteger('order_id')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('stk_requests');
    }
};
