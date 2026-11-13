import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/services/stories_service.dart';

/// The server answers a question-box answer with 201; the app only accepted
/// 200, so a successful answer was reported as a failure.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'token': 't'}));
  tearDown(() => StoriesService.httpClient = null);

  Future<Map<String, dynamic>> answerWith(int status) {
    StoriesService.httpClient =
        MockClient((_) async => http.Response('{"success":true}', status));
    return StoriesService.answerQuestion(storyId: 's1', text: 'hi');
  }

  test('201 is success', () async {
    expect((await answerWith(201))['success'], isTrue);
  });

  test('200 is success', () async {
    expect((await answerWith(200))['success'], isTrue);
  });

  test('400 is failure', () async {
    expect((await answerWith(400))['success'], isFalse);
  });
}
