class ProductDepartment {
  static const babyShop = 'baby_shop';
  static const bakery = 'bakery';
  static const phoneRepair = 'phone_repair';

  static const values = [babyShop, bakery, phoneRepair];

  static String label(String? id) {
    switch (id) {
      case babyShop:
        return 'Baby Shop';
      case bakery:
        return 'Bakery';
      case phoneRepair:
        return 'Phone Repair';
      default:
        return 'General';
    }
  }

  static String? fromBusinessType(String? typeId) {
    if (typeId == babyShop || typeId == bakery || typeId == phoneRepair) {
      return typeId;
    }
    return null;
  }
}

class RepairTicketStatus {
  static const pending = 'pending';
  static const fixed = 'fixed';
  static const collected = 'collected';

  static const values = [pending, fixed, collected];

  static String label(String? id) {
    switch (id) {
      case pending:
        return 'Pending';
      case fixed:
        return 'Fixed';
      case collected:
        return 'Collected';
      default:
        return 'Pending';
    }
  }
}
