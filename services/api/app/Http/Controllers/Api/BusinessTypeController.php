<?php

namespace App\Http\Controllers\Api;

use App\Enums\BusinessType;
use App\Http\Controllers\Concerns\RespondsWithJson;
use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;

class BusinessTypeController extends Controller
{
    use RespondsWithJson;

    public function index(): JsonResponse
    {
        return $this->success(BusinessType::catalog());
    }
}
