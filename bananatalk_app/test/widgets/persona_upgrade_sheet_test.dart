import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/tutor/tutor_memory.dart';
import 'package:bananatalk_app/providers/tutor_provider.dart';
import 'package:bananatalk_app/services/analytics_service.dart';
import 'package:bananatalk_app/widgets/tutor/persona_upgrade_sheet.dart';

Widget _host({Locale locale = const Locale('en'), required Future<TutorMemory> memory}) =>
    ProviderScope(
      overrides: [tutorMemoryProvider.overrideWith((ref) => memory)],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: PersonaUpgradeSheet(triggerChip: 'chat')),
      ),
    );

void main() {
  final events = <String>[];
  setUp(() {
    events.clear();
    AnalyticsService.debugLogSink = (name, _) => events.add(name);
  });
  tearDown(() => AnalyticsService.debugLogSink = null);

  testWidgets('paywall_shown fires once even as the sheet rebuilds', (tester) async {
    final memory = Completer<TutorMemory>();
    await tester.pumpWidget(_host(memory: memory.future));
    await tester.pump();
    // The memory resolving rebuilds the sheet; that is not a second showing.
    memory.completeError(Exception('offline'));
    await tester.pumpAndSettle();
    expect(events.where((e) => e == 'paywall_shown').length, 1);
  });

  testWidgets('the headline is localized', (tester) async {
    await tester.pumpWidget(_host(
      locale: const Locale('ko'),
      memory: Completer<TutorMemory>().future,
    ));
    await tester.pump();
    expect(find.textContaining('Upgrade for unlimited'), findsNothing);
    expect(find.textContaining('업그레이드'), findsWidgets);
  });
}
