import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/models/coin_transaction.dart';
import 'package:bananatalk_app/providers/coins_provider.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/services/api_client.dart';
import 'package:bananatalk_app/services/coin_api_client.dart';
import 'package:bananatalk_app/widgets/coins/unlock_cta.dart';

/// "80 코인으로 3개 잠금 해제" with too few coins: the "not enough coins"
/// SnackBar showed on the screen UNDER the upgrade sheet (2026-10-17).
class _BrokeCoinApi extends CoinApiClient {
  @override
  Future<ApiResponse> unlock(String featureKey) async =>
      ApiResponse(success: false, statusCode: 402, error: 'Not enough coins');

  @override
  Future<int> getBalance() async => 10;
}

const _cfg = AppConfig(
  minVersion: '0',
  latestVersion: '0',
  forceUpdate: false,
  iosUrl: '',
  androidUrl: '',
  releaseNotes: '',
  coinsEnabled: true,
);

Widget _host(Widget home) => ProviderScope(
      overrides: [
        appConfigProvider.overrideWith((ref) async => _cfg),
        coinApiClientProvider.overrideWithValue(_BrokeCoinApi()),
        coinUnlockCatalogProvider.overrideWith((ref) async => const {
              'chat': CoinUnlockEntry(featureKey: 'chat', cost: 80, grant: 3),
            }),
        coinBalanceProvider.overrideWith((ref) async => 10),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );

void main() {
  testWidgets('inside a bottom sheet: not enough coins is a dialog on top',
      (tester) async {
    await tester.pumpWidget(_host(Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              builder: (_) => const Padding(
                padding: EdgeInsets.all(24),
                child: UnlockCta(featureKey: 'chat'),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(OutlinedButton));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('unlock-not-enough-coins')), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing, reason: 'a SnackBar would sit under the sheet');
    expect(find.text('Get more coins'), findsOneWidget);
  });

  testWidgets('on a plain screen it stays a SnackBar', (tester) async {
    await tester.pumpWidget(_host(const Scaffold(
      body: Center(child: UnlockCta(featureKey: 'chat')),
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(OutlinedButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.byKey(const Key('unlock-not-enough-coins')), findsNothing);
  });
}
