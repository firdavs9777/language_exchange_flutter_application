import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
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

  group('serverMessageOf', () {
    test('keeps a sentence our backend wrote, minus the Exception prefix', () {
      expect(
        serverMessageOf(Exception('You already reported this user')),
        'You already reported this user',
      );
    });

    test('reads message or error out of a decoded body', () {
      expect(serverMessageOf({'message': 'This club is full'}),
          'This club is full');
      expect(serverMessageOf({'success': false, 'error': 'Name is too long'}),
          'Name is too long');
    });

    test('drops a re-wrapped exception chain', () {
      expect(
        serverMessageOf(Exception('Failed to update: Exception: boom')),
        isNull,
      );
    });

    test('drops a JSON blob', () {
      expect(
        serverMessageOf(Exception('{"success":false,"error":"x"}')),
        isNull,
      );
    });

    test('drops type errors and stack-ish text', () {
      expect(
        serverMessageOf(
          "type 'Null' is not a subtype of type 'String' in type cast",
        ),
        isNull,
      );
      expect(serverMessageOf('Null check operator used on a null value'),
          isNull);
      expect(serverMessageOf(StateError('Bad state')), isNull);
      expect(serverMessageOf(const FormatException('Unexpected character')),
          isNull);
      expect(serverMessageOf(Exception('Instance of _ClientSocket')), isNull);
    });

    test('drops an HTML error page', () {
      expect(serverMessageOf('<html><body>502 Bad Gateway</body></html>'),
          isNull);
    });

    test('null and empty give null', () {
      expect(serverMessageOf(null), isNull);
      expect(serverMessageOf(Exception('')), isNull);
    });
  });

  group('friendlyErrorMessage', () {
    final l10n = lookupAppLocalizations(const Locale('en'));

    test('offline beats everything, even a fallback', () {
      expect(
        friendlyErrorMessage(
          l10n,
          Exception('Failed: SocketException: Failed host lookup'),
          fallback: 'x',
        ),
        l10n.noInternetConnection,
      );
    });

    test('a clean server sentence is shown as-is', () {
      expect(
        friendlyErrorMessage(l10n, Exception('This club is full')),
        'This club is full',
      );
    });

    test('opaque text becomes the generic message', () {
      expect(
        friendlyErrorMessage(l10n, Exception('Failed to update: 500')),
        l10n.somethingWentWrong,
      );
    });

    test('an explicit fallback wins over guessing', () {
      expect(
        friendlyErrorMessage(l10n, Exception('This club is full'),
            fallback: 'Could not follow'),
        'Could not follow',
      );
    });

    test('a prefix frames a server sentence and stands in for opaque text',
        () {
      expect(
        friendlyErrorMessage(l10n, Exception('Name is too long'),
            prefix: 'Failed to update'),
        'Failed to update: Name is too long',
      );
      expect(
        friendlyErrorMessage(l10n, Exception('Failed: {"a":1}'),
            prefix: 'Failed to update'),
        'Failed to update',
      );
      expect(
        friendlyErrorMessage(l10n, const SocketException('x'),
            prefix: 'Failed to update'),
        l10n.noInternetConnection,
      );
    });
  });
}
