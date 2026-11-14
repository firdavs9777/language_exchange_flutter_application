import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/services/product_query_gate.dart';

/// The purchase services are static classes that need the platform channel
/// (and `Platform.isIOS`/`isAndroid`), so they cannot be driven here. Their
/// retry decision and one-query-at-a-time rule are these two small pieces,
/// which both services call.
void main() {
  group('storeNeedsProductQuery (the initializeStore short-circuit)', () {
    test('an empty product result is queried again; a non-empty one is not',
        () {
      expect(
          storeNeedsProductQuery(
              available: true, subscribed: true, hasProducts: false),
          isTrue);
      expect(
          storeNeedsProductQuery(
              available: true, subscribed: true, hasProducts: true),
          isFalse);
    });

    test('not yet available or not yet subscribed still initializes', () {
      expect(
          storeNeedsProductQuery(
              available: false, subscribed: true, hasProducts: true),
          isTrue);
      expect(
          storeNeedsProductQuery(
              available: true, subscribed: false, hasProducts: true),
          isTrue);
    });
  });

  group('SingleFlight (loadProducts)', () {
    test('two loadProducts calls during one query share it', () async {
      final flight = SingleFlight<void>();
      final gate = Completer<void>();
      var queries = 0;
      Future<void> query() {
        queries++;
        return gate.future;
      }

      final first = flight.run(query);
      final second = flight.run(query);
      expect(identical(first, second), isTrue);
      expect(queries, 1);
      gate.complete();
      await Future.wait([first, second]);
      expect(queries, 1);
    });

    test('after a query ends the next call queries again', () async {
      final flight = SingleFlight<void>();
      var queries = 0;
      Future<void> query() async => queries++;
      await flight.run(query);
      await flight.run(query);
      expect(queries, 2);
    });

    test('a failed query is not kept: the next call queries again', () async {
      final flight = SingleFlight<void>();
      var queries = 0;
      Future<void> query() async {
        queries++;
        if (queries == 1) throw StateError('store down');
      }

      await expectLater(flight.run(query), throwsStateError);
      await flight.run(query);
      expect(queries, 2);
    });
  });

  test('reset forgets a hung query so the next session queries again',
      () async {
    final flight = SingleFlight<void>();
    final hung = Completer<void>();
    var queries = 0;
    unawaited(flight.run(() {
      queries++;
      return hung.future;
    }));
    flight.reset();
    await flight.run(() async => queries++);
    expect(queries, 2);
    hung.complete(); // the old run finishing late changes nothing
    await Future<void>.delayed(Duration.zero);
    await flight.run(() async => queries++);
    expect(queries, 3);
  });
}
