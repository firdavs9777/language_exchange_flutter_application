import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/models/coin_transaction.dart';
import 'package:bananatalk_app/pages/community/widgets/wave_error_snackbar.dart';
import 'package:bananatalk_app/providers/coins_provider.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/services/api_client.dart';
import 'package:bananatalk_app/services/coin_api_client.dart';
import 'package:bananatalk_app/widgets/limit_exceeded_dialog.dart';

class _FakeCoinClient implements CoinApiClient {
  final unlocks = <String>[];

  @override
  Future<ApiResponse> unlock(String featureKey) async {
    unlocks.add(featureKey);
    return ApiResponse(success: true, statusCode: 200, data: const {});
  }

  @override
  Future<int> getBalance() async => 100;

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

AppConfig _config({required bool waveCap}) => AppConfig(
      minVersion: '0.0.0',
      latestVersion: '0.0.0',
      forceUpdate: false,
      iosUrl: '',
      androidUrl: '',
      releaseNotes: '',
      coinsEnabled: true,
      waveCapEnabled: waveCap,
    );

const _legacyText = 'Too many waves. Please slow down!';

Widget _harness({
  required bool waveCap,
  required _FakeCoinClient coins,
  required Future<void> Function() retry,
  String? code = 'wave_cap',
}) {
  return ProviderScope(
    overrides: [
      appConfigProvider.overrideWith((ref) async => _config(waveCap: waveCap)),
      userProvider.overrideWith((ref) => Completer<Community>().future),
      coinApiClientProvider.overrideWithValue(coins),
      coinUnlockCatalogProvider.overrideWith((ref) async => {
            'wave': const CoinUnlockEntry(featureKey: 'wave', cost: 10, grant: 1),
          }),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Consumer(
          builder: (context, ref, _) {
            // Resolve the config before the tap (the app has it long before
            // a wave can be sent).
            ref.watch(appConfigProvider);
            return ElevatedButton(
              onPressed: () => handleWaveError(
                context,
                ref,
                WaveSendException(_legacyText, statusCode: 429, code: code),
                retry: retry,
              ),
              child: const Text('wave'),
            );
          },
        ),
      ),
    ),
  );
}

void main() {
  final en = lookupAppLocalizations(const Locale('en'));

  group('waveErrorAction', () {
    final table = <(int?, bool, String?, WaveErrorAction)>[
      (429, true, 'wave_cap', WaveErrorAction.limitDialog),
      // Flag off: even a real cap body keeps today's message.
      (429, false, 'wave_cap', WaveErrorAction.legacyMessage),
      // Rate limiter / older server: no code -> legacy, never the dialog.
      (429, true, null, WaveErrorAction.legacyMessage),
      (429, false, null, WaveErrorAction.legacyMessage),
      (429, true, 'something_else', WaveErrorAction.legacyMessage),
      (400, true, 'wave_cap', WaveErrorAction.genericError),
      (400, false, null, WaveErrorAction.genericError),
      (403, true, null, WaveErrorAction.genericError),
      (500, true, null, WaveErrorAction.genericError),
      (null, false, null, WaveErrorAction.genericError),
      (null, true, 'wave_cap', WaveErrorAction.genericError),
    ];
    for (final row in table) {
      test('status=${row.$1} cap=${row.$2} code=${row.$3} -> ${row.$4.name}',
          () {
        expect(
          waveErrorAction(status: row.$1, waveCapEnabled: row.$2, code: row.$3),
          row.$4,
        );
      });
    }
  });

  group('featureKeyForUnlock', () {
    test('wave -> wave', () {
      expect(LimitExceededDialog.featureKeyForUnlock('wave'), 'wave');
      expect(LimitExceededDialog.featureKeyForUnlock('waves'), 'wave');
    });
    test('existing mappings unchanged', () {
      expect(LimitExceededDialog.featureKeyForUnlock('messages'), 'dm');
      expect(LimitExceededDialog.featureKeyForUnlock('moment'), 'moment');
      expect(LimitExceededDialog.featureKeyForUnlock('comments'), isNull);
      expect(LimitExceededDialog.featureKeyForUnlock('profileViews'), isNull);
    });
  });

  group('WaveSendException', () {
    test('toString is byte-identical to the old Exception(message)', () {
      expect(
        const WaveSendException(_legacyText, statusCode: 429).toString(),
        Exception(_legacyText).toString(),
      );
      expect(
        const WaveSendException('Failed to send wave').toString(),
        Exception('Failed to send wave').toString(),
      );
    });
    test('status is exposed; other errors carry none', () {
      expect(
        waveErrorStatus(const WaveSendException('x', statusCode: 429)),
        429,
      );
      expect(waveErrorStatus(Exception('x')), isNull);
    });
  });

  group('sendWave threads the body code into WaveSendException', () {
    Future<WaveSendException> sendWith(http.Response r) async {
      SharedPreferences.setMockInitialValues({});
      try {
        await http.runWithClient(
          () => CommunityService().sendWave(targetUserId: 'u1'),
          () => MockClient((_) async => r),
        );
      } on WaveSendException catch (e) {
        return e;
      }
      fail('expected WaveSendException');
    }

    http.Response json429(Map<String, dynamic> body) => http.Response(
        jsonEncode(body), 429,
        headers: {'content-type': 'application/json'});

    test('cap 429 -> status 429, code wave_cap, legacy text unchanged',
        () async {
      final e = await sendWith(json429({
        'success': false,
        'error': 'Daily wave limit reached (5).',
        'code': 'wave_cap',
      }));
      expect(e.statusCode, 429);
      expect(e.code, 'wave_cap');
      expect(e.toString(), 'Exception: $_legacyText');
    });

    test('rate-limiter 429 (no code) -> code null', () async {
      final e = await sendWith(
          json429({'success': false, 'error': 'Too many requests'}));
      expect(e.statusCode, 429);
      expect(e.code, isNull);
    });
  });

  group('AppConfig.waveCapEnabled', () {
    Map<String, dynamic> base() => {
          'minVersion': '1.0.0',
          'latestVersion': '1.0.0',
          'forceUpdate': false,
          'iosUrl': '',
          'androidUrl': '',
          'releaseNotes': '',
        };
    test('defaults to false when absent', () {
      expect(AppConfig.fromJson(base()).waveCapEnabled, isFalse);
    });
    test('reads true', () {
      expect(
        AppConfig.fromJson({...base(), 'waveCapEnabled': true}).waveCapEnabled,
        isTrue,
      );
    });
  });

  testWidgets('cap off: a wave 429 shows the legacy text, no dialog',
      (tester) async {
    var retries = 0;
    final coins = _FakeCoinClient();
    await tester.pumpWidget(_harness(
      waveCap: false,
      coins: coins,
      retry: () async => retries++,
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('wave'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(_legacyText), findsOneWidget);
    expect(find.byType(LimitExceededDialog), findsNothing);
    expect(retries, 0);
  });

  testWidgets(
      'cap on: a wave 429 opens the wave limit dialog; coin unlock retries once',
      (tester) async {
    var retries = 0;
    final coins = _FakeCoinClient();
    await tester.pumpWidget(_harness(
      waveCap: true,
      coins: coins,
      retry: () async => retries++,
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('wave'));
    await tester.pumpAndSettle();
    expect(find.byType(LimitExceededDialog), findsOneWidget);
    expect(find.text(en.waveLimitTitle), findsOneWidget);
    expect(find.text(en.waveLimitBody), findsOneWidget);
    final cta = find.text(en.unlockGrantForCoins(1, 10));
    expect(cta, findsOneWidget);

    await tester.tap(cta);
    await tester.pumpAndSettle();
    expect(coins.unlocks, ['wave']);
    expect(find.byType(LimitExceededDialog), findsNothing);
    expect(retries, 1);
  });

  testWidgets('cap on: a limiter 429 (no wave_cap code) keeps the legacy text',
      (tester) async {
    var retries = 0;
    await tester.pumpWidget(_harness(
      waveCap: true,
      coins: _FakeCoinClient(),
      retry: () async => retries++,
      code: null,
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('wave'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(_legacyText), findsOneWidget);
    expect(find.byType(LimitExceededDialog), findsNothing);
    expect(retries, 0);
  });

  testWidgets('cap on: dismissing with Maybe Later does not retry',
      (tester) async {
    var retries = 0;
    await tester.pumpWidget(_harness(
      waveCap: true,
      coins: _FakeCoinClient(),
      retry: () async => retries++,
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('wave'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(en.maybeLater));
    await tester.pumpAndSettle();
    expect(find.byType(LimitExceededDialog), findsNothing);
    expect(retries, 0);
  });
}
