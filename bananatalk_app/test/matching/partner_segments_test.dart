import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/community/widgets/partner_segment_chips.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';

Widget _wrap(ProviderContainer container) => UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: PartnerSegmentChips()),
      ),
    );

void main() {
  test('PartnerFilterParams equality/copyWith include segment fields', () {
    expect(const PartnerFilterParams(activeWithin: '7d'),
        isNot(const PartnerFilterParams()));
    expect(const PartnerFilterParams(joinedWithin: '7d'),
        isNot(const PartnerFilterParams()));
    expect(const PartnerFilterParams(reciprocal: true),
        isNot(const PartnerFilterParams()));
    expect(const PartnerFilterParams(activeWithin: '7d'),
        const PartnerFilterParams(activeWithin: '7d'));
    expect(const PartnerFilterParams(activeWithin: '7d').hashCode,
        isNot(const PartnerFilterParams().hashCode));
    final c = const PartnerFilterParams().copyWith(joinedWithin: '7d');
    expect(c.joinedWithin, '7d');
  });

  test('segment maps to filter params', () {
    expect(PartnerSegment.all.activeWithin, isNull);
    expect(PartnerSegment.all.joinedWithin, isNull);
    expect(PartnerSegment.serious.activeWithin, '7d');
    expect(PartnerSegment.serious.joinedWithin, isNull);
    expect(PartnerSegment.newMembers.joinedWithin, '7d');
    expect(PartnerSegment.newMembers.activeWithin, isNull);
  });

  testWidgets('chip taps update segment state, mutually exclusive, hint shown',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(_wrap(container));

    expect(container.read(partnerSegmentProvider), PartnerSegment.all);
    expect(find.text('Complete profile · active this week · replies to messages'),
        findsNothing);

    await tester.tap(find.text('🔥 Serious learners'));
    await tester.pump();
    expect(container.read(partnerSegmentProvider), PartnerSegment.serious);
    expect(find.text('Complete profile · active this week · replies to messages'),
        findsOneWidget);

    await tester.tap(find.text('🌱 New members'));
    await tester.pump();
    expect(container.read(partnerSegmentProvider), PartnerSegment.newMembers);
    expect(find.text('Joined in the last 7 days'), findsOneWidget);

    await tester.tap(find.text('All'));
    await tester.pump();
    expect(container.read(partnerSegmentProvider), PartnerSegment.all);
  });
}
