import 'package:flutter_test/flutter_test.dart';

import 'package:akira_bites/core/voice_wake_phrases.dart';

void main() {
  test('extracts a product command after Hi Akira Flow', () {
    final parsed = parseVoiceWake(
      'Hi AkiraFlow, add for me product A, selling price 300, buying 250 and we have 50 in sock',
    );
    expect(parsed.heardWake, isTrue);
    expect(parsed.command, contains('product a'));
    expect(parsed.command, contains('300'));
    expect(parsed.command, isNot(contains('akira')));
  });

  test('accepts Kira Flow sale command', () {
    final parsed = parseVoiceWake(
      "KiraFlow add for me a sale of two nails 3 inches, 2 kilos",
    );
    expect(parsed.heardWake, isTrue);
    expect(parsed.command, contains('sale'));
    expect(parsed.command, contains('nails'));
  });

  test('ignores speech without the wake phrase', () {
    final parsed = parseVoiceWake('add milk selling 60');
    expect(parsed.heardWake, isFalse);
  });
}
