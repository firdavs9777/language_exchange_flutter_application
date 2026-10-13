import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/services/call/call_routes.dart';

void main() {
  testWidgets('the not-sent notice is a short localized snackbar', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      })),
    ));
    CallRoutes.showDeclineMessageNotSent(ctx);
    await tester.pump();
    expect(find.text('Failed to send message'), findsOneWidget);
  });

  testWidgets('no messenger (no context): nothing happens, no throw', (tester) async {
    CallRoutes.showDeclineMessageNotSent(null);
    expect(tester.takeException(), isNull);
  });
}
