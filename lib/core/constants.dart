/// Fixed prices for samosas (in local currency)
class SamosaPrices {
  static const double ndenguPrice = 20.0;
  static const double meatPrice = 40.0;
}

/// M-Pesa API base URL. Flutter app calls this backend for STK Push.
/// - Android emulator: http://10.0.2.2:8000
/// - iOS simulator: http://localhost:8000
/// - Physical device (same WiFi): http://YOUR_COMPUTER_IP:8000
const String mpesaApiBaseUrl = 'http://10.0.2.2:8000';
