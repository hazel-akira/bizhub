<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('repair_tickets')) {
            return;
        }

        Schema::create('repair_tickets', function (Blueprint $table) {
            $table->id();
            $table->foreignId('business_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->string('ticket_number');
            $table->string('customer_name');
            $table->string('customer_phone')->nullable();
            $table->string('phone_model');
            $table->text('issue_description');
            $table->text('spare_parts_used')->nullable();
            $table->decimal('labor_cost', 12, 2)->default(0);
            $table->string('status')->default('pending');
            $table->timestamps();

            $table->unique(['business_id', 'ticket_number']);
            $table->index(['business_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('repair_tickets');
    }
};
