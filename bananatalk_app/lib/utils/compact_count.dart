/// Renders a cardinal count the way Instagram does: `999`, `1k`, `1.1k`,
/// `12.3k`, `999k`, `1m`.
///
/// Two rules make it look right rather than merely short:
///
///  * **No dead decimal.** Exactly 1000 is `1k`, not `1.0k`. This is the
///    single most visible flaw in the ten hand-rolled formatters this
///    replaces.
///  * **Truncate, never round up.** 999,999 renders `999k`; rounding would
///    produce the self-contradictory `1000k`. Truncation also means a
///    displayed count never overstates the real one.
///
/// One decimal appears only below 100 of a unit, where it carries real
/// information (`1.1k` vs `1k`, `12.3k` vs `123k`). At 100 and above the
/// decimal is dropped.
String formatCompactCount(int count) {
  // A count is a cardinality. A negative one means the server sent something
  // impossible, and "-5 likes" is a worse answer than "0".
  if (count <= 0) return '0';
  if (count < 1000) return '$count';
  if (count < 1000000) return '${_unit(count, 1000)}k';
  return '${_unit(count, 1000000)}m';
}

/// Formats [count] in units of [divisor], keeping one truncated decimal only
/// while the whole part is below 100.
String _unit(int count, int divisor) {
  final whole = count ~/ divisor;
  final tenths = (count % divisor) * 10 ~/ divisor;

  // Truncate the tenth rather than rounding, so the result never crosses back
  // over the threshold it was just reduced below.
  if (whole < 100 && tenths != 0) {
    return '$whole.$tenths';
  }
  return '$whole';
}
