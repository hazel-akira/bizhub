/// Digits-only canonical form for Kenya numbers (254…), used for matching
/// duplicates regardless of spaces, +, or leading 0.
String normalizePhoneKey(String phone) {
  String digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return '';
  if (digits.startsWith('0')) {
    digits = '254${digits.substring(1)}';
  } else if (!digits.startsWith('254')) {
    digits = '254$digits';
  }
  return digits;
}

/// Human-readable local format for stored 254… numbers.
String formatPhoneForDisplay(String phone) {
  if (phone.trim().isEmpty) return '';
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('254') && digits.length >= 12) {
    final local = '0${digits.substring(3)}';
    if (local.length >= 10) {
      return '${local.substring(0, 4)} ${local.substring(4, 7)} ${local.substring(7)}';
    }
  }
  return phone.trim();
}
