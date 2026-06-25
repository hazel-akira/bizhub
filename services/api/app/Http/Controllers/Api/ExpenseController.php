<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Concerns\RespondsWithJson;
use App\Http\Controllers\Controller;
use App\Http\Requests\StoreExpenseRequest;
use App\Models\Expense;
use App\Services\ExpenseService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ExpenseController extends Controller
{
    use RespondsWithJson;

    public function __construct(private readonly ExpenseService $expenses) {}

    public function index(Request $request): JsonResponse
    {
        return $this->success(
            $this->expenses->listForBusiness($request->user()->business_id)
        );
    }

    public function store(StoreExpenseRequest $request): JsonResponse
    {
        $expense = $this->expenses->create($request->user(), $request->validated());

        return $this->success($expense, 201);
    }

    public function update(StoreExpenseRequest $request, Expense $expense): JsonResponse
    {
        $this->authorizeExpense($request, $expense);

        $expense = $this->expenses->update($expense, $request->validated());

        return $this->success($expense);
    }

    public function destroy(Request $request, Expense $expense): JsonResponse
    {
        $this->authorizeExpense($request, $expense);
        $expense->delete();

        return $this->success(null, 200, 'Expense deleted');
    }

    private function authorizeExpense(Request $request, Expense $expense): void
    {
        abort_if(
            $expense->business_id !== $request->user()->business_id,
            404,
            'Expense not found'
        );
    }
}
