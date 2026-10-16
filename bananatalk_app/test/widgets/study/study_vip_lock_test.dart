import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/ai/ai_quiz_model.dart';
import 'package:bananatalk_app/models/ai/grammar_feedback_model.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/pages/learning/main/sections/study_features.dart';
import 'package:bananatalk_app/providers/provider_root/ai_providers.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/services/ai_service.dart';
import 'package:bananatalk_app/services/analytics_service.dart';
import 'package:bananatalk_app/services/study_vip_lock.dart';
import 'package:bananatalk_app/widgets/coins/unlock_cta.dart';
import 'package:bananatalk_app/widgets/study/study_vip_lock.dart';

/// The body backend `requireStudyVip` sends (middleware/requireStudyVip.js).
Map<String, dynamic> _lockBody(String slug) => {
      'success': false,
      'error': 'quota_exceeded',
      'reason': 'vip_required',
      'feature': 'vip_only_$slug',
      'resetAt': null,
      'message': 'This feature is for VIP members. Upgrade to use it.',
      'upgradeAvailable': true,
    };

http.Response _json(int status, Map<String, dynamic> body) =>
    http.Response(jsonEncode(body), status,
        headers: {'content-type': 'application/json'});

Future<T> _withServer<T>(Future<T> Function() body, http.Response response) =>
    http.runWithClient(body, () => MockClient((_) async => response));

void main() {
  group('studyVipLockFeature', () {
    test('maps the lock body to its feature', () {
      expect(studyVipLockFeature(429, _lockBody('speak')), StudyFeature.speak);
      expect(studyVipLockFeature(429, _lockBody('writing')), StudyFeature.writing);
      expect(studyVipLockFeature(429, _lockBody('quizzes')), StudyFeature.quizzes);
    });

    test('a plain daily cap is not a VIP lock', () {
      expect(
          studyVipLockFeature(429, {'error': 'quota_exceeded', 'feature': 'story'}),
          isNull);
    });

    test('other statuses, errors and unknown slugs are ignored', () {
      expect(studyVipLockFeature(403, _lockBody('speak')), isNull);
      expect(studyVipLockFeature(429, {..._lockBody('speak'), 'error': 'rate_limited'}),
          isNull);
      expect(studyVipLockFeature(429, _lockBody('bogus')), isNull);
      expect(studyVipLockFeature(429, null), isNull);
    });
  });

  group('AIService carries the lock', () {
    setUp(() => SharedPreferences.setMockInitialValues({'token': 't'}));

    test('analyzeGrammar (Writing)', () async {
      final res = await _withServer(
          () => AIService.analyzeGrammar(
              AnalyzeGrammarRequest(text: 'hi', targetLanguage: 'en')),
          _json(429, _lockBody('writing')));
      expect(res['success'], isFalse);
      expect(res[studyVipLockKey], StudyFeature.writing);
    });

    test('evaluatePronunciation (Speak)', () async {
      final dir = await Directory.systemTemp.createTemp('vip_lock');
      addTearDown(() => dir.delete(recursive: true));
      final audio = File('${dir.path}/a.m4a')..writeAsBytesSync([0, 1, 2]);
      final res = await _withServer(
          () => AIService.evaluatePronunciation(audio, 'hello', 'en'),
          _json(429, _lockBody('speak')));
      expect(res['success'], isFalse);
      expect(res[studyVipLockKey], StudyFeature.speak);
    });

    test('generateQuiz (Quizzes) lands in provider state', () async {
      final notifier = AIQuizNotifier();
      addTearDown(notifier.dispose);
      final ok = await _withServer(
          () => notifier.generateQuiz(GenerateQuizRequest(type: 'vocabulary')),
          _json(429, _lockBody('quizzes')));
      expect(ok, isFalse);
      expect(notifier.state.vipLock, StudyFeature.quizzes);
    });

    test('ordinary failures carry no lock', () async {
      final res = await _withServer(
          () => AIService.analyzeGrammar(
              AnalyzeGrammarRequest(text: 'hi', targetLanguage: 'en')),
          _json(500, {'success': false, 'message': 'boom'}));
      expect(res['success'], isFalse);
      expect(res.containsKey(studyVipLockKey), isFalse);

      final notifier = AIQuizNotifier();
      addTearDown(notifier.dispose);
      await _withServer(
          () => notifier.generateQuiz(GenerateQuizRequest(type: 'vocabulary')),
          _json(429, {'error': 'quota_exceeded', 'feature': 'quiz'}));
      expect(notifier.state.vipLock, isNull);
    });
  });

  group('showStudyVipLockIfAny', () {
    final events = <String, Map<String, Object>>{};
    setUp(() {
      events.clear();
      AnalyticsService.debugLogSink = (n, p) => events[n] = p;
    });
    tearDown(() => AnalyticsService.debugLogSink = null);

    Future<bool?> tapOpen(WidgetTester tester, Map<String, dynamic> result) async {
      bool? shown;
      await tester.pumpWidget(ProviderScope(
        overrides: [
          appConfigProvider.overrideWith((ref) async => const AppConfig(
              minVersion: '0', latestVersion: '0', forceUpdate: false,
              iosUrl: '', androidUrl: '', releaseNotes: '', coinsEnabled: true)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async =>
                    shown = await showStudyVipLockIfAny(context, result),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return shown;
    }

    testWidgets('opens the VIP-lock sheet: Get VIP + Not now, no coins',
        (tester) async {
      await tapOpen(tester, {'success': false, studyVipLockKey: StudyFeature.writing});
      expect(find.text('Writing is a VIP feature'), findsOneWidget);
      expect(find.text('Get VIP — unlimited'), findsOneWidget);
      expect(find.text('Not Now'), findsOneWidget);
      expect(find.byType(UnlockCta), findsNothing);
      expect(events['study_upgrade_sheet_shown'],
          {'feature': 'writing', 'reason': 'locked'});

      await tester.tap(find.text('Not Now'));
      await tester.pumpAndSettle();
      expect(find.text('Writing is a VIP feature'), findsNothing);
    });

    testWidgets('resolves true once the sheet closes', (tester) async {
      bool? shown;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ProviderScope(
          overrides: [
            appConfigProvider.overrideWith((ref) async => const AppConfig(
                minVersion: '0', latestVersion: '0', forceUpdate: false,
                iosUrl: '', androidUrl: '', releaseNotes: '')),
          ],
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () async => shown = await showStudyVipLockIfAny(
                  context, {studyVipLockKey: StudyFeature.speak}),
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Speak is a VIP feature'), findsOneWidget);
      await tester.tap(find.text('Not Now'));
      await tester.pumpAndSettle();
      expect(shown, isTrue);
    });

    testWidgets('no lock: no sheet, resolves false', (tester) async {
      final shown = await tapOpen(tester, {'success': false, 'message': 'boom'});
      expect(shown, isFalse);
      expect(find.text('Get VIP — unlimited'), findsNothing);
      expect(events, isEmpty);
    });
  });
}
