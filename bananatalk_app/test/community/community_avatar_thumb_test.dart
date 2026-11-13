import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/community/card/match_card.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_models/daily_match_model.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:bananatalk_app/widgets/community/partner_card.dart';
import 'package:bananatalk_app/widgets/community/partner_list_item.dart';

const _full = 'https://cdn.example.com/full.jpg';
const _thumb = 'https://cdn.example.com/thumb.jpg';

Map<String, dynamic> _user({Object? thumb, bool story = false}) => {
      '_id': 'u1',
      'name': 'Minji',
      'native_language': 'Korean',
      'language_to_learn': 'English',
      'images': [_full],
      'hasActiveStory': story,
      if (thumb != null) 'avatarThumb': thumb,
    };

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

List<String> _urls(WidgetTester t) =>
    t.widgetList<CachedImageWidget>(find.byType(CachedImageWidget))
        .map((w) => w.imageUrl ?? '')
        .toList();

Widget _matchCard(Map<String, dynamic> user) => MatchCard(
      match: DailyMatch.fromJson({
        'user': user,
        'matchReasons': const ['reciprocal_pair'],
        'reciprocal': true,
      }),
      onSayHi: () {},
      onWave: () {},
      onSkip: () {},
    );

void main() {
  final fullUrl = Community.fromJson(_user()).profileImageUrl!;

  group('daily-match parse keeps avatarThumb', () {
    test('thumb survives', () {
      final m = DailyMatch.fromJson({
        'user': _user(thumb: _thumb),
        'matchReasons': const [],
      });
      expect(m.user.avatarThumb, _thumb);
      expect(m.user.avatarUrl, _thumb);
    });
  });

  group('MatchCard avatar', () {
    testWidgets('thumb present -> thumb', (t) async {
      await t.pumpWidget(_wrap(_matchCard(_user(thumb: _thumb))));
      expect(_urls(t), [_thumb]);
    });
    testWidgets('no thumb -> first image', (t) async {
      await t.pumpWidget(_wrap(_matchCard(_user())));
      expect(_urls(t), [fullUrl]);
    });
    testWidgets('empty thumb -> first image', (t) async {
      await t.pumpWidget(_wrap(_matchCard(_user(thumb: ''))));
      expect(_urls(t), [fullUrl]);
    });
  });

  group('PartnerListItem avatar', () {
    testWidgets('thumb present -> thumb', (t) async {
      await t.pumpWidget(
          _wrap(PartnerListItem(user: Community.fromJson(_user(thumb: _thumb)))));
      expect(_urls(t), contains(_thumb));
      expect(_urls(t), isNot(contains(fullUrl)));
    });
    testWidgets('no thumb -> first image', (t) async {
      await t.pumpWidget(
          _wrap(PartnerListItem(user: Community.fromJson(_user()))));
      expect(_urls(t), contains(fullUrl));
    });
    testWidgets('empty thumb -> first image', (t) async {
      await t.pumpWidget(
          _wrap(PartnerListItem(user: Community.fromJson(_user(thumb: '')))));
      expect(_urls(t), contains(fullUrl));
    });
  });

  group('PartnerCard', () {
    testWidgets('mini story badge uses thumb; full-bleed photo stays full',
        (t) async {
      await t.pumpWidget(_wrap(SizedBox(
        height: 700,
        child: PartnerCard(
          user: Community.fromJson(_user(thumb: _thumb, story: true)),
        ),
      )));
      final urls = _urls(t);
      expect(urls, contains(_thumb));
      expect(urls, contains(fullUrl));
    });
    testWidgets('mini story badge without thumb -> first image', (t) async {
      await t.pumpWidget(_wrap(SizedBox(
        height: 700,
        child: PartnerCard(user: Community.fromJson(_user(story: true))),
      )));
      expect(_urls(t), everyElement(fullUrl));
    });
    testWidgets('mini story badge with empty thumb -> first image', (t) async {
      await t.pumpWidget(_wrap(SizedBox(
        height: 700,
        child: PartnerCard(
          user: Community.fromJson(_user(thumb: '', story: true)),
        ),
      )));
      expect(_urls(t), everyElement(fullUrl));
    });
  });
}
