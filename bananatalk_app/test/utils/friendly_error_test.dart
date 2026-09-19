import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/utils/friendly_error.dart';

void main() {
  group('classifyError', () {
    test('a raw SocketException is offline', () {
      expect(
        classifyError(const SocketException('Failed host lookup')),
        ErrorKind.offline,
      );
    });

    test('a timeout is offline', () {
      expect(classifyError(TimeoutException('too slow')), ErrorKind.offline);
    });

    test('a socket failure re-wrapped as a string is still offline', () {
      // This is the shape that actually reaches the UI: services catch the
      // real exception and rethrow `Exception('Failed to load: $e')`, so the
      // type is long gone by the time a screen renders it.
      expect(
        classifyError(
          Exception(
            'Failed to load community: SocketException: Failed host lookup: '
            "'api.banatalk.com' (OS Error: nodename nor servname provided)",
          ),
        ),
        ErrorKind.offline,
      );
    });

    test('matching is case-insensitive', () {
      expect(
        classifyError('FAILED HOST LOOKUP: api.banatalk.com'),
        ErrorKind.offline,
      );
    });

    test('a server-side refusal is not offline', () {
      expect(
        classifyError(Exception('This club is full')),
        ErrorKind.unknown,
      );
    });

    test('null classifies rather than throwing', () {
      expect(classifyError(null), ErrorKind.unknown);
    });
  });
}
