/// Age from the split birthdate fields the API returns (`birth_year`,
/// `birth_month`, `birth_day`), all of which arrive as strings.
///
/// This is the app-side mirror of the backend's `lib/userAge.js` `ageFrom`,
/// and the two must stay in agreement: the server gates minors on its own
/// `isMinor`, so a client that rounds ages up would show a 17-year-old as 18.
/// Subtracting years alone — the thing this replaced — is wrong for everyone
/// whose birthday has not come round yet this year.
///
/// Returns null for an unknown, malformed or implausible birthdate rather
/// than guessing. Callers treat null as "age unknown", never as zero.
int? ageFrom(String birthYear, String birthMonth, String birthDay,
    {DateTime? now}) {
  final year = int.tryParse(birthYear.trim());
  final month = int.tryParse(birthMonth.trim());
  final day = int.tryParse(birthDay.trim());
  if (year == null || month == null || day == null) return null;
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;

  final today = now ?? DateTime.now();
  var age = today.year - year;
  // DateTime.month is 1-based in Dart, so unlike the JS original there is no
  // +1 correction here.
  final monthDiff = today.month - month;
  if (monthDiff < 0 || (monthDiff == 0 && today.day < day)) age -= 1;

  return age >= 0 && age < 130 ? age : null;
}
