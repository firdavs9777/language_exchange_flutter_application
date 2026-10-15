import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/pages/community/tabs/waves_tab.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';

class _FakeCommunity implements CommunityService {
  _FakeCommunity(this.waves);
  final List<Wave> waves;
  int calls = 0;
  @override
  Future<List<Wave>> getWavesReceived({
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
    bool archive = false,
    bool reveal = false,
  }) async {
    calls++;
    return waves;
  }

  @override
  Future<void> markWavesAsRead({List<String>? waveIds}) async {}
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

Widget _app(CommunityService community, {TextDirection? dir}) =>
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWith((ref) async => AppConfig(
              minVersion: '0.0.0',
              latestVersion: '0.0.0',
              forceUpdate: false,
              iosUrl: '',
              androidUrl: '',
              releaseNotes: '',
            )),
        communityServiceProvider.overrideWithValue(community),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: dir == null
            ? null
            : (context, child) =>
                Directionality(textDirection: dir, child: child!),
        home: Scaffold(body: WavesTab(primeNotifications: (_) async {})),
      ),
    );

void main() {
  testWidgets('empty inbox still offers the archive and pull-to-refresh',
      (tester) async {
    final fake = _FakeCommunity([]);
    await tester.pumpWidget(_app(fake));
    await tester.pumpAndSettle();
    expect(find.text('View archive'), findsOneWidget);
    expect(find.byType(RefreshIndicator), findsOneWidget);

    await tester.fling(
        find.byType(RefreshIndicator), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();
    expect(fake.calls, 2);
  });

  testWidgets('View archive sits at the trailing edge in RTL', (tester) async {
    await tester.pumpWidget(
        _app(_FakeCommunity([]), dir: TextDirection.rtl));
    await tester.pumpAndSettle();
    final button = tester.getRect(find.text('View archive'));
    final screen = tester.getRect(find.byType(Scaffold));
    // Trailing in RTL is the left half.
    expect(button.center.dx, lessThan(screen.center.dx));
  });
}
