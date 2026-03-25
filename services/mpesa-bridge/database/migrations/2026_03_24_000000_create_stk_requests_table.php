<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('stk_requests', function (Blueprint $table) {
            $table->id();
            $table->string('checkout_request_id')->nullable()->unique();
            $table->string('reference', 64);
            $table->decimal('amount', 12, 2);
            $table->string('phone', 20);
            $table->string('status', 32)->default('pending');
            $table->string('mpesa_receipt_number')->nullable();
            $table->json('meta')->nullable();
            $table->timestamps();

            $table->index(['checkout_request_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('stk_requests');
    }
};
