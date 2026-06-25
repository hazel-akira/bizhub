import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../core/api_config.dart';
import '../services/api_client.dart';
import '../services/api_config_service.dart';

class ApiConnectionCard extends StatefulWidget {
  const ApiConnectionCard({super.key});

  @override
  State<ApiConnectionCard> createState() => _ApiConnectionCardState();
}

class _ApiConnectionCardState extends State<ApiConnectionCard> {
  final _urlController = TextEditingController();
  bool _loading = false;
  bool _loaded = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _loadUrl();
  }

  Future<void> _loadUrl() async {
    final url = await ApiConfigService.getBaseUrl();
    if (!mounted) return;
    setState(() {
      _urlController.text = url;
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ApiConfigService.setBaseUrl(_urlController.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('API URL saved')),
    );
  }

  Future<void> _reset() async {
    await ApiConfigService.resetToDefault();
    if (!mounted) return;
    setState(() => _urlController.text = defaultApiBaseUrl);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reset to default URL')),
    );
  }

  Future<void> _test() async {
    setState(() {
      _loading = true;
      _status = null;
    });

    await ApiConfigService.setBaseUrl(_urlController.text);
    ApiClient().clearBaseUrlCache();
    final result = await ApiClient().testConnectionDetailed();

    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.ok) {
        _status = 'Connected ✓';
      } else {
        _status = result.message ?? 'Cannot reach server ✗';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const SizedBox(
        height: 48,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'API connection',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Server URL',
                hintText: 'https://api.akirabites.shop',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: TextInputType.url,
              autocorrect: false,
              readOnly: kReleaseMode,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: kReleaseMode || _loading ? null : _test,
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Test'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: kReleaseMode ? null : _save,
                    child: const Text('Save'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Reset default',
                  onPressed: kReleaseMode ? null : _reset,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            if (_status != null) ...[
              const SizedBox(height: 6),
              Text(
                _status!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _status!.contains('✓')
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            Text(
              kReleaseMode
                  ? 'Release build endpoint is managed via --dart-define API_BASE_URL.'
                  : 'Linux: 127.0.0.1 · Emulator: 10.0.2.2 · Phone: your PC IP',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
