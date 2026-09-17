/// Splitting a "YYYY.MM.DD" birthdate into the three fields the API stores.
///
/// Pure, because the original was three ternaries inline in a 1,000-line submit
/// method and contained a bug that looked like a guard:
///
///   final dateParts = birthDate.split('.');
///   final year = dateParts.isNotEmpty ? dateParts[0] : '';
///
/// `''.split('.')` returns `['']` — a one-element list holding an empty string
/// — so `isNotEmpty` is true and `year` becomes `''`. The ternary never fired.
/// The client then PUT `birth_year: ''` alongside `profileCompleted: true` and
/// relied on the server to reject it, which it does today. Leaning on a remote
/// validator to catch your own malformed payload only works until that rule is
/// relaxed.
library;

/// The three stored birth fields, or null when [raw] does not carry a date.
///
/// Returns null rather than empty strings so a caller cannot accidentally treat
/// "no date" as a valid value — the exact mistake above.
({String year, String month, String day})? parseBirthDateParts(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  final parts = trimmed.split('.');
  if (parts.length != 3) return null;

  final year = parts[0].trim();
  final month = parts[1].trim();
  final day = parts[2].trim();
  if (year.isEmpty || month.isEmpty || day.isEmpty) return null;

  // Digits only. A non-numeric year reaches the server as a string it stores
  // happily and `ageFrom` can never parse, which is worse than a rejection
  // because it looks like a real value.
  final numeric = RegExp(r'^\d+$');
  if (!numeric.hasMatch(year) ||
      !numeric.hasMatch(month) ||
      !numeric.hasMatch(day)) {
    return null;
  }

  final y = int.parse(year);
  final m = int.parse(month);
  final d = int.parse(day);
  if (y < 1900 || y > 2200) return null;
  if (m < 1 || m > 12) return null;
  if (d < 1 || d > 31) return null;

  return (year: year, month: month, day: day);
}
