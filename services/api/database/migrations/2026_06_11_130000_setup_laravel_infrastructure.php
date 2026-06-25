<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // personal_access_tokens is created by 2026_06_11_123133_create_personal_access_tokens_table.
        // users.remember_token is included in 2026_06_11_120000_create_core_business_schema.
    }

    public function down(): void
    {
        //
    }
};
