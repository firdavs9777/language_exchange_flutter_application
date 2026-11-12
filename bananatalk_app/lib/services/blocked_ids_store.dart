import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// The last block list fetched for the signed-in user, kept so cached feed
/// and stories lists can be filtered when the list cannot be fetched (an
/// offline cold start reads the last known list, not an empty one).
///
/// Stored as `{userId, ids}` under [key]; another account never reads it.
/// User-scoped: not on the device-level allow-list in `session_prefs.dart`,
/// so sign-out removes it.
class BlockedIdsStore {
  static const String key = 'blocked_user_ids_v1';

  Future<Set<String>> read({required String userId}) async {
    try {
      if (userId.isEmpty) return <String>{};
      final prefs = await SharedPreferences.getInstance();
      final text = prefs.getString(key);
      if (text == null) return <String>{};
      final decoded = jsonDecode(text);
      if (decoded is! Map || decoded['userId'] != userId) return <String>{};
      final ids = decoded['ids'];
      return ids is List ? ids.whereType<String>().toSet() : <String>{};
    } catch (_) {
      return <String>{};
    }
  }

  Future<void> write({
    required String userId,
    required Set<String> ids,
  }) async {
    if (userId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        key,
        jsonEncode({'userId': userId, 'ids': ids.toList()}),
      );
    } catch (_) {}
  }

  Future<void> add({required String userId, required String id}) async =>
      write(userId: userId, ids: {...await read(userId: userId), id});

  Future<void> remove({required String userId, required String id}) async =>
      write(userId: userId, ids: (await read(userId: userId))..remove(id));
}
