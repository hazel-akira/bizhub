<?php

namespace App\Services;

use App\Models\Expense;
use App\Models\User;

class ExpenseService
{
    public function create(User $user, array $data): Expense
    {
        return Expense::create([
            'business_id' => $user->business_id,
            'category_id' => $data['category_id'] ?? null,
            'title' => $data['title'],
            'description' => $data['description'] ?? null,
            'amount' => $data['amount'],
            'expense_date' => $data['expense_date'] ?? now(),
            'created_by' => $user->id,
            'created_at' => now(),
        ]);
    }

    public function update(Expense $expense, array $data): Expense
    {
        $expense->update([
            'category_id' => $data['category_id'] ?? $expense->category_id,
            'title' => $data['title'] ?? $expense->title,
            'description' => $data['description'] ?? $expense->description,
            'amount' => $data['amount'] ?? $expense->amount,
            'expense_date' => $data['expense_date'] ?? $expense->expense_date,
        ]);

        return $expense->fresh('category');
    }

    public function listForBusiness(int $businessId)
    {
        return Expense::forBusiness($businessId)
            ->with('category')
            ->orderByDesc('expense_date')
            ->get();
    }
}
