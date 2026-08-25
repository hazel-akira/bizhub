<?php

namespace App\Enums;

enum MpesaTransactionStatus: string
{
    case Pending = 'PENDING';
    case Completed = 'COMPLETED';
    case Failed = 'FAILED';
}
