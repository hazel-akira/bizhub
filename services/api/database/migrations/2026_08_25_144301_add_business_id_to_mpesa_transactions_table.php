<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('mpesa_transactions', function (Blueprint $table) {
            $table->foreignId('business_id')->nullable()->after('id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->nullable()->after('business_id')->constrained()->nullOnDelete();
            $table->foreignId('sale_id')->nullable()->after('order_id')->constrained()->nullOnDelete();
            $table->json('metadata')->nullable();

            $table->index(['business_id', 'status']);
        });

        DB::table('mpesa_transactions')->where('status', 'paid')->update(['status' => 'COMPLETED']);
        DB::table('mpesa_transactions')->whereIn('status', ['pending', 'processing'])->update(['status' => 'PENDING']);
        DB::table('mpesa_transactions')->where('status', 'failed')->update(['status' => 'FAILED']);
    }

    public function down(): void
    {
        DB::table('mpesa_transactions')->where('status', 'COMPLETED')->update(['status' => 'paid']);
        DB::table('mpesa_transactions')->where('status', 'PENDING')->update(['status' => 'pending']);
        DB::table('mpesa_transactions')->where('status', 'FAILED')->update(['status' => 'failed']);

        Schema::table('mpesa_transactions', function (Blueprint $table) {
            $table->dropIndex(['business_id', 'status']);
            $table->dropConstrainedForeignId('sale_id');
            $table->dropConstrainedForeignId('user_id');
            $table->dropConstrainedForeignId('business_id');
            $table->dropColumn('metadata');
        });
    }
};
