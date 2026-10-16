import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';
import 'package:bananatalk_app/widgets/story/story_question_box_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SizedBox(height: 600, child: child)),
    );

void main() {
  testWidgets('a response with an unpopulated author gets a placeholder',
      (tester) async {
    final response = StoryQuestionResponse.fromJson({
      'user': '64f000000000000000000001',
      'text': 'hello there',
    });
    await tester.pumpWidget(
      _host(StoryQuestionResponsesList(responses: [response])),
    );
    await tester.pumpAndSettle();
    expect(find.text('hello there'), findsOneWidget);
    expect(find.text('Unknown'), findsOneWidget);
    expect(find.byKey(const Key('response-placeholder-avatar')), findsOneWidget);
  });

  testWidgets('a failed load shows an error with Retry', (tester) async {
    var retried = 0;
    await tester.pumpWidget(_host(StoryQuestionResponsesList(
      responses: const [],
      hasError: true,
      onRetry: () => retried++,
    )));
    await tester.pumpAndSettle();
    expect(find.text('Something went wrong'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(retried, 1);
  });
}
