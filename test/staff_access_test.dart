import 'package:akira_bites/core/staff_access.dart';
import 'package:flutter_test/flutter_test.dart';

StaffAccess _access(List<String> roles) {
  return StaffAccess(
    roles: StaffAccess.normalize(roles),
    permissions: StaffAccess.permissionsFor(roles).toSet(),
  );
}

void main() {
  test('cashier can sell but cannot open books or staff', () {
    final access = _access(const [StaffAccess.cashier]);
    expect(access.canOpenSales, isTrue);
    expect(access.canOpenCustomers, isTrue);
    expect(access.canOpenReports, isFalse);
    expect(access.canOpenExpenses, isFalse);
    expect(access.canOpenProfit, isFalse);
    expect(access.canOpenInventory, isFalse);
    expect(access.canOpenStaff, isFalse);
    expect(access.canOpenSettings, isFalse);
  });

  test('stock can manage inventory but cannot sell', () {
    final access = _access(const [StaffAccess.stock]);
    expect(access.canOpenInventory, isTrue);
    expect(access.canOpenProduction, isTrue);
    expect(access.canOpenSales, isFalse);
    expect(access.canOpenCustomers, isFalse);
    expect(access.canOpenReports, isFalse);
    expect(access.canOpenStaff, isFalse);
  });

  test('manager can run the shop but not profit or staff', () {
    final access = _access(const [StaffAccess.manager]);
    expect(access.canOpenSales, isTrue);
    expect(access.canOpenReports, isTrue);
    expect(access.canOpenCustomers, isTrue);
    expect(access.canOpenInventory, isTrue);
    expect(access.canOpenProfit, isFalse);
    expect(access.canOpenExpenses, isFalse);
    expect(access.canOpenStaff, isFalse);
    expect(access.canOpenSettings, isFalse);
  });

  test('owner can open every restricted page', () {
    final access = _access(const [StaffAccess.owner]);
    expect(access.canOpenStaff, isTrue);
    expect(access.canOpenSettings, isTrue);
    expect(access.canOpenProfit, isTrue);
    expect(access.canOpenExpenses, isTrue);
    expect(access.canOpenReports, isTrue);
  });
}
