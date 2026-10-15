import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/moments/widgets/moment_prompt_label.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';

Widget _host(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: SizedBox(width: 320, child: child))),
    );

void main() {
  testWidgets('shows "Answering: {emoji} {text}"', (tester) async {
    await tester.pumpWidget(_host(const MomentPromptLabel(
      prompt: MomentPrompt(id: 'p1', text: 'Your favourite food?', emoji: '🍜'),
    )));
    await tester.pumpAndSettle();
    expect(find.text('Answering: 🍜 Your favourite food?'), findsOneWidget);
  });

  testWidgets('renders nothing without a prompt', (tester) async {
    await tester.pumpWidget(_host(const MomentPromptLabel(prompt: null)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('moment-prompt-label')), findsNothing);
  });
}
