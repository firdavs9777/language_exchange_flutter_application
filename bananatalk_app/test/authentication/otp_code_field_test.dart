import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/pages/authentication/widgets/otp_code_field.dart';

void main() {
  testWidgets('auto-completes and clears via shakeAndClear', (tester) async {
    final key = GlobalKey<OtpCodeFieldState>();
    String? completedValue;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OtpCodeField(
            key: key,
            length: 6,
            onCompleted: (value) => completedValue = value,
          ),
        ),
      ),
    );

    final textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);

    await tester.enterText(textFieldFinder, '123456');
    await tester.pump();

    expect(completedValue, '123456');
    expect(find.text('1'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);

    key.currentState!.shakeAndClear();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('1'), findsNothing);
    expect(find.text('6'), findsNothing);
  });

  testWidgets('shakeAndClear does not throw when widget is disposed mid-shake',
      (tester) async {
    final key = GlobalKey<OtpCodeFieldState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OtpCodeField(
            key: key,
            length: 6,
            onCompleted: (_) {},
          ),
        ),
      ),
    );

    key.currentState!.shakeAndClear();

    // Replace the tree before the 300ms shake animation completes, which
    // disposes the OtpCodeField (and its AnimationController) while the
    // forward().then(...) callback is still pending.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
  });
}
