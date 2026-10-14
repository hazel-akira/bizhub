import 'package:akira_bites/core/business_theme.dart';
import 'package:akira_bites/core/business_type_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('vehicle spare parts uses a parts shop layout', () {
    final config = BusinessTypeConfig.forType('vehicle_spares');

    expect(config.label, 'Vehicle Spare Parts');
    expect(config.isFoodBusiness, isFalse);
    expect(config.showInventoryNav, isTrue);
    expect(config.showProductionDrawer, isFalse);
    expect(config.showRepairsNav, isFalse);
    expect(config.productNoun, 'part');
    expect(config.expenseNameHint, 'e.g. Stock, Transport, Tools');
  });

  test('vehicle spare parts has its own colors', () {
    final palette = BusinessThemePalette.forType('vehicle_spares');

    expect(palette.id, 'vehicle_spares');
    expect(palette.label, 'Vehicle Spare Parts');
  });
}
