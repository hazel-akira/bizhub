class WakeParseResult {
  const WakeParseResult({required this.heardWake, required this.command});

  final bool heardWake;
  final String command;
}

/// Detects "Hi Akira Flow" / "Kira Flow" and the shop command after it.
WakeParseResult parseVoiceWake(String raw) {
  var text = raw.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
  text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (text.isEmpty) {
    return const WakeParseResult(heardWake: false, command: '');
  }

  text = text
      .replaceAll('akiraflow', 'akira flow')
      .replaceAll('kiraflow', 'akira flow')
      .replaceAll(RegExp(r'\ba kira flow\b'), 'akira flow')
      .replaceAll(RegExp(r'\bakira flo\b'), 'akira flow')
      .replaceAll(RegExp(r'\bkira flow\b'), 'akira flow')
      .replaceAll(RegExp(r'\bhi kira\b'), 'hi akira flow')
      .replaceAll(RegExp(r'\bhey kira\b'), 'hey akira flow');

  final match = RegExp(
    r'(?:(?:hi|hey|hello|ok)\s+)?akira flow',
  ).firstMatch(text);

  if (match == null) {
    return WakeParseResult(heardWake: false, command: text);
  }

  var command = text.substring(match.end).trim();
  command = command.replaceFirst(
    RegExp(r'^(please|can you|could you|for me|kindly)\s+'),
    '',
  );
  return WakeParseResult(heardWake: true, command: command);
}
