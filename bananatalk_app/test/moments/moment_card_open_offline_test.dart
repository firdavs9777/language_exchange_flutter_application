import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/moments/card/moment_card.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';

import '../support/moment_fixture.dart';

/// Tapping a moment card offline did nothing at all: the detail fetch threw
/// an unhandled async error and no feedback appeared.
class _OfflineMomentsService extends MomentsService {
  @override
  Future<Moments> getSingleMoment({required String id}) async {
    throw const SocketException('Failed host lookup');
  }
}

void main() {
  testWidgets('an offline tap says so instead of doing nothing',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        momentsServiceProvider.overrideWithValue(_OfflineMomentsService()),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: MomentCard(moments: buildMoment(description: 'tap me')),
          ),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('tap me'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('No internet connection'), findsOneWidget);
  });
}
