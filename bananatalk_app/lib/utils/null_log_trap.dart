import 'dart:async';

import 'package:flutter/foundation.dart';

/// Debug-only locator for bare `flutter: null` console lines.
///
/// Nothing in lib/ prints a bare null (grepped 2026-10-12), so the line comes
/// from a dependency or an interpolation that evaluates to "null". When one is
/// printed, the trap prints a second line naming the first stack frame outside
/// dart: and package:flutter/ — the code that logged it.
const String kNullLogTag = '[null-log]';

bool _isBareNull(String? message) => message == null || message.trim() == 'null';

/// First frame that is not the SDK, Flutter's print plumbing or this file.
String? callerFrame(StackTrace stack) {
  for (final raw in stack.toString().split('\n')) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    if (line.contains('null_log_trap.dart')) continue;
    if (line.contains('(dart:') || line.contains('package:flutter/')) continue;
    return line;
  }
  return null;
}

String _report(String kind) =>
    '$kNullLogTag $kind from ${callerFrame(StackTrace.current) ?? 'unknown frame'}';

DebugPrintCallback wrapDebugPrint(DebugPrintCallback inner) {
  return (String? message, {int? wrapWidth}) {
    inner(message, wrapWidth: wrapWidth);
    if (_isBareNull(message)) inner(_report('debugPrint(null)'));
  };
}

ZoneSpecification nullPrintZone() => ZoneSpecification(
      print: (self, parent, zone, line) {
        parent.print(zone, line);
        if (_isBareNull(line)) parent.print(zone, _report('print(null)'));
      },
    );

/// Wraps [debugPrint] in debug builds; a no-op in profile/release.
void installNullLogTrap() {
  if (!kDebugMode) return;
  debugPrint = wrapDebugPrint(debugPrint);
}
