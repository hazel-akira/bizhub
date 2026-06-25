<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('global_products', function (Blueprint $table) {
            $table->id();
            $table->foreignId('global_category_id')
                ->constrained('global_categories')
                ->cascadeOnDelete();
            $table->string('name');
            $table->text('description')->nullable();
            $table->string('barcode')->nullable()->unique();
            $table->string('unit', 50)->default('pcs');
            $table->timestamps();

            $table->unique(['global_category_id', 'name']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('global_products');
    }
};
