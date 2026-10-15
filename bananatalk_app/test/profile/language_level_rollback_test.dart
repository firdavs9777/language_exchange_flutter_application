import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/profile/edit_main/sections/language_section.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';

class _FailingAuth extends AuthService {
  @override
  Future<Community> updateUserLanguageLevel({
    required String languageLevel,
  }) async {
    throw Exception('server error');
  }
}

/// Holds the level the way the edit screen does, so the section re-renders.
class _Host extends StatefulWidget {
  const _Host({required this.initial});
  final String? initial;
  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late String? level = widget.initial;
  @override
  Widget build(BuildContext context) => Scaffold(
        body: SingleChildScrollView(
          child: LanguageSection(
            selectedNativeLanguage: 'Korean',
            selectedLanguageToLearn: 'English',
            selectedLanguageLevel: level,
            onNativeLanguageChanged: (_) {},
            onLanguageToLearnChanged: (_) {},
            onLanguageLevelChanged: (l) => setState(() => level = l),
          ),
        ),
      );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpAndPick(WidgetTester t, String? initial) async {
    await t.pumpWidget(ProviderScope(
      overrides: [authServiceProvider.overrideWith((ref) => _FailingAuth())],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: _Host(initial: initial),
      ),
    ));
    await t.tap(find.text('Language Level'));
    await t.pumpAndSettle();
    await t.tap(find.text('B1').last);
    await t.pumpAndSettle();
  }

  testWidgets('a failed save restores the previous level', (t) async {
    await pumpAndPick(t, 'A2');
    final section = t.widget<LanguageSection>(find.byType(LanguageSection));
    expect(section.selectedLanguageLevel, 'A2');
  });

  testWidgets('a failed save restores an unset level', (t) async {
    await pumpAndPick(t, null);
    final section = t.widget<LanguageSection>(find.byType(LanguageSection));
    expect(section.selectedLanguageLevel, isNull);
  });
}
