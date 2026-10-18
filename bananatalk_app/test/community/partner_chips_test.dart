import 'package:bananatalk_app/l10n/app_localizations_en.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/widgets/community/partner_list_item.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Partners chips (2026-10-18): what you have in common first; no exact
/// recency or account age.
Community _user({
  String native = 'Korean',
  String learning = 'English',
  List<String> topics = const [],
  String city = '',
  bool online = false,
  DateTime? lastActive,
  int? responseRate,
  Map<String, dynamic>? privacy,
  String createdAt = '2026-10-10T00:00:00.000Z',
}) =>
    Community.fromJson({
      '_id': 'u',
      'name': 'Minji',
      'native_language': native,
      'language_to_learn': learning,
      'topics': topics,
      'location': {'type': 'Point', 'coordinates': [0, 0], 'city': city, 'country': 'Korea'},
      'isOnline': online,
      if (lastActive != null) 'lastActive': lastActive.toIso8601String(),
      if (responseRate != null) 'responseRate': responseRate,
      if (privacy != null) 'privacySettings': privacy,
      'createdAt': createdAt,
    });

void main() {
  final l10n = AppLocalizationsEn();
  final now = DateTime(2026, 10, 18, 12);
  final me = _user(native: 'English', learning: 'Korean', topics: ['travel', 'cooking'], city: 'Seoul');
  List<String> chips(Community u, {Community? viewer}) => partnerChipLabels(
        l10n, u, viewer ?? me, languageName: (s) => s, now: now,
      ).map((c) => c.text).toList();

  test('a perfect exchange, a shared interest and the same city come first', () {
    final u = _user(topics: ['cooking'], city: 'Seoul', responseRate: 90, online: true);
    final c = chips(u);
    expect(c.take(3), [
      l10n.matchReasonReciprocal,
      l10n.partnerTagBothLike('Cooking'),
      l10n.matchReasonSameCity,
    ]);
  });

  test('no "Joined Xd ago", and no exact "Active 3h ago"', () {
    final u = _user(lastActive: now.subtract(const Duration(hours: 3)));
    final c = chips(u, viewer: _user(native: 'French', learning: 'German'));
    expect(c, [l10n.matchReasonActiveToday]);
    expect(c.any((t) => t.contains('Joined')), isFalse);
  });

  test('activity hidden for someone who hides their online status', () {
    final u = _user(online: true, privacy: {'showOnlineStatus': false});
    expect(chips(u, viewer: _user(native: 'French', learning: 'German')), isEmpty);
  });

  test('same city only when the person shows their city', () {
    final hidden = _user(city: 'Seoul', privacy: {'showCity': false, 'showOnlineStatus': true});
    expect(chips(hidden).contains(l10n.matchReasonSameCity), isFalse);
  });

  test('one-sided fit says which side', () {
    expect(chips(_user(native: 'Korean', learning: 'Japanese')).first, l10n.partnerTagSpeaks('Korean'));
    expect(chips(_user(native: 'Japanese', learning: 'English')).first, l10n.partnerTagLearning('English'));
  });

  for (final locale in const [Locale('de'), Locale('ru'), Locale('en')]) {
    testWidgets('chips never overflow a 320-wide row ($locale)', (t) async {
      t.view.physicalSize = const Size(320, 800);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final u = _user(topics: ['cooking'], city: 'Seoul', responseRate: 95, online: true);
      await t.pumpWidget(MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: ListView(children: [PartnerListItem(user: u, currentUser: me)])),
      ));
      await t.pump();
      expect(t.takeException(), isNull);
    });
  }
}
