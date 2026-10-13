import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/services/call/call_api.dart';
import 'package:bananatalk_app/widgets/call/decline_message_sheet.dart';

void main() {
  testWidgets('custom message is limited in UTF-16 units, as the backend counts', (tester) async {
    String? result;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (ctx) => TextButton(
          onPressed: () async => result = await showDeclineMessageSheet(ctx),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    // 199 graphemes but 296 UTF-16 units: Flutter's maxLength would accept it.
    await tester.enterText(find.byType(TextField), '😀' * 99 + 'a' * 100);
    await tester.pump();
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text.length, lessThanOrEqualTo(kDeclineMessageMax));
    expect(field.controller!.text, '😀' * 99 + 'aa');
    await tester.tap(find.byType(TextButton).last);
    await tester.pumpAndSettle();
    expect(result!.length, lessThanOrEqualTo(kDeclineMessageMax));
  });
}
