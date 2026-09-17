import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/community/single/avatar_action_sheet.dart';

Widget _host(void Function(BuildContext) onReady) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => onReady(context),
            child: const Text('open'),
          ),
        ),
      ),
    );

void main() {
  testWidgets('both options are offered', (tester) async {
    await tester.pumpWidget(_host((c) => showAvatarActionSheet(c)));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('avatar-action-story')), findsOneWidget);
    expect(find.byKey(const Key('avatar-action-photo')), findsOneWidget);
  });

  testWidgets('choosing the story returns AvatarAction.story', (tester) async {
    AvatarAction? chosen;
    await tester.pumpWidget(_host((c) async {
      chosen = await showAvatarActionSheet(c);
    }));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('avatar-action-story')));
    await tester.pumpAndSettle();
    expect(chosen, AvatarAction.story);
  });

  testWidgets('choosing the photo returns AvatarAction.photo', (tester) async {
    AvatarAction? chosen;
    await tester.pumpWidget(_host((c) async {
      chosen = await showAvatarActionSheet(c);
    }));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('avatar-action-photo')));
    await tester.pumpAndSettle();
    expect(chosen, AvatarAction.photo);
  });

  testWidgets('dismissing returns null, and the caller must do nothing',
      (tester) async {
    AvatarAction? chosen = AvatarAction.story;
    var completed = false;
    await tester.pumpWidget(_host((c) async {
      chosen = await showAvatarActionSheet(c);
      completed = true;
    }));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Tap the scrim above the sheet.
    await tester.tapAt(const Offset(200, 60));
    await tester.pumpAndSettle();

    expect(completed, isTrue);
    expect(chosen, isNull, reason: 'a dismissed sheet must not pick for the user');
  });

  testWidgets('the labels are translated, not raw keys', (tester) async {
    await tester.pumpWidget(_host((c) => showAvatarActionSheet(c)));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('View story'), findsOneWidget);
    expect(find.text('See profile photo'), findsOneWidget);
  });
}
