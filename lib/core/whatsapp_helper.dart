import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'phone_utils.dart';

/// Prefilled WhatsApp URLs can be truncated on some devices past ~1–2k chars.
const int _maxWhatsAppPrefillChars = 1000;

/// Converts phone to WhatsApp format (e.g. 0712345678 -> 254712345678)
String normalizePhoneForWhatsApp(String phone) => normalizePhoneKey(phone);

String _clipPrefill(String? message) {
  if (message == null || message.isEmpty) return '';
  if (message.length <= _maxWhatsAppPrefillChars) return message;
  return '${message.substring(0, _maxWhatsAppPrefillChars - 24)}…\n(truncated)';
}

/// Opens WhatsApp chat with the given phone number.
/// [message] is optional pre-filled text.
///
/// Avoids `whatsapp://send?phone=...` first: some OEM builds drop the number and
/// open **Message yourself**. Uses `wa.me/<phone>` (number in path) and
/// [LaunchMode.externalNonBrowserApplication] on mobile where supported.
Future<bool> openWhatsAppChat(String phone, {String? message}) async {
  if (phone.trim().isEmpty) return false;
  final normalized = normalizePhoneForWhatsApp(phone);
  final clipped = _clipPrefill(message);
  final hasText = clipped.isNotEmpty;

  Future<bool> tryLaunch(Uri uri, LaunchMode mode) async {
    try {
      return await launchUrl(uri, mode: mode);
    } catch (_) {
      return false;
    }
  }

  Map<String, String>? waQuery;
  if (hasText) {
    waQuery = {'text': clipped};
  }
  final waMe = Uri.https('wa.me', '/$normalized', waQuery);

  final apiQuery = <String, String>{'phone': normalized};
  if (hasText) {
    apiQuery['text'] = clipped;
  }
  final api = Uri.https('api.whatsapp.com', '/send', apiQuery);

  final uris = <Uri>[waMe, api];
  final modes = kIsWeb
      ? <LaunchMode>[LaunchMode.externalApplication]
      : <LaunchMode>[
          LaunchMode.externalNonBrowserApplication,
          LaunchMode.externalApplication,
        ];

  for (final uri in uris) {
    for (final mode in modes) {
      if (await tryLaunch(uri, mode)) return true;
    }
  }
  return false;
}

/// Shares text (user can pick WhatsApp from share sheet)
Future<void> shareToWhatsApp(String text) async {
  await SharePlus.instance.share(
    ShareParams(
      text: text,
      subject: 'Samosa payment reminder',
    ),
  );
}
