@extends('layouts.order')

@section('title', 'Admin — Orders')

@section('content')
<div class="max-w-4xl mx-auto">
    <h1 class="text-2xl font-bold text-[var(--akira-black)] mb-6">Orders</h1>

    <div id="orders-loading" class="text-center py-12 text-gray-500">Loading orders...</div>

    <div id="orders-table" class="hidden overflow-x-auto">
        <table class="w-full bg-white rounded-2xl shadow-sm overflow-hidden">
            <thead class="bg-gray-100">
                <tr>
                    <th class="text-left py-3 px-4 font-semibold">ID</th>
                    <th class="text-left py-3 px-4 font-semibold">Phone</th>
                    <th class="text-left py-3 px-4 font-semibold">Total</th>
                    <th class="text-left py-3 px-4 font-semibold">Status</th>
                    <th class="text-left py-3 px-4 font-semibold">Receipt</th>
                    <th class="text-left py-3 px-4 font-semibold">Date</th>
                </tr>
            </thead>
            <tbody id="orders-tbody">
            </tbody>
        </table>
    </div>
</div>

@push('scripts')
<script>
    document.addEventListener('DOMContentLoaded', async () => {
        try {
            const res = await fetch('/api/admin/orders');
            const json = await res.json();
            document.getElementById('orders-loading').classList.add('hidden');
            const tbody = document.getElementById('orders-tbody');
            const orders = json.data || [];
            tbody.innerHTML = orders.map(o => `
                <tr class="border-t">
                    <td class="py-3 px-4">${o.id}</td>
                    <td class="py-3 px-4">${o.phone_number}</td>
                    <td class="py-3 px-4">KSh ${o.total_amount}</td>
                    <td class="py-3 px-4"><span class="px-2 py-1 rounded text-sm ${o.payment_status === 'paid' ? 'bg-green-100 text-green-800' : o.payment_status === 'failed' ? 'bg-red-100 text-red-800' : 'bg-amber-100 text-amber-800'}">${o.payment_status}</span></td>
                    <td class="py-3 px-4">${o.mpesa_receipt || '—'}</td>
                    <td class="py-3 px-4 text-sm text-gray-600">${new Date(o.created_at).toLocaleString()}</td>
                </tr>
            `).join('');
            document.getElementById('orders-table').classList.remove('hidden');
        } catch {
            document.getElementById('orders-loading').textContent = 'Failed to load orders.';
        }
    });
</script>
@endpush
@endsection
