import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/community/widgets/partner_segment_chips.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
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
  notifierRaceTests();
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

class _FakeService implements CommunityService {
  final calls = <Completer<PaginatedCommunityResponse>>[];
  final params = <String?>[];

  @override
  Future<PaginatedCommunityResponse> getCommunityPaginated({
    int page = 1,
    int limit = 20,
    String? nativeLanguage,
    String? learningLanguage,
    bool matchLanguage = false,
    String? gender,
    int? minAge,
    int? maxAge,
    bool? onlineOnly,
    String? country,
    String? languageLevel,
    String? search,
    String? sort,
    bool reciprocal = false,
    String? activeWithin,
    String? joinedWithin,
  }) {
    params.add(activeWithin ?? joinedWithin);
    final c = Completer<PaginatedCommunityResponse>();
    calls.add(c);
    return c.future;
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

PaginatedCommunityResponse _resp(String id) => PaginatedCommunityResponse(
      users: [Community.fromJson({'_id': id, 'name': id})],
      total: 1,
      page: 1,
      pages: 1,
      hasMore: false,
    );

void notifierRaceTests() {
  test('filters switched mid-load: stale response never lands', () async {
    final svc = _FakeService();
    final n = PartnerFilterNotifier(svc, () => false);
    const a = PartnerFilterParams(activeWithin: '7d');
    const b = PartnerFilterParams(joinedWithin: '7d');

    final fa = n.loadWithFilters(a);
    final fb = n.loadWithFilters(b); // must NOT be dropped
    expect(svc.calls.length, 2);
    expect(n.state.filters, b);
    expect(n.state.isLoading, true);

    svc.calls[0].complete(_resp('A'));
    await fa;
    expect(n.state.users, isEmpty); // A's rows discarded
    expect(n.state.isLoading, true);

    svc.calls[1].complete(_resp('B'));
    await fb;
    expect(n.state.users.map((u) => u.id), ['B']);
    expect(n.state.isLoading, false);
    expect(n.state.filters, b);
  });

  test('same filters while loading is still deduped', () async {
    final svc = _FakeService();
    final n = PartnerFilterNotifier(svc, () => false);
    const a = PartnerFilterParams(activeWithin: '7d');
    final f1 = n.loadWithFilters(a);
    await n.loadWithFilters(a);
    expect(svc.calls.length, 1);
    svc.calls[0].complete(_resp('A'));
    await f1;
  });

  test('segment switched mid-loadMore: stale page dropped', () async {
    final svc = _FakeService();
    final n = PartnerFilterNotifier(svc, () => false);
    const a = PartnerFilterParams(activeWithin: '7d');
    const b = PartnerFilterParams(joinedWithin: '7d');
    final f1 = n.loadWithFilters(a);
    svc.calls[0].complete(PaginatedCommunityResponse(
      users: [Community.fromJson({'_id': 'A1', 'name': 'A1'})],
      total: 2, page: 1, pages: 2, hasMore: true,
    ));
    await f1;
    final fm = n.loadMore();
    final fb = n.loadWithFilters(b);
    svc.calls[1].complete(_resp('A2'));
    await fm;
    expect(n.state.users, isEmpty);
    expect(n.state.filters, b);
    svc.calls[2].complete(_resp('B'));
    await fb;
    expect(n.state.users.map((u) => u.id), ['B']);
  });

  testWidgets('every segment chip has a >=44px touch target', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(_wrap(container));
    for (final label in ['All', '🔥 Serious learners', '🌱 New members']) {
      final target = find.ancestor(
          of: find.text(label), matching: find.byType(GestureDetector)).first;
      expect(tester.getSize(target).height, greaterThanOrEqualTo(44), reason: label);
    }
  });
}
