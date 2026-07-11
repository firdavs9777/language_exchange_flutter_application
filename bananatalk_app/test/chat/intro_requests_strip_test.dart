import 'package:bananatalk_app/pages/chat/list/intro_requests_strip.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Wave _fakeWave({
  required String id,
  required String fromUserId,
  required String fromUserName,
  String? message,
}) {
  return Wave(
    id: id,
    fromUserId: fromUserId,
    fromUserName: fromUserName,
    fromUserImage: null,
    message: message,
    isRead: false,
    createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
  );
}

Widget harness(List<Override> overrides) {
  return ProviderScope(
    overrides: overrides,
    child: const MaterialApp(
      home: Scaffold(body: IntroRequestsStrip()),
    ),
  );
}

void main() {
  group('IntroRequestsStrip', () {
    testWidgets(
      'renders header, count chip, and one card per pending wave',
      (tester) async {
        final waves = [
          _fakeWave(
            id: 'w1',
            fromUserId: 'u1',
            fromUserName: 'Alice',
            message: 'Hi there!',
          ),
          _fakeWave(id: 'w2', fromUserId: 'u2', fromUserName: 'Bob'),
        ];

        await tester.pumpWidget(
          harness([
            pendingIntrosProvider.overrideWith((ref) async => waves),
          ]),
        );
        await tester.pump();
        await tester.pump();

        expect(find.text('Intro requests'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
        expect(find.text('Alice'), findsOneWidget);
        expect(find.text('Bob'), findsOneWidget);
        // Bob has no message -> falls back to the wave emoji preview.
        expect(find.text('👋'), findsOneWidget);
      },
    );

    testWidgets(
      'renders nothing when there are no pending intros',
      (tester) async {
        await tester.pumpWidget(
          harness([
            pendingIntrosProvider.overrideWith((ref) async => <Wave>[]),
          ]),
        );
        await tester.pump();
        await tester.pump();

        expect(find.text('Intro requests'), findsNothing);
        expect(find.byType(IntroRequestsStrip), findsOneWidget);

        final strip = tester.widget<Widget>(find.byType(IntroRequestsStrip));
        expect(strip, isA<IntroRequestsStrip>());

        // The strip's own subtree should collapse to a zero-size SizedBox.
        final size = tester.getSize(find.byType(IntroRequestsStrip));
        expect(size.height, 0);
      },
    );
  });
}
