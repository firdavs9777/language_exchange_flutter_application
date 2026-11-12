import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/pages/settings/data_storage_screen.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:bananatalk_app/services/interest_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeInterestService extends InterestService {
  _FakeInterestService(this.result);
  final Future<bool> Function() result;
  int calls = 0;

  @override
  Future<bool> clear() {
    calls++;
    return result();
  }
}

AppConfig _config({required bool interests}) => AppConfig(
  minVersion: '1.0.0',
  latestVersion: '1.0.0',
  forceUpdate: false,
  iosUrl: '',
  androidUrl: '',
  releaseNotes: '',
  interestRankingEnabled: interests,
);

Widget _app({
  required bool flag,
  required InterestService service,
  required void Function() onInvalidate,
}) => ProviderScope(
  overrides: [
    appConfigProvider.overrideWith((ref) async => _config(interests: flag)),
  ],
  child: MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: DataStorageScreen(
      interestService: service,
      onInterestsCleared: (_) => onInvalidate(),
    ),
  ),
);

AppLocalizations _l10n(WidgetTester t) =>
    AppLocalizations.of(t.element(find.byType(DataStorageScreen)))!;

/// The screen has a repeating animation, so pumpAndSettle never returns.
Future<void> _settle(WidgetTester t) async {
  for (var i = 0; i < 4; i++) {
    // Real async work (prefs, plugin channels) only advances outside FakeAsync.
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await t.pump(const Duration(milliseconds: 300));
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'token': 'tok'});
    // StorageService reads the temp dir with real file IO, which never
    // settles under FakeAsync; a failing channel makes it fall back at once.
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => throw PlatformException(code: 'unavailable'),
    );
  });

  group('InterestService', () {
    test('DELETEs auth/users/me/interests with the bearer token', () async {
      late http.Request seen;
      final service = InterestService(
        client: MockClient((req) async {
          seen = req;
          return http.Response('{"success":true}', 200);
        }),
      );
      expect(await service.clear(), isTrue);
      expect(seen.method, 'DELETE');
      expect(
        seen.url.toString(),
        '${Endpoints.baseURL}auth/users/me/interests',
      );
      expect(seen.headers['Authorization'], 'Bearer tok');
    });

    test('false on a non-2xx answer and on a network error', () async {
      expect(
        await InterestService(
          client: MockClient((_) async => http.Response('{}', 500)),
        ).clear(),
        isFalse,
      );
      expect(
        await InterestService(
          client: MockClient((_) async => throw Exception('offline')),
        ).clear(),
        isFalse,
      );
    });
  });

  group('DataStorageScreen clear interests row', () {
    testWidgets('flag off: no row', (t) async {
      final svc = _FakeInterestService(() async => true);
      await t.pumpWidget(_app(flag: false, service: svc, onInvalidate: () {}));
      await _settle(t);
      expect(find.text(_l10n(t).clearInterestsTitle), findsNothing);
    });

    testWidgets('flag on: confirm, service once, success snackbar, feeds invalidated', (t) async {
      final svc = _FakeInterestService(() async => true);
      var invalidated = 0;
      await t.pumpWidget(
        _app(flag: true, service: svc, onInvalidate: () => invalidated++),
      );
      await _settle(t);
      final l10n = _l10n(t);
      await t.scrollUntilVisible(
        find.text(l10n.clearInterestsTitle),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(l10n.clearInterestsSubtitle), findsOneWidget);
      await t.tap(find.text(l10n.clearInterestsTitle));
      await _settle(t);
      expect(find.text(l10n.clearInterestsConfirm), findsOneWidget);
      expect(svc.calls, 0);

      await t.tap(find.text(l10n.clearInterestsAction));
      await _settle(t);
      expect(svc.calls, 1);
      expect(invalidated, 1);
      expect(find.text(l10n.clearInterestsDone), findsOneWidget);
    });

    testWidgets('cancel does nothing', (t) async {
      final svc = _FakeInterestService(() async => true);
      await t.pumpWidget(_app(flag: true, service: svc, onInvalidate: () {}));
      await _settle(t);
      final l10n = _l10n(t);
      await t.scrollUntilVisible(
        find.text(l10n.clearInterestsTitle),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await t.tap(find.text(l10n.clearInterestsTitle));
      await _settle(t);
      await t.tap(find.text(l10n.cancel));
      await _settle(t);
      expect(svc.calls, 0);
    });

    testWidgets('failure: error snackbar, no invalidation', (t) async {
      final svc = _FakeInterestService(() async => false);
      var invalidated = 0;
      await t.pumpWidget(
        _app(flag: true, service: svc, onInvalidate: () => invalidated++),
      );
      await _settle(t);
      final l10n = _l10n(t);
      await t.scrollUntilVisible(
        find.text(l10n.clearInterestsTitle),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await t.tap(find.text(l10n.clearInterestsTitle));
      await _settle(t);
      await t.tap(find.text(l10n.clearInterestsAction));
      await _settle(t);
      expect(svc.calls, 1);
      expect(invalidated, 0);
      expect(find.text(l10n.clearInterestsDone), findsNothing);
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
