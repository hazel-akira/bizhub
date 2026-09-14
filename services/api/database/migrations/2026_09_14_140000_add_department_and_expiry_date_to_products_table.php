<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('products')) {
            return;
        }

        Schema::table('products', function (Blueprint $table) {
            if (! Schema::hasColumn('products', 'department')) {
                $table->string('department')->nullable();
                $table->index(['business_id', 'department']);
            }
            if (! Schema::hasColumn('products', 'expiry_date')) {
                $table->date('expiry_date')->nullable();
            }
        });
    }

    public function down(): void
    {
        if (! Schema::hasTable('products')) {
            return;
        }

        Schema::table('products', function (Blueprint $table) {
            if (Schema::hasColumn('products', 'department')) {
                $table->dropIndex(['business_id', 'department']);
                $table->dropColumn('department');
            }
            if (Schema::hasColumn('products', 'expiry_date')) {
                $table->dropColumn('expiry_date');
            }
        });
    }
};
