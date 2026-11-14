import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/models/study/my_words.dart';
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:bananatalk_app/services/api_client.dart';

/// "My words and mistakes": `study/my-words`, keep / dismiss a word, and
/// "got it" on a mistake. The server answers 404 while capture is off.
class MyWordsApi {
  MyWordsApi([ApiClient? client]) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// A 404 (capture off, or nothing there) is [MyWords.empty]; any other
  /// failure throws.
  Future<MyWords> fetch() async {
    // No dedupe: a refresh right after keep / dismiss must see the new list,
    // not the answer ApiClient kept for its short dedupe window.
    final res = await _client.get(Endpoints.myWordsURL, deduplicate: false);
    if (res.statusCode == 404) return MyWords.empty;
    if (!res.success) throw StateError(res.error ?? 'my-words failed');
    final data = res.data;
    return data is Map<String, dynamic>
        ? MyWords.fromJson(data)
        : MyWords.empty;
  }

  /// Returns the new vocabulary id; throws on failure.
  Future<String?> keep(String candidateId) async {
    final res = await _client.post(Endpoints.candidateKeepURL(candidateId));
    if (!res.success) throw StateError(res.error ?? 'keep failed');
    final data = res.data;
    final id = data is Map ? data['vocabularyId'] : null;
    return id is String ? id : null;
  }

  Future<void> dismiss(String candidateId) async {
    final res = await _client.post(Endpoints.candidateDismissURL(candidateId));
    if (!res.success) throw StateError(res.error ?? 'dismiss failed');
  }

  Future<({int successes, bool resolved})> gotIt(String mistakeId) async {
    final res = await _client.post(Endpoints.mistakeGotItURL(mistakeId));
    if (!res.success) throw StateError(res.error ?? 'got-it failed');
    final data = res.data;
    final m = data is Map ? data : const {};
    final s = m['successes'];
    return (
      successes: s is num ? s.toInt() : 0,
      resolved: m['resolved'] == true,
    );
  }
}

final myWordsApiProvider = Provider<MyWordsApi>((ref) => MyWordsApi());
