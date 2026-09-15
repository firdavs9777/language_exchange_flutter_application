import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/settings/deletion_reason_picker.dart';

/// ~130 accounts a month are deleted deliberately, most within an hour of
/// signing up, and nothing recorded why. One optional tap on the way out turns
/// that into evidence.
///
/// Optional is the whole contract: a user who wants to leave must never be
/// blocked, slowed, or argued with. Nothing is preselected, nothing is
/// required, and the picker never gates the delete button.
Widget _host({
  String? selected,
  ValueChanged<String?>? onChanged,
  ValueChanged<String>? onTextChanged,
}) =>
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: DeletionReasonPicker(
            selected: selected,
            onChanged: onChanged ?? (_) {},
            onTextChanged: onTextChanged ?? (_) {},
          ),
        ),
      ),
    );

void main() {
  testWidgets('offers every reason the server accepts', (tester) async {
    await tester.pumpWidget(_host());
    for (final code in kDeletionReasons) {
      expect(find.byKey(Key('deletion-reason-$code')), findsOneWidget,
          reason: 'missing chip for $code');
    }
  });

  testWidgets('nothing is preselected — leaving must not require an answer',
      (tester) async {
    await tester.pumpWidget(_host());
    expect(find.byKey(const Key('deletion-reason-text')), findsNothing);
  });

  testWidgets('choosing a reason reports its code', (tester) async {
    String? got = 'untouched';
    await tester.pumpWidget(_host(onChanged: (v) => got = v));
    await tester.tap(find.byKey(const Key('deletion-reason-no_people')));
    await tester.pump();
    expect(got, 'no_people');
  });

  testWidgets('tapping the chosen reason again clears it', (tester) async {
    String? got = 'untouched';
    await tester.pumpWidget(
      _host(selected: 'bugs', onChanged: (v) => got = v),
    );
    await tester.tap(find.byKey(const Key('deletion-reason-bugs')));
    await tester.pump();
    expect(got, isNull, reason: 'an answer given by accident must be retractable');
  });

  testWidgets('only "other" asks for free text', (tester) async {
    await tester.pumpWidget(_host(selected: 'privacy'));
    expect(find.byKey(const Key('deletion-reason-text')), findsNothing);

    await tester.pumpWidget(_host(selected: 'other'));
    await tester.pump();
    expect(find.byKey(const Key('deletion-reason-text')), findsOneWidget);
  });

  testWidgets('typed text is reported', (tester) async {
    var got = '';
    await tester.pumpWidget(_host(selected: 'other', onTextChanged: (v) => got = v));
    await tester.enterText(
        find.byKey(const Key('deletion-reason-text')), 'it kept crashing');
    await tester.pump();
    expect(got, 'it kept crashing');
  });

  testWidgets('the free-text field is bounded like the server field',
      (tester) async {
    await tester.pumpWidget(_host(selected: 'other'));
    // The key sits on the TextField itself, not on a wrapper.
    final field = tester.widget<TextField>(
      find.byKey(const Key('deletion-reason-text')),
    );
    expect(field.maxLength, kDeletionReasonMaxLength);
  });
}
