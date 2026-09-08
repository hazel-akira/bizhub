<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('users') && ! Schema::hasColumn('users', 'roles')) {
            Schema::table('users', function (Blueprint $table) {
                $table->json('roles')->nullable();
            });
        }

        if (! Schema::hasColumn('users', 'roles')) {
            return;
        }

        $users = DB::table('users')->select('id', 'role', 'roles')->get();
        foreach ($users as $user) {
            if ($user->roles) {
                continue;
            }
            $role = strtolower((string) ($user->role ?: 'owner'));
            if ($role === 'admin') {
                $role = 'owner';
            }
            if (! in_array($role, ['cashier', 'stock', 'manager', 'owner'], true)) {
                $role = 'owner';
            }
            DB::table('users')->where('id', $user->id)->update([
                'roles' => json_encode([$role]),
            ]);
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('users') && Schema::hasColumn('users', 'roles')) {
            Schema::table('users', function (Blueprint $table) {
                $table->dropColumn('roles');
            });
        }
    }
};
