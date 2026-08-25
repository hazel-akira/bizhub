<?php

namespace App\Models;

use App\Enums\MpesaAccountType;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class MpesaConfig extends Model
{
    protected $fillable = [
        'business_id',
        'shortcode',
        'consumer_key',
        'consumer_secret',
        'passkey',
        'account_type',
    ];

    protected $hidden = [
        'consumer_key',
        'consumer_secret',
        'passkey',
    ];

    protected function casts(): array
    {
        return [
            'consumer_key' => 'encrypted',
            'consumer_secret' => 'encrypted',
            'passkey' => 'encrypted',
            'account_type' => MpesaAccountType::class,
        ];
    }

    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }

    public function isReady(): bool
    {
        return filled($this->shortcode)
            && filled($this->consumer_key)
            && filled($this->consumer_secret)
            && filled($this->passkey);
    }

    public function toPublicArray(): array
    {
        return [
            'configured' => $this->isReady(),
            'shortcode' => $this->shortcode,
            'account_type' => $this->account_type?->value ?? MpesaAccountType::Paybill->value,
            'account_type_label' => $this->account_type?->label(),
        ];
    }
}
