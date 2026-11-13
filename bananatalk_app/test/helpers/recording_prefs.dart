import 'package:shared_preferences/shared_preferences.dart';

/// A [SharedPreferences] that records every call made through it (and every
/// time it is handed out), delegating to the real mock store. Pass
/// [RecordingPrefs.getter] as a cache's `prefs:` to prove a code path touches
/// no preferences at all.
class RecordingPrefs implements SharedPreferences {
  RecordingPrefs(this._inner);

  final SharedPreferences _inner;
  final List<String> calls = [];

  /// A drop-in for `SharedPreferences.getInstance` that records `getInstance`.
  static Future<SharedPreferences> Function() getter(RecordingPrefs prefs) =>
      () async {
        prefs.calls.add('getInstance');
        return prefs;
      };

  @override
  String? getString(String key) {
    calls.add('getString $key');
    return _inner.getString(key);
  }

  @override
  Future<bool> setString(String key, String value) {
    calls.add('setString $key');
    return _inner.setString(key, value);
  }

  @override
  Future<bool> remove(String key) {
    calls.add('remove $key');
    return _inner.remove(key);
  }

  @override
  Set<String> getKeys() {
    calls.add('getKeys');
    return _inner.getKeys();
  }

  @override
  bool containsKey(String key) {
    calls.add('containsKey $key');
    return _inner.containsKey(key);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls.add('unexpected ${invocation.memberName}');
    throw UnimplementedError('RecordingPrefs: ${invocation.memberName}');
  }
}
