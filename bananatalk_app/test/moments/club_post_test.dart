import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/l10n/app_localizations_en.dart';
import 'package:bananatalk_app/pages/moments/create/club_post.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';

/// Clubs v2 slice 3: a club post's privacy and stats, and how stats read.
void main() {
  final en = AppLocalizationsEn();

  test('a moment parses its club and activity; old payloads have neither', () {
    final m = Moments.fromJson({
      '_id': 'm1', 'description': 'tempo', 'privacy': 'club', 'club': 'c1',
      'activity': {'distanceM': 5200, 'durationS': 1860},
    });
    expect(m.clubId, 'c1');
    expect(m.activity!.distanceM, 5200);
    expect(m.activity!.durationS, 1860);
    final old = Moments.fromJson({'_id': 'm2', 'description': 'x'});
    expect(old.clubId, isNull);
    expect(old.activity, isNull);
    expect(m.copyWith(likeCount: 3).clubId, 'c1');
  });

  test('members-only unless shared; km and minutes become metres and seconds', () {
    final a = clubPostFields(shareToMoments: false, distanceKm: '5.2', timeMin: '31');
    expect(a.privacy, 'club');
    expect(a.activity, {'distanceM': 5200, 'durationS': 1860});
    final b = clubPostFields(shareToMoments: true, distanceKm: '', timeMin: '');
    expect(b.privacy, 'public');
    expect(b.activity, isNull);
    final c = clubPostFields(shareToMoments: false, distanceKm: '5,2', timeMin: 'abc');
    expect(c.activity, {'distanceM': 5200});
  });

  test('the stats line: distance, time and pace', () {
    expect(clubActivityLine(en, const MomentActivity(distanceM: 5200, durationS: 1860)),
        '5.2 km · 31:00 · 5:58/km');
    expect(clubActivityLine(en, const MomentActivity(distanceM: 10000)), '10 km');
    expect(clubActivityLine(en, const MomentActivity(durationS: 3725)), '1:02:05');
  });

  testWidgets('the options: share switch off by default, two stat fields', (tester) async {
    ClubPostOptionsValue? last;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: ClubPostOptions(onChanged: (v) => last = v)),
    ));
    expect(find.text(en.clubShareToMoments), findsOneWidget);
    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value, isFalse);
    await tester.enterText(find.byKey(const Key('club-activity-distance')), '5.2');
    await tester.enterText(find.byKey(const Key('club-activity-time')), '31');
    await tester.tap(find.byType(SwitchListTile));
    await tester.pump();
    expect(last!.shareToMoments, isTrue);
    expect(last!.distanceKm, '5.2');
    expect(last!.timeMin, '31');
  });
}
