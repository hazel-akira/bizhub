<?php

namespace App\Services;

use App\Enums\ProductDepartment;
use App\Models\Category;
use App\Models\Customer;
use App\Models\Product;
use App\Models\Sale;
use App\Models\SaleItem;
use App\Models\User;
use Illuminate\Support\Facades\Http;
use Illuminate\Validation\ValidationException;

class AssistantService
{
    /** @var list<string> */
    private array $actions = [];

    public function __construct(
        private readonly DashboardService $dashboard,
        private readonly SaleService $sales,
        private readonly ExpenseService $expenses,
    ) {}

    /**
     * @return array{reply: string, actions: list<string>, ai: bool}
     */
    public function chat(User $user, string $message): array
    {
        $this->actions = [];
        $message = trim($message);
        if ($message === '') {
            return [
                'reply' => 'Say or type what you need — add a product, record a sale, or ask how the shop is doing today.',
                'actions' => [],
                'ai' => false,
            ];
        }

        if ($this->apiKey() === '') {
            return [
                'reply' => $this->keywordReply($user, $message),
                'actions' => $this->actions,
                'ai' => false,
            ];
        }

        try {
            return [
                'reply' => $this->chatWithOpenAi($user, $message),
                'actions' => array_values(array_unique($this->actions)),
                'ai' => true,
            ];
        } catch (\Throwable $e) {
            report($e);

            return [
                'reply' => $this->keywordReply($user, $message)
                    ."\n\n(AI is temporarily unavailable, so I used the built-in helper.)",
                'actions' => $this->actions,
                'ai' => false,
            ];
        }
    }

    private function chatWithOpenAi(User $user, string $message): string
    {
        $user->loadMissing('business');
        $shop = $user->business?->name ?? 'your shop';
        $type = $user->business?->business_type ?? 'shop';

        $messages = [
            [
                'role' => 'system',
                'content' => 'You are Akira Flow, a shop assistant inside a Kenyan POS app. '
                    ."The business is \"{$shop}\" (type: {$type}). Currency is KES. "
                    .'Users may speak English, Swahili, or mixed Sheng. Speech-to-text is noisy: treat "sock" as stock, "AkiraFlow"/"Kira Flow" as your name, and keep product names like "nails 3 inches". '
                    .'You can look up sales, profit, debts, and inventory, and you can take actions: add products, update stock, record expenses, add customers, and record simple sales. '
                    .'Phrases like "add for me product A selling 300 buying 250 we have 50 in stock" mean add_product(name=A, selling_price=300, cost_price=250, stock_quantity=50). '
                    .'Phrases like "add a sale of two nails 3 inches" mean search_inventory then record_sale for that product. '
                    .'When adding a product, selling_price is required. cost_price and stock default to 0. '
                    .'Do not invent prices. If a required value is missing, ask one short question. '
                    .'Search inventory before updating stock or recording a sale if you are unsure which product. '
                    .'Confirm what you did in plain language. Keep replies short.',
            ],
            ['role' => 'user', 'content' => $message],
        ];

        for ($i = 0; $i < 6; $i++) {
            $payload = $this->openAiRequest($messages);
            $choice = $payload['choices'][0]['message'] ?? [];
            $toolCalls = $choice['tool_calls'] ?? [];

            if ($toolCalls === []) {
                $text = trim((string) ($choice['content'] ?? ''));

                return $text !== '' ? $text : 'I could not complete that. Try again in a short sentence.';
            }

            $messages[] = [
                'role' => 'assistant',
                'content' => $choice['content'] ?? null,
                'tool_calls' => $toolCalls,
            ];

            foreach ($toolCalls as $call) {
                $name = (string) ($call['function']['name'] ?? '');
                $args = json_decode((string) ($call['function']['arguments'] ?? '{}'), true);
                if (! is_array($args)) {
                    $args = [];
                }
                $messages[] = [
                    'role' => 'tool',
                    'tool_call_id' => (string) ($call['id'] ?? ''),
                    'content' => json_encode($this->runTool($user, $name, $args), JSON_UNESCAPED_UNICODE),
                ];
            }
        }

        return 'That request needed too many steps. Try a shorter command, like “add milk selling 60 buying 45 stock 10”.';
    }

    /**
     * @param  array<int, array<string, mixed>>  $messages
     * @return array<string, mixed>
     */
    private function openAiRequest(array $messages): array
    {
        $response = Http::withToken($this->apiKey())
            ->timeout(30)
            ->acceptJson()
            ->post(rtrim((string) config('services.openai.base_url'), '/').'/chat/completions', [
                'model' => config('services.openai.model', 'gpt-4o-mini'),
                'temperature' => 0.2,
                'messages' => $messages,
                'tools' => $this->tools(),
                'tool_choice' => 'auto',
            ]);

        if (! $response->successful()) {
            throw new \RuntimeException('OpenAI request failed: '.$response->status());
        }

        return $response->json() ?? [];
    }

    /**
     * @param  array<string, mixed>  $args
     * @return array<string, mixed>
     */
    private function runTool(User $user, string $name, array $args): array
    {
        try {
            return match ($name) {
                'get_today_summary' => $this->toolTodaySummary($user),
                'get_unpaid_customers' => $this->toolUnpaid($user),
                'get_best_selling' => $this->toolBestSelling($user),
                'search_inventory' => $this->toolSearchInventory($user, $args),
                'add_product' => $this->toolAddProduct($user, $args),
                'update_stock' => $this->toolUpdateStock($user, $args),
                'add_expense' => $this->toolAddExpense($user, $args),
                'add_customer' => $this->toolAddCustomer($user, $args),
                'record_sale' => $this->toolRecordSale($user, $args),
                default => ['error' => 'Unknown action'],
            };
        } catch (ValidationException $e) {
            return ['error' => collect($e->errors())->flatten()->first() ?? $e->getMessage()];
        } catch (\Throwable $e) {
            return ['error' => $e->getMessage()];
        }
    }

    /**
     * @return list<array<string, mixed>>
     */
    private function tools(): array
    {
        $productProps = [
            'type' => 'object',
            'properties' => [
                'query' => ['type' => 'string', 'description' => 'Product name or part of the name'],
            ],
            'required' => ['query'],
        ];

        return [
            $this->fn('get_today_summary', 'Get today sales, expenses, profit, units sold, and low stock.'),
            $this->fn('get_unpaid_customers', 'List customers who still owe money.'),
            $this->fn('get_best_selling', 'Get the best selling product this week.'),
            $this->fn('search_inventory', 'Search products in this shop inventory.', $productProps),
            $this->fn('add_product', 'Add a custom product to inventory.', [
                'type' => 'object',
                'properties' => [
                    'name' => ['type' => 'string'],
                    'selling_price' => ['type' => 'number'],
                    'cost_price' => ['type' => 'number', 'description' => 'Buying price'],
                    'stock_quantity' => ['type' => 'integer'],
                    'subcategory' => ['type' => 'string', 'description' => 'Shop subcategory or form, e.g. Dry Goods, Fresh, 500ml'],
                ],
                'required' => ['name', 'selling_price'],
            ]),
            $this->fn('update_stock', 'Set or add stock for a product found by name.', [
                'type' => 'object',
                'properties' => [
                    'product_name' => ['type' => 'string'],
                    'quantity' => ['type' => 'integer'],
                    'mode' => ['type' => 'string', 'enum' => ['set', 'add'], 'description' => 'set replaces stock, add increases it'],
                ],
                'required' => ['product_name', 'quantity'],
            ]),
            $this->fn('add_expense', 'Record a shop expense.', [
                'type' => 'object',
                'properties' => [
                    'title' => ['type' => 'string'],
                    'amount' => ['type' => 'number'],
                ],
                'required' => ['title', 'amount'],
            ]),
            $this->fn('add_customer', 'Save a customer.', [
                'type' => 'object',
                'properties' => [
                    'name' => ['type' => 'string'],
                    'phone' => ['type' => 'string'],
                ],
                'required' => ['name'],
            ]),
            $this->fn('record_sale', 'Record a simple sale of one product.', [
                'type' => 'object',
                'properties' => [
                    'product_name' => ['type' => 'string'],
                    'quantity' => ['type' => 'integer'],
                    'payment_method' => ['type' => 'string', 'enum' => ['cash', 'mpesa', 'credit']],
                    'customer_name' => ['type' => 'string', 'description' => 'Required for credit sales'],
                ],
                'required' => ['product_name', 'quantity'],
            ]),
        ];
    }

    /**
     * @param  array<string, mixed>|null  $parameters
     * @return array<string, mixed>
     */
    private function fn(string $name, string $description, ?array $parameters = null): array
    {
        return [
            'type' => 'function',
            'function' => [
                'name' => $name,
                'description' => $description,
                'parameters' => $parameters ?? [
                    'type' => 'object',
                    'properties' => (object) [],
                ],
            ],
        ];
    }

    /** @return array<string, mixed> */
    private function toolTodaySummary(User $user): array
    {
        if (! $this->canViewShop($user)) {
            return ['error' => 'You do not have permission to view shop performance.'];
        }

        $summary = $this->dashboard->summary((int) $user->business_id);
        if (! $user->hasPermission('view_profit')) {
            unset(
                $summary['today_cogs'],
                $summary['today_gross_profit'],
                $summary['today_operating_profit'],
                $summary['today_net_profit'],
                $summary['today_profit'],
                $summary['today_gross_margin'],
                $summary['today_net_margin'],
            );
        }

        return $summary;
    }

    /** @return array<string, mixed> */
    private function toolUnpaid(User $user): array
    {
        if (! $user->hasPermission('view_sales') && ! $user->hasPermission('sell')) {
            return ['error' => 'You do not have permission to view unpaid customers.'];
        }

        $unpaid = $this->sales->listUnpaidForBusiness((int) $user->business_id);
        $byCustomer = [];
        foreach ($unpaid as $sale) {
            $name = $sale['customer_name'] ?? ('Customer '.($sale['customer_id'] ?? ''));
            $byCustomer[$name] = ($byCustomer[$name] ?? 0) + (float) ($sale['outstanding'] ?? 0);
        }
        arsort($byCustomer);

        return [
            'total' => array_sum($byCustomer),
            'customers' => collect($byCustomer)->take(8)->all(),
        ];
    }

    /** @return array<string, mixed> */
    private function toolBestSelling(User $user): array
    {
        if (! $this->canViewShop($user)) {
            return ['error' => 'You do not have permission to view sales.'];
        }

        $start = now()->startOfWeek();
        $saleIds = Sale::forBusiness((int) $user->business_id)
            ->where('sale_date', '>=', $start)
            ->pluck('id');

        if ($saleIds->isEmpty()) {
            return ['message' => 'No sales this week yet.'];
        }

        $row = SaleItem::query()
            ->whereIn('sale_id', $saleIds)
            ->selectRaw('product_id, SUM(quantity) as total_qty')
            ->groupBy('product_id')
            ->orderByDesc('total_qty')
            ->with('product')
            ->first();

        return [
            'product' => $row?->product?->name,
            'quantity' => (int) ($row?->total_qty ?? 0),
        ];
    }

    /**
     * @param  array<string, mixed>  $args
     * @return array<string, mixed>
     */
    private function toolSearchInventory(User $user, array $args): array
    {
        if (! $user->hasPermission('manage_stock')
            && ! $user->hasPermission('add_product')
            && ! $user->hasPermission('sell')
            && ! $user->hasPermission('view_sales')) {
            return ['error' => 'You do not have permission to search inventory.'];
        }

        $query = trim((string) ($args['query'] ?? ''));
        $products = Product::forBusiness((int) $user->business_id)
            ->when($query !== '', fn ($q) => $q->where('name', 'like', '%'.$query.'%'))
            ->with('category')
            ->orderBy('name')
            ->limit(12)
            ->get()
            ->map(fn (Product $p) => [
                'id' => $p->id,
                'name' => $p->name,
                'selling_price' => (float) $p->selling_price,
                'cost_price' => $user->hasPermission('edit_price') || $user->hasPermission('view_profit')
                    ? (float) $p->cost_price
                    : null,
                'stock_quantity' => $p->stock_quantity,
                'subcategory' => $p->category?->name,
            ]);

        return ['products' => $products];
    }

    /**
     * @param  array<string, mixed>  $args
     * @return array<string, mixed>
     */
    private function toolAddProduct(User $user, array $args): array
    {
        if (! $user->hasPermission('add_product')) {
            return ['error' => 'You do not have permission to add products.'];
        }

        $name = trim((string) ($args['name'] ?? ''));
        $selling = (float) ($args['selling_price'] ?? 0);
        if ($name === '' || $selling <= 0) {
            return ['error' => 'Product name and a selling price greater than 0 are required.'];
        }

        $user->loadMissing('business');
        $forced = ProductDepartment::fromBusinessType($user->business?->business_type);
        $categoryId = $this->resolveCategoryId($user, (string) ($args['subcategory'] ?? ''));

        $product = Product::create([
            'business_id' => $user->business_id,
            'global_product_id' => null,
            'category_id' => $categoryId,
            'name' => $name,
            'cost_price' => max(0, (float) ($args['cost_price'] ?? 0)),
            'selling_price' => $selling,
            'stock_quantity' => max(0, (int) ($args['stock_quantity'] ?? 0)),
            'department' => $forced?->value,
            'is_active' => true,
        ]);

        $this->actions[] = 'product_created';
        $product->load('category');

        return [
            'ok' => true,
            'id' => $product->id,
            'name' => $product->name,
            'selling_price' => (float) $product->selling_price,
            'cost_price' => (float) $product->cost_price,
            'stock_quantity' => $product->stock_quantity,
            'subcategory' => $product->category?->name,
        ];
    }

    /**
     * @param  array<string, mixed>  $args
     * @return array<string, mixed>
     */
    private function toolUpdateStock(User $user, array $args): array
    {
        if (! $user->hasPermission('manage_stock') && ! $user->hasPermission('add_product')) {
            return ['error' => 'You do not have permission to update stock.'];
        }

        $product = $this->matchOneProduct($user, (string) ($args['product_name'] ?? ''));
        if (isset($product['error']) || isset($product['matches'])) {
            return $product;
        }

        /** @var Product $found */
        $found = $product['product'];
        $qty = (int) ($args['quantity'] ?? 0);
        if ($qty < 0) {
            return ['error' => 'Quantity cannot be negative.'];
        }

        $mode = ($args['mode'] ?? 'set') === 'add' ? 'add' : 'set';
        if ($mode === 'add') {
            $found->increment('stock_quantity', $qty);
        } else {
            $found->update(['stock_quantity' => $qty]);
        }
        $found->refresh();
        $this->actions[] = 'product_updated';

        return [
            'ok' => true,
            'name' => $found->name,
            'stock_quantity' => $found->stock_quantity,
            'mode' => $mode,
        ];
    }

    /**
     * @param  array<string, mixed>  $args
     * @return array<string, mixed>
     */
    private function toolAddExpense(User $user, array $args): array
    {
        if (! $user->hasPermission('manage_expenses')) {
            return ['error' => 'You do not have permission to record expenses.'];
        }

        $title = trim((string) ($args['title'] ?? ''));
        $amount = (float) ($args['amount'] ?? 0);
        if ($title === '' || $amount < 0) {
            return ['error' => 'Expense title and amount are required.'];
        }

        $expense = $this->expenses->create($user, [
            'title' => $title,
            'amount' => $amount,
        ]);
        $this->actions[] = 'expense_created';

        return [
            'ok' => true,
            'title' => $expense->title,
            'amount' => (float) $expense->amount,
        ];
    }

    /**
     * @param  array<string, mixed>  $args
     * @return array<string, mixed>
     */
    private function toolAddCustomer(User $user, array $args): array
    {
        if (! $user->hasPermission('manage_customers') && ! $user->hasPermission('sell')) {
            return ['error' => 'You do not have permission to add customers.'];
        }

        $name = trim((string) ($args['name'] ?? ''));
        if ($name === '') {
            return ['error' => 'Customer name is required.'];
        }

        $customer = Customer::create([
            'business_id' => $user->business_id,
            'name' => $name,
            'phone' => trim((string) ($args['phone'] ?? '')) ?: null,
        ]);
        $this->actions[] = 'customer_created';

        return [
            'ok' => true,
            'id' => $customer->id,
            'name' => $customer->name,
            'phone' => $customer->phone,
        ];
    }

    /**
     * @param  array<string, mixed>  $args
     * @return array<string, mixed>
     */
    private function toolRecordSale(User $user, array $args): array
    {
        if (! $user->hasPermission('sell')) {
            return ['error' => 'You do not have permission to record sales.'];
        }

        $product = $this->matchOneProduct($user, (string) ($args['product_name'] ?? ''));
        if (isset($product['error']) || isset($product['matches'])) {
            return $product;
        }

        /** @var Product $found */
        $found = $product['product'];
        $qty = max(1, (int) ($args['quantity'] ?? 1));
        $method = strtolower((string) ($args['payment_method'] ?? 'cash'));
        if (! in_array($method, ['cash', 'mpesa', 'credit'], true)) {
            $method = 'cash';
        }

        $payload = [
            'payment_method' => $method,
            'items' => [
                ['product_id' => $found->id, 'quantity' => $qty],
            ],
        ];

        if ($method === 'credit') {
            $customerName = trim((string) ($args['customer_name'] ?? ''));
            if ($customerName === '') {
                return ['error' => 'A customer name is required for credit sales.'];
            }
            $customer = Customer::forBusiness((int) $user->business_id)
                ->whereRaw('LOWER(name) = ?', [mb_strtolower($customerName)])
                ->first();
            if ($customer === null) {
                $customer = Customer::create([
                    'business_id' => $user->business_id,
                    'name' => $customerName,
                ]);
                $this->actions[] = 'customer_created';
            }
            $payload['customer_id'] = $customer->id;
        }

        $sale = $this->sales->createSale($user, $payload);
        $this->actions[] = 'sale_created';

        return [
            'ok' => true,
            'invoice' => $sale['invoice_number'] ?? null,
            'total' => $sale['total_amount'] ?? null,
            'product' => $found->name,
            'quantity' => $qty,
            'payment_method' => $method,
        ];
    }

    /**
     * @return array<string, mixed>
     */
    private function matchOneProduct(User $user, string $name): array
    {
        $name = trim($name);
        if ($name === '') {
            return ['error' => 'Product name is required.'];
        }

        $matches = Product::forBusiness((int) $user->business_id)
            ->where('is_active', true)
            ->where('name', 'like', '%'.$name.'%')
            ->orderBy('name')
            ->limit(8)
            ->get(['id', 'name', 'selling_price', 'stock_quantity']);

        if ($matches->isEmpty()) {
            return ['error' => 'No product named "'.$name.'" was found in inventory.'];
        }

        $exact = $matches->first(
            fn (Product $p) => strcasecmp($p->name, $name) === 0
        );
        if ($exact !== null) {
            return ['product' => $exact];
        }

        if ($matches->count() === 1) {
            return ['product' => $matches->first()];
        }

        return [
            'error' => 'Several products match. Ask the user which one.',
            'matches' => $matches->map(fn (Product $p) => [
                'name' => $p->name,
                'stock_quantity' => $p->stock_quantity,
                'selling_price' => (float) $p->selling_price,
            ])->all(),
        ];
    }

    private function resolveCategoryId(User $user, string $name): ?int
    {
        $name = trim($name);
        if ($name === '') {
            return null;
        }

        $existing = Category::forBusiness((int) $user->business_id)
            ->get()
            ->first(fn (Category $category) => strcasecmp($category->name, $name) === 0);

        if ($existing === null) {
            $existing = Category::create([
                'business_id' => $user->business_id,
                'name' => $name,
                'created_at' => now(),
            ]);
        }

        return $existing->id;
    }

    private function canViewShop(User $user): bool
    {
        return $user->hasPermission('view_sales')
            || $user->hasPermission('view_reports')
            || $user->hasPermission('view_profit')
            || $user->hasPermission('sell');
    }

    private function keywordReply(User $user, string $input): string
    {
        $q = mb_strtolower($input);
        if (str_contains($q, 'who owe') || str_contains($q, 'unpaid customer') || str_contains($q, 'debtor')) {
            $data = $this->toolUnpaid($user);
            if (isset($data['error'])) {
                return (string) $data['error'];
            }
            $customers = $data['customers'] ?? [];
            if ($customers === []) {
                return 'No unpaid customers right now. All accounts are clear.';
            }
            $lines = [];
            foreach ($customers as $name => $amount) {
                $lines[] = '• '.$name.': KES '.number_format((float) $amount, 0);
            }

            return "Customers with unpaid balances:\n".implode("\n", $lines);
        }

        if (str_contains($q, 'best sell') || str_contains($q, 'top product') || str_contains($q, 'most sold')) {
            $data = $this->toolBestSelling($user);
            if (isset($data['error'])) {
                return (string) $data['error'];
            }
            if (empty($data['product'])) {
                return (string) ($data['message'] ?? 'No sales this week yet.');
            }

            return 'Best selling item this week: '.$data['product'].' ('.$data['quantity'].' sold).';
        }

        if (str_contains($q, 'summary') || str_contains($q, 'profit') || str_contains($q, 'revenue') || str_contains($q, 'dashboard') || str_contains($q, 'today')) {
            $data = $this->toolTodaySummary($user);
            if (isset($data['error'])) {
                return (string) $data['error'];
            }

            $lines = ['Here is your today snapshot:'];
            if (isset($data['today_units_sold'])) {
                $lines[] = '• Units sold: '.$data['today_units_sold'];
            }
            if (isset($data['today_sales'])) {
                $lines[] = '• Revenue: KES '.number_format((float) $data['today_sales'], 0);
            }
            if (isset($data['today_expenses'])) {
                $lines[] = '• Expenses: KES '.number_format((float) $data['today_expenses'], 0);
            }
            if (isset($data['today_profit'])) {
                $lines[] = '• Net profit: KES '.number_format((float) $data['today_profit'], 0);
            }

            return implode("\n", $lines);
        }

        return 'I can help by voice or text. Examples:'
            ."\n• add milk selling 60 buying 45 stock 10 subcategory Dairy"
            ."\n• add 20 more packets of milk to stock"
            ."\n• record cash sale of 3 milk"
            ."\n• today summary"
            ."\n• who owes"
            ."\n\nTo unlock natural language, set OPENAI_API_KEY on the API server.";
    }

    private function apiKey(): string
    {
        return trim((string) config('services.openai.key'));
    }
}
