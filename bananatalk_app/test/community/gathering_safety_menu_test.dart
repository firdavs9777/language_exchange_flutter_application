import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/community/gatherings/gathering_safety_menu.dart';

Widget _host(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(appBar: AppBar(actions: [child])),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'userId': 'viewer-1'}));

  group('wire values', () {
    test('match the backend Report type enum exactly', () {
      // models/Report.js accepts "gathering" and "club". A rename here would
      // fail server-side validation with no client-visible clue.
      expect(SafetyTarget.gathering.wireValue, 'gathering');
      expect(SafetyTarget.club.wireValue, 'club');
    });
  });

  group('visibility', () {
    testWidgets('the owner sees nothing to report', (tester) async {
      await tester.pumpWidget(_host(const GatheringSafetyMenu(
        target: SafetyTarget.gathering,
        contentId: 'g1',
        hostId: 'viewer-1',
        hostName: 'Me',
        viewerIsOwner: true,
      )));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('gathering-safety-menu')), findsNothing);
    });

    testWidgets('a non-owner gets the menu', (tester) async {
      await tester.pumpWidget(_host(const GatheringSafetyMenu(
        target: SafetyTarget.gathering,
        contentId: 'g1',
        hostId: 'host-9',
        hostName: 'Dana',
        viewerIsOwner: false,
      )));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('gathering-safety-menu')), findsOneWidget);
    });

    testWidgets('an unknown host hides the menu rather than reporting nobody',
        (tester) async {
      await tester.pumpWidget(_host(const GatheringSafetyMenu(
        target: SafetyTarget.gathering,
        contentId: 'g1',
        hostId: '',
        hostName: '',
        viewerIsOwner: false,
      )));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('gathering-safety-menu')), findsNothing);
    });
  });

  group('menu contents', () {
    testWidgets('a gathering offers report and block', (tester) async {
      await tester.pumpWidget(_host(const GatheringSafetyMenu(
        target: SafetyTarget.gathering,
        contentId: 'g1',
        hostId: 'host-9',
        hostName: 'Dana',
        viewerIsOwner: false,
      )));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('gathering-safety-menu')));
      await tester.pumpAndSettle();
      expect(find.text('Report gathering'), findsOneWidget);
      expect(find.text('Block User'), findsOneWidget);
    });

    testWidgets('a club says club, not gathering', (tester) async {
      await tester.pumpWidget(_host(const GatheringSafetyMenu(
        target: SafetyTarget.club,
        contentId: 'c1',
        hostId: 'owner-9',
        hostName: 'Dana',
        viewerIsOwner: false,
      )));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('gathering-safety-menu')));
      await tester.pumpAndSettle();
      expect(find.text('Report club'), findsOneWidget);
      expect(find.text('Report gathering'), findsNothing);
    });

    testWidgets('block is withheld when the viewer id is unknown',
        (tester) async {
      // Blocking needs the viewer's own id. Offering an entry that cannot
      // work is worse than not offering it; reporting still does.
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(_host(const GatheringSafetyMenu(
        target: SafetyTarget.gathering,
        contentId: 'g1',
        hostId: 'host-9',
        hostName: 'Dana',
        viewerIsOwner: false,
      )));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('gathering-safety-menu')));
      await tester.pumpAndSettle();
      expect(find.text('Report gathering'), findsOneWidget);
      expect(find.text('Block User'), findsNothing);
    });
  });
}
