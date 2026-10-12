import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/models/announcement.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/services/announcement_seen_store.dart';
import 'package:bananatalk_app/services/app_config_service.dart';
import 'package:bananatalk_app/services/session_prefs.dart';

Announcement _a(String id, {int p = 0}) =>
    Announcement(id: id, title: 't$id', body: 'b', priority: p);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('app-config parses the announcements list', () {
    final c = AppConfig.fromJson({
      'announcements': [
        {'id': 'x', 'title': 'Hi', 'body': 'B', 'priority': 5, 'buttonUrl': '/boost', 'buttonLabel': 'Go'},
        {'title': 'no id'},
      ],
    });
    expect(c.announcements.map((a) => a.id), ['x']);
    expect(c.announcements.single.priority, 5);
    expect(c.announcements.single.hasButton, isTrue);
    expect(AppConfig.fromJson({}).announcements, isEmpty);
  });

  group('pickAnnouncement', () {
    test('highest priority unseen; ties keep server order', () {
      expect(pickAnnouncement(live: [_a('1'), _a('2', p: 3), _a('3', p: 3)],
              legacy: null, seen: {})!.id, '2');
      expect(pickAnnouncement(live: [_a('1'), _a('2', p: 3)],
              legacy: null, seen: {'2'})!.id, '1');
    });
    test('all seen: nothing', () {
      expect(pickAnnouncement(live: [_a('1')], legacy: null, seen: {'1'}), isNull);
    });
    test('old backend (no list): the legacy field', () {
      expect(pickAnnouncement(live: const [], legacy: _a('env'), seen: {})!.id, 'env');
    });
    test('a list present: legacy ignored', () {
      expect(pickAnnouncement(live: [_a('1')], legacy: _a('env'), seen: {'1'}), isNull);
    });
  });

  test('legacy announcement needs active, id and text', () {
    const a = AppAnnouncement(active: false, id: 'e', title: 'T', body: '',
        emoji: '📢', buttonLabel: '', buttonUrl: '');
    expect(Announcement.fromLegacy(a), isNull);
    expect(Announcement.fromLegacy(const AppAnnouncement(active: true, id: 'e',
            title: 'T', body: '', emoji: '📢', buttonLabel: '', buttonUrl: ''))!
        .id, 'e');
  });

  test('seen set: add, read, and old dismissed_announcement_ keys', () async {
    SharedPreferences.setMockInitialValues({'dismissed_announcement_env1': true});
    await AnnouncementSeenStore.add('db1');
    expect(await AnnouncementSeenStore.read(), {'db1', 'env1'});
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList(kAnnouncementsSeenKey), ['db1']);
  });

  test('app-config is requested with the app language', () async {
    SharedPreferences.setMockInitialValues({'app_language': 'ko'});
    Uri? asked;
    await http.runWithClient(
      () => AppConfigService().fetch(),
      () => MockClient((req) async {
        asked = req.url;
        return http.Response(jsonEncode({'data': {}}), 200);
      }),
    );
    expect(asked!.queryParameters['lang'], 'ko');
  });

  // Shape copied from the backend's test/appConfigAnnouncements.test.js
  // (toPublic + controller): nulls for absent optionals, string id, int priority.
  test('parses the backend response shape, nulls included', () {
    final c = AppConfig.fromJson({
      'announcement': {
        'active': true, 'id': 'a1', 'title': 'T', 'body': 'b',
        'emoji': '🎉', 'buttonLabel': '', 'buttonUrl': '',
      },
      'announcements': [
        {
          'id': 'a1', 'title': 'T', 'body': 'b', 'emoji': null,
          'imageUrl': null, 'buttonLabel': null, 'buttonUrl': null,
          'priority': 0,
        },
        {
          'id': 'a2', 'title': 'T2', 'body': 'b2', 'emoji': '🎉',
          'imageUrl': 'https://cdn.example.com/i.png', 'buttonLabel': 'Open',
          'buttonUrl': 'bananatalk://study', 'priority': 9,
        },
      ],
    });
    expect(c.announcements, hasLength(2));
    expect(c.announcements[0].emoji, isNull);
    expect(c.announcements[0].hasButton, isFalse);
    expect(c.announcements[1].hasButton, isTrue);
    expect(c.announcements[1].priority, 9);
    // The legacy field for a hidden deep-link button: active, no button.
    final legacy = Announcement.fromLegacy(c.announcement)!;
    expect(legacy.id, 'a1');
    expect(legacy.hasButton, isFalse);
  });

  test('hasButton accepts http(s) and bananatalk://, rejects //host and junk', () {
    Announcement b(String url) => Announcement(
        id: 'i', title: 't', body: 'b', buttonLabel: 'Go', buttonUrl: url);
    expect(b('https://example.com/x').hasButton, isTrue);
    expect(b('http://example.com').hasButton, isTrue);
    expect(b('bananatalk://study').hasButton, isTrue);
    expect(b('/boost').hasButton, isTrue);
    expect(b('//evil.com/x').hasButton, isFalse);
    expect(b('javascript:alert(1)').hasButton, isFalse);
    expect(b('https://').hasButton, isFalse);
    expect(const Announcement(id: 'i', title: 't', body: 'b', buttonUrl: '/x')
        .hasButton, isFalse);
  });

  test('seen set is bounded to 200 ids, newest kept', () async {
    for (var i = 0; i < 205; i++) {
      await AnnouncementSeenStore.add('id$i');
    }
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(kAnnouncementsSeenKey)!;
    expect(ids, hasLength(200));
    expect(ids.last, 'id204');
    expect(ids.contains('id0'), isFalse);
  });

  test('seen key is user-scoped: not on the device allow-list', () {
    expect(isDeviceLevelPrefsKey(kAnnouncementsSeenKey), isFalse);
  });

  test('hasButton hardening: backslash, bananatalk:foo, case, whitespace', () {
    bool ok(String u) => Announcement(
        id: 'i', title: 't', body: 'b', buttonLabel: 'Go', buttonUrl: u)
        .hasButton;
    expect(ok(r'/\evil.com'), isFalse);
    expect(ok('//host'), isFalse);
    expect(ok(r'https://a.com\@evil.com'), isFalse);
    expect(ok('bananatalk:foo'), isFalse);
    expect(ok('BananaTalk://study'), isTrue);
    expect(ok('HTTP://x.com'), isTrue);
    expect(ok('  https://x.com/a  '), isTrue);
  });

  test('a non-string title drops only that item; fromLegacy trims', () {
    final c = AppConfig.fromJson({
      'announcements': [
        {'id': 'bad', 'title': 5, 'body': 7},
        {'id': 'half', 'title': 5, 'body': 'b'},
        {'id': 'good', 'title': 'T', 'body': 'b'},
        {'id': 'x', 'title': null, 'body': ['z']},
      ],
    });
    expect(c.announcements.map((a) => a.id), ['half', 'good']);
    expect(c.announcements.first.title, '');
    final l = Announcement.fromLegacy(const AppAnnouncement(
        active: true, id: ' e ', title: ' T ', body: '', emoji: ' ',
        buttonLabel: ' Go ', buttonUrl: ' https://x.com '))!;
    expect(l.id, 'e');
    expect(l.title, 'T');
    expect(l.emoji, isNull);
    expect(l.buttonUrl, 'https://x.com');
  });

  test('seen set with a wrong-typed value: read null, add does not clobber',
      () async {
    SharedPreferences.setMockInitialValues({kAnnouncementsSeenKey: 'oops'});
    expect(await AnnouncementSeenStore.read(), isNull);
    await AnnouncementSeenStore.add('x');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.get(kAnnouncementsSeenKey), 'oops');
  });
}
