import 'dart:async';

import 'package:bananatalk_app/utils/null_log_trap.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('debugPrint(null) is followed by a line naming the caller', () {
    final lines = <String?>[];
    final trapped = wrapDebugPrint((String? m, {int? wrapWidth}) => lines.add(m));

    trapped(null);

    expect(lines, hasLength(2));
    expect(lines[0], isNull);
    expect(lines[1], startsWith(kNullLogTag));
    expect(lines[1], contains('null_log_trap_test.dart'));
  });

  test('the literal string "null" is trapped too', () {
    final lines = <String?>[];
    final trapped = wrapDebugPrint((String? m, {int? wrapWidth}) => lines.add(m));
    trapped('null');
    expect(lines.last, startsWith(kNullLogTag));
  });

  test('ordinary messages pass through untouched', () {
    final lines = <String?>[];
    final trapped = wrapDebugPrint((String? m, {int? wrapWidth}) => lines.add(m));
    trapped('🎯 Provider: hello');
    expect(lines, ['🎯 Provider: hello']);
  });

  test('print(null) inside the trap zone is followed by the caller line', () {
    final lines = <String>[];
    runZoned(
      () => runZoned(
        // ignore: avoid_print
        () => print(null),
        zoneSpecification: nullPrintZone(),
      ),
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) => lines.add(line),
      ),
    );
    expect(lines.first, 'null');
    expect(lines[1], startsWith(kNullLogTag));
    expect(lines[1], contains('null_log_trap_test.dart'));
  });

  test('callerFrame skips dart: and flutter frames', () {
    final frame = callerFrame(StackTrace.fromString(
      '#0 foo (dart:core/print.dart:1)\n'
      '#1 bar (package:flutter/src/foundation/print.dart:2)\n'
      '#2 baz (package:dio/src/log.dart:150:5)\n',
    ));
    expect(frame, contains('package:dio/src/log.dart:150'));
  });
}
