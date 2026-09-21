import 'package:akira_bites/core/api_config.dart';
import 'package:akira_bites/services/api_config_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('uses the Render production API by default', () {
    expect(defaultApiBaseUrl, productionApiBaseUrl);
    expect(defaultApiBaseUrl, 'https://akira-flow-api.onrender.com');
  });

  test('clears a saved custom URL and uses the production API', () async {
    SharedPreferences.setMockInitialValues({
      'akira_api_base_url': 'https://example.com/old-api',
    });

    final url = await ApiConfigService.getBaseUrl();

    expect(url, productionApiBaseUrl);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('akira_api_base_url'), isNull);
  });

  test('sanitizeApiBaseUrl strips trailing slashes', () {
    expect(
      sanitizeApiBaseUrl('https://akira-flow-api.onrender.com/'),
      'https://akira-flow-api.onrender.com',
    );
  });
}
