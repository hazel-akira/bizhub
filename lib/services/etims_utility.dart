import 'dart:developer' as developer;

import '../models/api_sale.dart';
import 'etims_settings_service.dart';

/// Background utility for KRA eTIMS (electronic Tax Invoice Management System).
///
/// When integration is enabled, this runs after the sale is saved and before
/// the invoice is treated as finalized. Wire real OSCU/VSCU API calls here.
class EtimsUtility {
  EtimsUtility._();

  /// Saves the sale first via [persistSale], then optionally runs eTIMS
  /// before returning the finalized sale.
  static Future<ApiSale> finalizeSale({
    required Future<ApiSale> Function() persistSale,
  }) async {
    final sale = await persistSale();

    final enabled = await EtimsSettingsService.instance.isEnabled();
    if (!enabled) {
      return sale;
    }

    await processInvoiceBeforeFinalize(sale);
    return sale;
  }

  /// Submits the invoice to eTIMS. Intended as a background step; failures
  /// are logged so a temporary KRA outage does not roll back the local sale.
  static Future<void> processInvoiceBeforeFinalize(ApiSale sale) async {
    try {
      final settings = await EtimsSettingsService.instance.getSettings();
      developer.log(
        'eTIMS: submitting invoice '
        '${sale.displayLabel} (sale #${sale.id}, '
        'KES ${sale.totalAmount.toStringAsFixed(2)}, '
        'PIN=${settings.kraPin.isEmpty ? "(missing)" : settings.kraPin})',
        name: 'etims',
      );

      // TODO: Call KRA eTIMS OSCU/VSCU API with settings.kraPin +
      // settings.deviceToken (sign & transmit tax invoice).
      await Future<void>.delayed(Duration.zero);
    } catch (e, st) {
      developer.log(
        'eTIMS: failed for sale #${sale.id}: $e',
        name: 'etims',
        error: e,
        stackTrace: st,
      );
    }
  }
}
