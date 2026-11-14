import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/models/study/my_words.dart';
import 'package:bananatalk_app/services/study/my_words_api.dart';

const _body = {
  'success': true,
  'data': {
    'counts': {'candidates': 31, 'mistakes': 2, 'dueWords': 4},
    'candidates': [
      {
        'id': 'c1',
        'text': 'bonjour',
        'translation': 'hello',
        'partOfSpeech': 'interjection',
        'language': 'fr',
        'seenCount': 3,
        'lastSeenAt': '2026-11-14T10:00:00.000Z',
      },
    ],
    'mistakes': [
      {
        'id': 'm1',
        'original': 'I goed',
        'corrected': 'I went',
        'explanation': '',
        'source': 'partner',
        'language': 'en',
        'createdAt': '2026-11-14T10:00:00.000Z',
        'successes': 1,
      },
    ],
  },
};

Future<T> _with<T>(
  Future<T> Function() body,
  http.Response Function(http.Request) handler,
) {
  SharedPreferences.setMockInitialValues({'userId': 'me', 'token': 't'});
  return http.runWithClient(
      body, () => MockClient((req) async => handler(req)));
}

http.Response _json(Object body, [int code = 200]) => http.Response(
    jsonEncode(body), code,
    headers: {'content-type': 'application/json'});

void main() {
  test('fetch parses counts, candidates and mistakes', () async {
    final w = await _with(() => MyWordsApi().fetch(), (req) {
      expect(req.method, 'GET');
      expect(req.url.path, endsWith('/study/my-words'));
      return _json(_body);
    });
    expect(w.candidateCount, 31);
    expect(w.mistakeCount, 2);
    expect(w.dueWords, 4);
    expect(w.candidates.single.text, 'bonjour');
    expect(w.candidates.single.partOfSpeech, 'interjection');
    expect(w.candidates.single.seenCount, 3);
    expect(w.mistakes.single.corrected, 'I went');
    expect(w.mistakes.single.explanation, '');
    expect(w.mistakes.single.successes, 1);
  });

  test('fetch returns empty on 404 and throws on 500', () async {
    final empty = await _with(() => MyWordsApi().fetch(),
        (_) => _json({'success': false, 'error': 'Not found'}, 404));
    expect(empty, same(MyWords.empty));
    await expectLater(
      _with(() => MyWordsApi().fetch(),
          (_) => _json({'success': false, 'error': 'boom'}, 500)),
      throwsA(anything),
    );
  });

  test('a row with no id or no text is dropped; a missing number is 0', () {
    final w = MyWords.fromJson({
      'counts': {'candidates': 'x'},
      'candidates': [
        {'text': 'no id', 'translation': 't'},
        {'id': 'c2'},
        {'id': 'c3', 'text': 'ok'},
        'junk',
      ],
      'mistakes': [
        {'id': 'm2', 'corrected': 'x'},
        {'original': 'no id'},
        {'id': 'm3', 'original': 'ok'},
      ],
    });
    expect(w.candidateCount, 0);
    expect(w.mistakeCount, 0);
    expect(w.dueWords, 0);
    expect(w.candidates.map((c) => c.id), ['c3']);
    expect(w.candidates.single.seenCount, 0);
    expect(w.candidates.single.translation, '');
    expect(w.mistakes.map((m) => m.id), ['m3']);
    expect(w.mistakes.single.successes, 0);
    expect(MyWords.fromJson(const {}).candidates, isEmpty);
  });

  test('keep posts to /study/candidates/<id>/keep and returns the vocabulary id',
      () async {
    late http.Request seen;
    final id = await _with(() => MyWordsApi().keep('c1'), (req) {
      seen = req;
      return _json({
        'success': true,
        'data': {'vocabularyId': 'v9'},
      });
    });
    expect(seen.method, 'POST');
    expect(seen.url.path, endsWith('/study/candidates/c1/keep'));
    expect(id, 'v9');
  });

  test('dismiss posts to /study/candidates/<id>/dismiss; failures throw',
      () async {
    late http.Request seen;
    await _with(() => MyWordsApi().dismiss('c1'), (req) {
      seen = req;
      return _json({'success': true});
    });
    expect(seen.url.path, endsWith('/study/candidates/c1/dismiss'));
    await expectLater(
      _with(() => MyWordsApi().dismiss('c1'),
          (_) => _json({'success': false, 'error': 'Not found'}, 404)),
      throwsA(anything),
    );
  });

  test('gotIt returns successes and resolved', () async {
    late http.Request seen;
    final r = await _with(() => MyWordsApi().gotIt('m1'), (req) {
      seen = req;
      return _json({
        'success': true,
        'data': {'successes': 2, 'resolved': true},
      });
    });
    expect(seen.url.path, endsWith('/study/mistakes/m1/got-it'));
    expect(r.successes, 2);
    expect(r.resolved, isTrue);
  });
}
