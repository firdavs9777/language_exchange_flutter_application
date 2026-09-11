import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/pages/learning/daily/widgets/check_question.dart';

const _check = PackCheck(
  prompt: 'She ___ to work every day.',
  options: ['go', 'goes', 'going'],
);

Widget _host({
  int? selected,
  int? correctIndex,
  ValueChanged<int>? onSelect,
  String? explanation,
}) =>
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: CheckQuestion(
          check: _check,
          index: 0,
          selected: selected,
          correctIndex: correctIndex,
          explanation: explanation,
          onSelect: onSelect ?? (_) {},
        ),
      ),
    );

void main() {
  testWidgets('renders the prompt and every option', (tester) async {
    await tester.pumpWidget(_host());
    expect(find.text('She ___ to work every day.'), findsOneWidget);
    for (final o in _check.options) {
      expect(find.text(o), findsOneWidget);
    }
  });

  testWidgets('tapping an option reports its index', (tester) async {
    int? picked;
    await tester.pumpWidget(_host(onSelect: (i) => picked = i));
    await tester.tap(find.byKey(const Key('check-q0-opt1')));
    await tester.pumpAndSettle();
    expect(picked, 1);
  });

  testWidgets('a correct answer is marked with an icon, not colour alone', (tester) async {
    await tester.pumpWidget(_host(selected: 1, correctIndex: 1));
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('a wrong answer marks both the choice and the right answer', (tester) async {
    await tester.pumpWidget(_host(selected: 0, correctIndex: 1));
    expect(find.byIcon(Icons.cancel), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('the explanation appears only after answering', (tester) async {
    await tester.pumpWidget(_host(explanation: 'Third person takes -s.'));
    expect(find.text('Third person takes -s.'), findsNothing);

    await tester.pumpWidget(
        _host(selected: 1, correctIndex: 1, explanation: 'Third person takes -s.'));
    expect(find.text('Third person takes -s.'), findsOneWidget);
  });

  testWidgets('options stop responding once answered', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(selected: 1, correctIndex: 1, onSelect: (_) => taps++));
    await tester.tap(find.byKey(const Key('check-q0-opt2')), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(taps, 0);
  });

  testWidgets('every option meets the 44pt minimum tap target', (tester) async {
    await tester.pumpWidget(_host());
    for (var i = 0; i < _check.options.length; i++) {
      final size = tester.getSize(find.byKey(Key('check-q0-opt$i')));
      expect(size.height, greaterThanOrEqualTo(44.0));
    }
  });

  testWidgets('stays legible at a 1.3 text scale', (tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: Scaffold(
          body: CheckQuestion(check: _check, index: 0, onSelect: (_) {}),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
    expect(find.text('goes'), findsOneWidget);
  });
}
