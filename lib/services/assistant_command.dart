enum AssistantIntent {
  bestSelling,
  whoOwes,
  unpaidTotal,
  profit,
  revenue,
  unitsSold,
  todaySummary,
  unknown,
}

const assistantHelp = 'I can help with:\n'
    '- today summary\n'
    '- profit today\n'
    '- revenue today\n'
    '- units sold today\n'
    '- unpaid total\n'
    '- who owes\n'
    '- best selling this week';

String normalizeAssistantInput(String input) {
  return input
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

/// Most specific phrase wins. Spoken wording such as "who owes me" and
/// "what's my profit" maps to the same intents as the quick chips.
AssistantIntent matchAssistantCommand(String input) {
  final q = normalizeAssistantInput(input);
  if (q.isEmpty) return AssistantIntent.unknown;

  bool hasAny(List<String> phrases) => phrases.any(q.contains);

  if (hasAny([
    'best sell',
    'bestseller',
    'best seller',
    'top product',
    'top seller',
    'most sold',
  ])) {
    return AssistantIntent.bestSelling;
  }

  if (hasAny([
    'who owes',
    'who owe',
    'owes me',
    'owe me',
    'debtors',
    'unpaid customer',
    'who is owing',
  ])) {
    return AssistantIntent.whoOwes;
  }

  if (hasAny([
        'unpaid total',
        'total unpaid',
        'total debt',
        'how much owed',
        'how much is owed',
        'outstanding',
        'balance owed',
        'how much unpaid',
        'debt total',
      ]) ||
      (q.contains('unpaid') &&
          (q.contains('how much') ||
              q.contains('total') ||
              q.contains('balance')))) {
    return AssistantIntent.unpaidTotal;
  }

  if (q.contains('profit') || q.contains('am i up') || q.contains('in profit')) {
    return AssistantIntent.profit;
  }

  if (hasAny([
    'revenue',
    'sales today',
    'today sales',
    'money today',
    'how much did i make',
    'made today',
    'takings',
  ])) {
    return AssistantIntent.revenue;
  }

  if (hasAny([
    'sold today',
    'how many sold',
    'units sold',
    'quantity today',
    'samosa',
    'items sold',
  ])) {
    return AssistantIntent.unitsSold;
  }

  if (q == 'unpaid' || q == 'debt' || q == 'debts') {
    return AssistantIntent.whoOwes;
  }

  if (hasAny([
        'summary',
        'dashboard',
        'today performance',
        'how is the business',
        'how am i doing',
        'how did i do',
      ]) ||
      q == 'today' ||
      q == 'status') {
    return AssistantIntent.todaySummary;
  }

  return AssistantIntent.unknown;
}
