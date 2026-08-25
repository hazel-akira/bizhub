<?php

use App\Models\User;
use Illuminate\Support\Facades\Broadcast;

Broadcast::channel('business.{businessId}', function (User $user, int $businessId) {
    return (int) $user->business_id === $businessId;
});
