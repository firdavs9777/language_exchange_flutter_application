import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/services/api_client.dart';
import 'package:bananatalk_app/services/coin_api_client.dart';

void main() {
  group('coinVerifyOutcome', () {
    test('a fresh credit', () {
      final r = ApiResponse(
        success: true,
        statusCode: 200,
        data: {'balance': 200, 'credited': 100, 'alreadyCredited': false},
      );
      expect(coinVerifyOutcome(r), CoinVerifyOutcome.credited);
      expect(coinVerifyOutcome(r).finishesPurchase, isTrue);
    });

    test('a replay the server had already credited is not "Coins added!"', () {
      final r = ApiResponse(
        success: true,
        statusCode: 200,
        data: {'balance': 200, 'credited': 0, 'alreadyCredited': true},
      );
      expect(coinVerifyOutcome(r), CoinVerifyOutcome.alreadyCredited);
      expect(coinVerifyOutcome(r).finishesPurchase, isTrue);
    });

    test('a receipt linked to another account is final: finish it', () {
      final r = ApiResponse(
        success: false,
        statusCode: 409,
        error: 'This purchase is already linked to another account.',
        errorCode: 'ALREADY_LINKED_TO_ANOTHER_ACCOUNT',
      );
      expect(coinVerifyOutcome(r), CoinVerifyOutcome.linkedToAnotherAccount);
      expect(coinVerifyOutcome(r).finishesPurchase, isTrue);
    });

    test('anything else is retryable: leave the purchase unfinished', () {
      for (final code in [400, 500, 503]) {
        final r = ApiResponse(success: false, statusCode: code, error: 'x');
        expect(coinVerifyOutcome(r), CoinVerifyOutcome.failed);
        expect(coinVerifyOutcome(r).finishesPurchase, isFalse);
      }
      // A 409 without the code is not ours to finish.
      final bare409 = ApiResponse(success: false, statusCode: 409);
      expect(coinVerifyOutcome(bare409), CoinVerifyOutcome.failed);
    });
  });
}
