import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/widgets/chat/opener_chips.dart';

Community _user(
  String name,
  String native,
  String learn, {
  List<String> topics = const [],
}) =>
    Community.fromJson({
      '_id': name,
      'name': name,
      'native_language': native,
      'language_to_learn': learn,
      'topics': topics,
    });

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  test('reciprocal + shared topic -> 3 chips, reciprocal first', () {
    final me = _user('Me', 'English', 'Korean', topics: ['Music', 'Food']);
    final them =
        _user('Minji', ' korean ', 'ENGLISH', topics: ['Travel', 'music']);
    final out = OpenerChips.buildOpeners(l10n, me, them);
    expect(out.length, 3);
    expect(out[0], l10n.openerReciprocal('korean', 'English'));
    expect(out[1], l10n.openerSharedTopic('Music'));
    expect(out[2], l10n.openerGeneric('Minji', ' korean '.trim()));
  });

  test('no overlap -> only generic', () {
    final me = _user('Me', 'English', 'Korean', topics: ['Music']);
    final them = _user('Ana', 'Spanish', 'French', topics: ['Chess']);
    final out = OpenerChips.buildOpeners(l10n, me, them);
    expect(out, [l10n.openerGeneric('Ana', 'Spanish')]);
  });

  testWidgets('tap chip calls onPick with text and nothing else',
      (tester) async {
    final picked = <String>[];
    final me = _user('Me', 'English', 'Korean');
    final them = _user('Ana', 'Spanish', 'French');
    await tester.pumpWidget(_wrap(OpenerChips(
      me: me,
      partner: them,
      onPick: picked.add,
    )));
    expect(find.text(l10n.openerChipsTitle), findsOneWidget);
    await tester.tap(find.text(l10n.openerGeneric('Ana', 'Spanish')));
    await tester.pump();
    expect(picked, [l10n.openerGeneric('Ana', 'Spanish')]);
  });
}
