<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Concerns\RespondsWithJson;
use App\Http\Controllers\Controller;
use App\Services\ShopOrderService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ShopOrderController extends Controller
{
    use RespondsWithJson;

    public function __construct(private readonly ShopOrderService $orders) {}

    public function index(Request $request): JsonResponse
    {
        return $this->success(
            $this->orders->listPendingForBusiness($request->user()->business_id)
        );
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'customer_id' => ['required', 'integer'],
            'ndengu_count' => ['nullable', 'integer', 'min:0'],
            'meat_count' => ['nullable', 'integer', 'min:0'],
        ]);

        $order = $this->orders->create($request->user(), $validated);

        return $this->success($order, 201);
    }

    public function fulfill(Request $request, int $id): JsonResponse
    {
        $order = $this->orders->findForBusiness($request->user()->business_id, $id);

        if (! $order) {
            return $this->error('Order not found', 404);
        }

        $result = $this->orders->fulfill($request->user(), $order);

        return $this->success($result);
    }
}
