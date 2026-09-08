<?php

namespace App\Models;

use App\Support\StaffAccess;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'business_id',
        'name',
        'email',
        'google_id',
        'password',
        'role',
        'roles',
        'is_active',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected function casts(): array
    {
        return [
            'password' => 'hashed',
            'is_active' => 'boolean',
            'roles' => 'array',
        ];
    }

    /** @return list<string> */
    public function staffRoles(): array
    {
        $roles = is_array($this->roles) ? $this->roles : [];
        if ($roles === []) {
            $roles = [$this->role ?: StaffAccess::OWNER];
        }

        return StaffAccess::normalize($roles);
    }

    public function isOwner(): bool
    {
        return in_array(StaffAccess::OWNER, $this->staffRoles(), true);
    }

    public function hasPermission(string $permission): bool
    {
        return in_array($permission, StaffAccess::permissionsFor($this->staffRoles()), true);
    }

    /** @param  list<mixed>  $roles */
    public function syncStaffRoles(array $roles): void
    {
        StaffAccess::assertCompatible($roles);
        $normalized = StaffAccess::normalize($roles);
        $this->roles = $normalized;
        $this->role = StaffAccess::primaryRole($normalized);
    }

    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }

    public function orders(): HasMany
    {
        return $this->hasMany(Order::class);
    }

    public function sales(): HasMany
    {
        return $this->hasMany(Sale::class);
    }

    public function mpesaTransactions(): HasMany
    {
        return $this->hasMany(MpesaTransaction::class);
    }
}
