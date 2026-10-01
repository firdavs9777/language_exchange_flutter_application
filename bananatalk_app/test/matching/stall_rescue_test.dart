import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/widgets/chat/stall_rescue_banner.dart';

Community _user(String id) =>
    Community.fromJson({'_id': id, 'name': id, 'topics': <String>[]});

Message _msg(String from, DateTime at, {int n = 0}) => Message(
      id: 'm$n${at.microsecondsSinceEpoch}',
      sender: _user(from),
      receiver: _user(from == 'me' ? 'them' : 'me'),
      message: 'hi',
      createdAt: at.toUtc().toIso8601String(),
      version: 0,
      read: true,
    );

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  final now = DateTime.utc(2026, 10, 2, 12);

  group('shouldShowStallRescue', () {
    test('their last message 25h ago -> true', () {
      final msgs = [
        _msg('me', now.subtract(const Duration(hours: 30))),
        _msg('them', now.subtract(const Duration(hours: 25)), n: 1),
      ];
      expect(
          StallRescueBanner.shouldShowStallRescue(
              messages: msgs, myId: 'me', now: now),
          isTrue);
    });

    test('my message is last -> false', () {
      final msgs = [
        _msg('them', now.subtract(const Duration(hours: 40))),
        _msg('me', now.subtract(const Duration(hours: 30)), n: 1),
      ];
      expect(
          StallRescueBanner.shouldShowStallRescue(
              messages: msgs, myId: 'me', now: now),
          isFalse);
    });

    test('6 messages -> false', () {
      final msgs = [
        for (var i = 0; i < 6; i++)
          _msg('them', now.subtract(Duration(hours: 40 - i)), n: i),
      ];
      expect(
          StallRescueBanner.shouldShowStallRescue(
              messages: msgs, myId: 'me', now: now),
          isFalse);
    });

    test('2h ago -> false; empty -> false; bad date -> false', () {
      expect(
          StallRescueBanner.shouldShowStallRescue(
              messages: [_msg('them', now.subtract(const Duration(hours: 2)))],
              myId: 'me',
              now: now),
          isFalse);
      expect(
          StallRescueBanner.shouldShowStallRescue(
              messages: const [], myId: 'me', now: now),
          isFalse);
      final bad = Message(
        id: 'x',
        sender: _user('them'),
        receiver: _user('me'),
        message: 'hi',
        createdAt: 'garbage',
        version: 0,
        read: true,
      );
      expect(
          StallRescueBanner.shouldShowStallRescue(
              messages: [bad], myId: 'me', now: now),
          isFalse);
    });
  });

  group('StallRescueBanner widget', () {
    testWidgets('renders title, tap fills, dismiss hides', (tester) async {
      String? picked;
      var visible = true;
      await tester.pumpWidget(_wrap(StatefulBuilder(
        builder: (context, setState) => visible
            ? StallRescueBanner(
                name: 'Minji',
                suggestion: 'Sorry for the late reply!',
                onPick: (t) => picked = t,
                onDismiss: () => setState(() => visible = false),
              )
            : const SizedBox.shrink(),
      )));
      expect(find.text('Minji asked you something 👀'), findsOneWidget);
      await tester.tap(find.text('Sorry for the late reply!'));
      expect(picked, 'Sorry for the late reply!');
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(find.text('Minji asked you something 👀'), findsNothing);
    });
  });
}
