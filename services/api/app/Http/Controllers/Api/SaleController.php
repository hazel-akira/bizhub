<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Concerns\RespondsWithJson;
use App\Http\Controllers\Controller;
use App\Http\Requests\RecordSalePaymentRequest;
use App\Http\Requests\StoreSaleRequest;
use App\Services\SaleService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SaleController extends Controller
{
    use RespondsWithJson;

    public function __construct(private readonly SaleService $sales) {}

    public function index(Request $request): JsonResponse
    {
        return $this->success(
            $this->sales->listForBusiness($request->user()->business_id)
        );
    }

    public function unpaid(Request $request): JsonResponse
    {
        return $this->success(
            $this->sales->listUnpaidForBusiness($request->user()->business_id)
        );
    }

    public function show(Request $request, int $id): JsonResponse
    {
        $sale = $this->sales->findFormattedForBusiness($request->user()->business_id, $id);

        if (! $sale) {
            return $this->error('Sale not found', 404);
        }

        return $this->success($sale);
    }

    public function store(StoreSaleRequest $request): JsonResponse
    {
        $sale = $this->sales->createSale($request->user(), $request->validated());

        return $this->success($sale, 201);
    }

    public function recordPayment(
        RecordSalePaymentRequest $request,
        int $id,
    ): JsonResponse {
        $sale = $this->sales->findForBusiness($request->user()->business_id, $id);

        if (! $sale) {
            return $this->error('Sale not found', 404);
        }

        $validated = $request->validated();
        $sale = $this->sales->recordPayment(
            $request->user(),
            $sale,
            (float) $validated['amount'],
            $validated['payment_method'] ?? 'cash',
        );

        return $this->success($sale);
    }
}
