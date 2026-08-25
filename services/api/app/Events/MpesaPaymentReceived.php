<?php

namespace App\Events;

use App\Models\MpesaTransaction;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class MpesaPaymentReceived implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(public MpesaTransaction $transaction) {}

    public function broadcastOn(): array
    {
        return [
            new PrivateChannel('business.'.$this->transaction->business_id),
        ];
    }

    public function broadcastAs(): string
    {
        return 'MpesaPaymentReceived';
    }

    public function broadcastWith(): array
    {
        return [
            'id' => $this->transaction->id,
            'business_id' => $this->transaction->business_id,
            'amount' => $this->transaction->amount,
            'phone' => $this->transaction->phone,
            'status' => $this->transaction->status?->value,
            'mpesa_receipt_number' => $this->transaction->mpesa_receipt_number,
            'checkout_request_id' => $this->transaction->checkout_request_id,
            'sale_id' => $this->transaction->sale_id,
        ];
    }
}
