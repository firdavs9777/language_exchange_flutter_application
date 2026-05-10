import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kMutedMomentsKey = 'mutedMoments';

class MutedMomentsNotifier extends StateNotifier<Set<String>> {
  MutedMomentsNotifier() : super(<String>{}) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kMutedMomentsKey) ?? <String>[];
    state = list.toSet();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kMutedMomentsKey, state.toList());
  }

  Future<void> mute(String userId) async {
    state = {...state, userId};
    await _persist();
  }

  Future<void> unmute(String userId) async {
    state = {...state}..remove(userId);
    await _persist();
  }

  bool isMuted(String userId) => state.contains(userId);
}

final mutedMomentsProvider =
    StateNotifierProvider<MutedMomentsNotifier, Set<String>>(
  (ref) => MutedMomentsNotifier(),
);
