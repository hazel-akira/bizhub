import 'api_config.dart';

export 'api_config.dart' show apiBaseUrl;

/// Fixed prices for samosas (in local currency)
class SamosaPrices {
  static const double ndenguPrice = 20.0;
  static const double meatPrice = 40.0;
}

/// @deprecated Use [apiBaseUrl] instead.
String get mpesaApiBaseUrl => apiBaseUrl;
