import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/widgets/qr_code_sheet.dart';

const kId = '64b7f0c2a1b2c3d4e5f60718';

void main() {
  testWidgets('My Code encodes the https profile link', (tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: QrCodeSheet(userId: kId, userName: 'Ana', onUserScanned: (_) {}),
        ),
      ),
    ));
    await tester.pump();
    // The sheet still builds with the https payload (QrImageView keeps its
    // data private, so the payload is pinned through the source below).
    expect(find.byType(QrImageView), findsOneWidget);
    final src = File('lib/widgets/qr_code_sheet.dart').readAsStringSync();
    expect(src, contains("shareUrl('profile', widget.userId)"));
    expect(src, isNot(contains("'bananatalk://user/\${widget.userId}'")));
    expect(src, contains('userIdFromQrPayload(raw)'));
  });
}
