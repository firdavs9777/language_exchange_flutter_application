import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/community/tabs/partner_discovery_tab.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/block_provider.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Final review (2026-10-31): a chip tap empties the list while page 1
/// loads, and loading / error rendered without the chip rows -- the row
/// vanished after the first tap and a failing chip could only be retried,
/// never undone.
class _Fixed extends PartnerFilterNotifier {
  _Fixed(PartnerFilterState s) : super(CommunityService(), () => false) {
    state = s;
  }
  @override
  Future<void> loadWithFilters(PartnerFilterParams filters) async {}
  @override
  Future<void> loadMore({bool force = false}) async {}
}

Community _me() => Community.fromJson({
  '_id': 'me',
  'name': 'Me',
  'native_language': 'English',
  'language_to_learn': 'Korean',
  'location': {'type': 'Point', 'coordinates': [0, 0], 'city': 'Seoul', 'country': 'Korea'},
});

Widget _host(PartnerFilterState state) => ProviderScope(
  overrides: [
    userProvider.overrideWith((ref) async => _me()),
    blockedUserIdsProvider.overrideWith((ref) async => <String>{}),
    partnerFilterProvider.overrideWith((ref) => _Fixed(state)),
  ],
  child: const MaterialApp(
    localizationsDelegates: [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: PartnerDiscoveryTab(filters: {}, searchQuery: '')),
  ),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'userId': 'me'}));

  testWidgets('chips stay while page 1 loads', (tester) async {
    await tester.pumpWidget(_host(const PartnerFilterState(isLoading: true)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Same city'), findsOneWidget);
  });

  testWidgets('chips stay when page 1 fails', (tester) async {
    await tester.pumpWidget(_host(const PartnerFilterState(error: 'boom')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Same city'), findsOneWidget);
  });
}
