import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/community/gathering_model.dart';
import 'package:bananatalk_app/pages/community/gatherings/gathering_detail_screen.dart';
import 'package:bananatalk_app/services/gathering_api_client.dart';

/// "Ask to join" on an approval gathering, leave, reopen: the server says
/// `viewerRequestPending: true`, so the screen must show the pending state
/// (and a way to withdraw), not "Ask to join" again.
class _FakeApi extends GatheringApiClient {
  _FakeApi(this.gathering);

  Gathering gathering;
  int cancels = 0;

  @override
  Future<Gathering?> getGathering(String id) async => gathering;

  @override
  Future<GatheringResult<Gathering>> cancelRsvp(String id) async {
    cancels++;
    gathering = gathering.copyWith(viewerRequestPending: false);
    return GatheringResult<Gathering>.ok(gathering);
  }
}

Gathering _approvalGathering({required bool pending}) => Gathering.fromJson({
      '_id': 'g1',
      'title': 'Korean evening',
      'startsAt': DateTime.now().add(const Duration(days: 2)).toIso8601String(),
      'joinMode': 'approval',
      'host': {'_id': 'h1', 'name': 'Anna'},
      'viewerRequestPending': pending,
    });

Widget _app(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

void main() {
  test('viewerRequestPending is parsed', () {
    expect(_approvalGathering(pending: true).viewerRequestPending, isTrue);
    expect(_approvalGathering(pending: false).viewerRequestPending, isFalse);
  });

  testWidgets('a pending request shows as pending and can be withdrawn',
      (tester) async {
    final api = _FakeApi(_approvalGathering(pending: true));
    await tester.pumpWidget(
        _app(GatheringDetailScreen(gatheringId: 'g1', apiClient: api)));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('gathering-request-pending')), findsOneWidget);
    expect(find.text('Ask to join'), findsNothing);

    await tester.ensureVisible(
        find.byKey(const Key('gathering-withdraw-request')));
    await tester.tap(find.byKey(const Key('gathering-withdraw-request')));
    await tester.pumpAndSettle();

    expect(api.cancels, 1);
    expect(find.text('Ask to join'), findsOneWidget);
  });

  testWidgets('no request yet: Ask to join', (tester) async {
    final api = _FakeApi(_approvalGathering(pending: false));
    await tester.pumpWidget(
        _app(GatheringDetailScreen(gatheringId: 'g1', apiClient: api)));
    await tester.pumpAndSettle();
    expect(find.text('Ask to join'), findsOneWidget);
    expect(find.byKey(const Key('gathering-request-pending')), findsNothing);
  });
}
