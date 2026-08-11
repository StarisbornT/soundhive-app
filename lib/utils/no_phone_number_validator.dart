class NoPhoneNumberValidator {
  /// Returns an error message if [text] looks like it contains a phone
  /// number, or null if it's fine. Mirrors the backend's NoPhoneNumber rule.
  static String? validate(String? text) {
    if (text == null || text.trim().isEmpty) return null;

    if (_containsPhoneNumber(text)) {
      return "For your safety, please don't share phone numbers or "
          "contact details before a booking is confirmed. You'll be able "
          "to exchange contact info in chat once the booking is made.";
    }

    return null;
  }

  static bool _containsPhoneNumber(String text) {
    // Tier 1: digits broken up by spaces/dashes/dots/parens/slashes,
    // e.g. "080 123 4567", "(080) 123-4567", "+234-801-234-5678"
    final separated = RegExp(r'(\+?\d[\d\-.\s()/]{5,}\d)');
    for (final match in separated.allMatches(text)) {
      final digitsOnly = match.group(1)!.replaceAll(RegExp(r'\D'), '');
      if (digitsOnly.length >= 7) return true;
    }

    // Tier 2: unbroken digit runs, e.g. "08012345678" with no spaces at all.
    // Higher threshold (10+) so a plain amount like "5000000" doesn't
    // false-positive.
    if (RegExp(r'\d{10,}').hasMatch(text)) return true;

    return false;
  }
}