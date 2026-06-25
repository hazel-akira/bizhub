<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Mirrors the Flutter Drift schema for future mobile sync.
     */
    public function up(): void
    {
        Schema::create('customers', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('phone')->default('');
            $table->timestamp('created_at')->useCurrent();
        });

        Schema::create('business_orders', function (Blueprint $table) {
            $table->id();
            $table->foreignId('customer_id')->constrained('customers')->cascadeOnDelete();
            $table->unsignedInteger('ndengu_count')->default(0);
            $table->unsignedInteger('meat_count')->default(0);
            $table->timestamp('order_date');
            $table->string('status')->default('pending');
            $table->timestamps();
        });

        Schema::create('sales', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->nullable()->constrained('business_orders')->nullOnDelete();
            $table->timestamp('created_at')->useCurrent();
            $table->unsignedInteger('ndengu_count')->default(0);
            $table->unsignedInteger('meat_count')->default(0);
            $table->decimal('total_amount', 10, 2)->default(0);
            $table->string('customer_name')->default('');
            $table->boolean('is_paid')->default(false);
        });

        Schema::create('expenses', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->decimal('amount', 10, 2);
            $table->string('category')->default('daily');
            $table->timestamp('created_at')->useCurrent();
        });

        Schema::create('unpaid_records', function (Blueprint $table) {
            $table->id();
            $table->string('customer_name');
            $table->decimal('amount', 10, 2);
            $table->timestamp('date');
            $table->text('notes')->default('');
            $table->boolean('is_paid')->default(false);
        });

        Schema::create('payments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('sale_id')->constrained('sales')->cascadeOnDelete();
            $table->decimal('amount', 10, 2);
            $table->string('method');
            $table->timestamp('created_at')->useCurrent();
        });

        Schema::create('production_batches', function (Blueprint $table) {
            $table->id();
            $table->timestamp('date');
            $table->unsignedInteger('ndengu_prepared')->default(0);
            $table->unsignedInteger('meat_prepared')->default(0);
            $table->timestamp('created_at')->useCurrent();
        });

        Schema::create('profit_records', function (Blueprint $table) {
            $table->id();
            $table->timestamp('date');
            $table->unsignedInteger('samosas_prepared')->default(0);
            $table->decimal('price_per_samosa', 10, 2)->default(40);
            $table->decimal('meat_cost', 10, 2)->default(0);
            $table->decimal('dhania_cost', 10, 2)->default(0);
            $table->decimal('flour_weekly_cost', 10, 2)->default(0);
            $table->decimal('onions_weekly_cost', 10, 2)->default(0);
            $table->decimal('oil_monthly_cost', 10, 2)->default(0);
            $table->decimal('gas_cost', 10, 2)->default(0);
            $table->decimal('transport_cost', 10, 2)->default(0);
            $table->decimal('labour_cost', 10, 2)->default(0);
            $table->decimal('revenue', 10, 2)->default(0);
            $table->decimal('total_costs', 10, 2)->default(0);
            $table->decimal('profit', 10, 2)->default(0);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('profit_records');
        Schema::dropIfExists('production_batches');
        Schema::dropIfExists('payments');
        Schema::dropIfExists('unpaid_records');
        Schema::dropIfExists('expenses');
        Schema::dropIfExists('sales');
        Schema::dropIfExists('business_orders');
        Schema::dropIfExists('customers');
    }
};
