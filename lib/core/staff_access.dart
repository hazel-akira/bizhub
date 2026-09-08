class StaffRoleInfo {
  const StaffRoleInfo({
    required this.id,
    required this.label,
    required this.summary,
  });

  final String id;
  final String label;
  final String summary;
}

class StaffAccess {
  const StaffAccess({
    required this.roles,
    required this.permissions,
  });

  final List<String> roles;
  final Set<String> permissions;

  static const cashier = 'cashier';
  static const stock = 'stock';
  static const manager = 'manager';
  static const owner = 'owner';

  static const catalog = [
    StaffRoleInfo(
      id: cashier,
      label: 'Cashier / Teller',
      summary: 'Checkout, cash/M-Pesa, receipts. Cannot edit prices, refund, or see profit.',
    ),
    StaffRoleInfo(
      id: stock,
      label: 'Stock / Inventory',
      summary: 'Add stock and products. Cannot take sales or see the books.',
    ),
    StaffRoleInfo(
      id: manager,
      label: 'Manager / Supervisor',
      summary: 'Refunds, discounts, stock, sales summaries. Cannot change base prices or net profit.',
    ),
    StaffRoleInfo(
      id: owner,
      label: 'Owner / Admin',
      summary: 'Full access, including prices, profit, and staff roles.',
    ),
  ];

  factory StaffAccess.full() {
    return StaffAccess(
      roles: const [owner],
      permissions: permissionsFor(const [owner]).toSet(),
    );
  }

  bool can(String permission) => permissions.contains(permission);

  bool get isOwner => roles.contains(owner);
  bool get canSell => can('sell');
  bool get canViewSales => can('view_sales');
  bool get canRefund => can('refund');
  bool get canApplyDiscount => can('apply_discount');
  bool get canEditPrice => can('edit_price');
  bool get canManageStock => can('manage_stock');
  bool get canAddProduct => can('add_product');
  bool get canViewProfit => can('view_profit');
  bool get canViewReports => can('view_reports');
  bool get canManageExpenses => can('manage_expenses');
  bool get canManageCustomers => can('manage_customers');
  bool get canManageStaff => can('manage_staff');
  bool get canManageSettings => can('manage_settings');
  bool get canSeeCost => canEditPrice || canViewProfit || canManageStock;

  static List<String> normalize(Iterable<String> roles) {
    final out = <String>{};
    for (final raw in roles) {
      var value = raw.trim().toLowerCase();
      if (value == 'admin') value = owner;
      if (value == cashier ||
          value == stock ||
          value == manager ||
          value == owner) {
        out.add(value);
      }
    }
    return out.toList();
  }

  static bool cashierConflictsWithOwner(Iterable<String> roles) {
    final normalized = normalize(roles);
    return normalized.contains(cashier) && normalized.contains(owner);
  }

  static List<String> permissionsFor(Iterable<String> roles) {
    final normalized = normalize(roles);
    if (normalized.contains(owner)) {
      return const [
        'sell',
        'view_sales',
        'refund',
        'apply_discount',
        'edit_price',
        'manage_stock',
        'add_product',
        'view_profit',
        'view_reports',
        'manage_expenses',
        'manage_customers',
        'manage_staff',
        'manage_settings',
      ];
    }

    final permissions = <String>{};
    for (final role in normalized) {
      permissions.addAll(_permissionsForRole(role));
    }
    return permissions.toList();
  }

  static List<String> _permissionsForRole(String role) {
    switch (role) {
      case cashier:
        return const ['sell', 'view_sales'];
      case stock:
        return const ['manage_stock', 'add_product'];
      case manager:
        return const [
          'sell',
          'view_sales',
          'refund',
          'apply_discount',
          'manage_stock',
          'add_product',
          'view_reports',
          'manage_customers',
        ];
      case owner:
        return permissionsFor(const [owner]);
      default:
        return const [];
    }
  }
}
