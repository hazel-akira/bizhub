<?php

namespace App\Http\Controllers\Api;

use App\Enums\RepairTicketStatus;
use App\Http\Controllers\Concerns\RespondsWithJson;
use App\Http\Controllers\Controller;
use App\Http\Requests\StoreRepairTicketRequest;
use App\Http\Requests\UpdateRepairTicketRequest;
use App\Models\RepairTicket;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class RepairTicketController extends Controller
{
    use RespondsWithJson;

    public function index(Request $request): JsonResponse
    {
        $tickets = RepairTicket::forBusiness($request->user()->business_id)
            ->when(
                $request->filled('status'),
                fn ($query) => $query->where('status', $request->string('status'))
            )
            ->latest()
            ->get()
            ->map(fn (RepairTicket $ticket) => $this->format($ticket));

        return $this->success($tickets);
    }

    public function store(StoreRepairTicketRequest $request): JsonResponse
    {
        $validated = $request->validated();
        $status = RepairTicketStatus::tryFrom((string) ($validated['status'] ?? ''))
            ?? RepairTicketStatus::Pending;

        $ticket = RepairTicket::create([
            'business_id' => $request->user()->business_id,
            'user_id' => $request->user()->id,
            'ticket_number' => $this->nextTicketNumber((int) $request->user()->business_id),
            'customer_name' => $validated['customer_name'],
            'customer_phone' => $validated['customer_phone'] ?? null,
            'phone_model' => $validated['phone_model'],
            'issue_description' => $validated['issue_description'],
            'spare_parts_used' => $validated['spare_parts_used'] ?? null,
            'labor_cost' => $validated['labor_cost'] ?? 0,
            'status' => $status,
        ]);

        return $this->success($this->format($ticket), 201, 'Repair ticket created');
    }

    public function show(Request $request, RepairTicket $repairTicket): JsonResponse
    {
        $this->authorizeTicket($request, $repairTicket);

        return $this->success($this->format($repairTicket));
    }

    public function update(UpdateRepairTicketRequest $request, RepairTicket $repairTicket): JsonResponse
    {
        $this->authorizeTicket($request, $repairTicket);
        $repairTicket->update($request->validated());

        return $this->success($this->format($repairTicket->fresh()));
    }

    public function destroy(Request $request, RepairTicket $repairTicket): JsonResponse
    {
        $this->authorizeTicket($request, $repairTicket);
        $repairTicket->delete();

        return $this->success(null, 200, 'Repair ticket deleted');
    }

    private function authorizeTicket(Request $request, RepairTicket $ticket): void
    {
        abort_if(
            $ticket->business_id !== $request->user()->business_id,
            404,
            'Repair ticket not found'
        );
    }

    private function nextTicketNumber(int $businessId): string
    {
        do {
            $number = 'RT-'.now()->format('ymd').'-'.Str::upper(Str::random(4));
        } while (
            RepairTicket::forBusiness($businessId)->where('ticket_number', $number)->exists()
        );

        return $number;
    }

    private function format(RepairTicket $ticket): array
    {
        $status = $ticket->status instanceof RepairTicketStatus
            ? $ticket->status
            : RepairTicketStatus::tryFrom((string) $ticket->status);

        return [
            'id' => $ticket->id,
            'ticket_number' => $ticket->ticket_number,
            'customer_name' => $ticket->customer_name,
            'customer_phone' => $ticket->customer_phone,
            'phone_model' => $ticket->phone_model,
            'issue_description' => $ticket->issue_description,
            'spare_parts_used' => $ticket->spare_parts_used,
            'labor_cost' => $ticket->labor_cost,
            'status' => $status?->value ?? RepairTicketStatus::Pending->value,
            'status_label' => $status?->label() ?? RepairTicketStatus::Pending->label(),
            'created_at' => $ticket->created_at?->toIso8601String(),
            'updated_at' => $ticket->updated_at?->toIso8601String(),
        ];
    }
}
