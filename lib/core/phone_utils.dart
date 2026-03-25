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
