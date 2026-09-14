import 'package:akira_bites/core/api_config.dart';
import 'package:akira_bites/services/api_config_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('flags retired akirabites.shop hosts', () {
    expect(isRetiredApiBaseUrl('https://api.akirabites.shop'), isTrue);
    expect(isRetiredApiBaseUrl('https://akirabites.shop/'), isTrue);
    expect(isRetiredApiBaseUrl('https://www.akirabites.shop'), isTrue);
    expect(isRetiredApiBaseUrl(productionApiBaseUrl), isFalse);
    expect(isRetiredApiBaseUrl('http://127.0.0.1:8000'), isFalse);
  });

  test('uses the production API by default', () {
    expect(defaultApiBaseUrl, productionApiBaseUrl);
    expect(defaultApiBaseUrl, 'https://akira-flow-api.onrender.com');
  });

  test('clears a saved custom URL and uses the production API', () async {
    SharedPreferences.setMockInitialValues({
      'akira_api_base_url': 'https://api.akirabites.shop',
    });

    final url = await ApiConfigService.getBaseUrl();

    expect(url, productionApiBaseUrl);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('akira_api_base_url'), isNull);
  });
}
