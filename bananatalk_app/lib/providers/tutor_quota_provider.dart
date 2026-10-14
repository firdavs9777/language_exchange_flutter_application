import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/providers/tutor_provider.dart';
import 'package:bananatalk_app/services/analytics_service.dart';

class TutorQuotaInfo {
  final int used;
  final int? cap;       // null when unlimited (VIP)
  final int? remaining; // null when unlimited
  final DateTime? resetAt;
  final bool unlimited;

  /// Unspent coin unlocks (server `coinBonus[key]`). The server spends these
  /// after the free daily cap, so what's actually left is [remaining] +
  /// [bonus]. 0 when the server predates the field.
  final int bonus;

  const TutorQuotaInfo({
    required this.used,
    required this.cap,
    required this.remaining,
    required this.resetAt,
    required this.unlimited,
    this.bonus = 0,
  });

  factory TutorQuotaInfo.fromJson(Map<String, dynamic> j) => TutorQuotaInfo(
        used: (j['used'] as num?)?.toInt() ?? 0,
        cap: (j['cap'] as num?)?.toInt(),
        remaining: (j['remaining'] as num?)?.toInt(),
        resetAt: j['resetAt'] != null ? DateTime.tryParse(j['resetAt'].toString()) : null,
        unlimited: j['unlimited'] == true,
        bonus: ((j['bonus'] as num?)?.toInt() ?? 0).clamp(0, 1 << 30),
      );

  /// Uses left today, free + paid; null when unlimited or not reported.
  int? get available => unlimited || remaining == null ? null : remaining! + bonus;

  /// Nothing left at all — free cap used AND no coin unlocks in the pool.
  bool get isExhausted => available == 0;

  /// True once what's left (free + coin bonus) is ≤ 50% of the daily cap.
  /// With no bonus this is the old "used ≥ 50%" rule; with a bonus a user
  /// who just bought 3 uses sees "3 left" rather than "0 left", and one with
  /// plenty left sees nothing. Hides for unlimited.
  bool get shouldShowIndicator {
    if (unlimited || cap == null || cap == 0) return false;
    final left = available ?? (cap! - used).clamp(0, cap!);
    return left * 2 <= cap!;
  }
}

class TutorQuotaState {
  final TutorQuotaInfo? chat;
  final TutorQuotaInfo? roleplay;
  final TutorQuotaInfo? story;
  final TutorQuotaInfo? photo;
  final TutorQuotaInfo? pronunciation;

  const TutorQuotaState({this.chat, this.roleplay, this.story, this.photo, this.pronunciation});

  static const empty = TutorQuotaState();

  TutorQuotaInfo? get(String key) {
    switch (key) {
      case 'chat':          return chat;
      case 'roleplay':      return roleplay;
      case 'story':         return story;
      case 'photo':         return photo;
      case 'pronunciation': return pronunciation;
      default: return null;
    }
  }

  factory TutorQuotaState.fromMap(Map<String, dynamic>? quotasJson) {
    if (quotasJson == null) return empty;
    TutorQuotaInfo? parse(String k) {
      final v = quotasJson[k];
      return v is Map<String, dynamic> ? TutorQuotaInfo.fromJson(v) : null;
    }
    return TutorQuotaState(
      chat:          parse('chat'),
      roleplay:      parse('roleplay'),
      story:         parse('story'),
      photo:         parse('photo'),
      pronunciation: parse('pronunciation'),
    );
  }
}

/// Per-app-session dedup set for the quota_remaining_shown event.
/// Resets when the app process restarts — we intentionally do NOT
/// persist this across restarts. v1 acceptable.
final _shownThisSession = <String>{};

void _maybeFireRemainingShown(TutorQuotaState state) {
  for (final key in ['chat', 'roleplay', 'story', 'photo', 'pronunciation']) {
    final info = state.get(key);
    if (info != null && info.shouldShowIndicator && !_shownThisSession.contains(key)) {
      _shownThisSession.add(key);
      AnalyticsService.instance.quotaRemainingShown(
        chipName: key,
        remainingCount: info.available ?? 0,
      );
    }
  }
}

/// Public provider — reads from the private memory+quotas provider.
/// Fires quota_remaining_shown analytics on first sight of ≥ 50% per chip.
final tutorQuotaProvider = Provider<TutorQuotaState>((ref) {
  final asyncResult = ref.watch(tutorMemoryAndQuotasProvider);
  return asyncResult.maybeWhen(
    data: (r) {
      final state = TutorQuotaState.fromMap(r.quotas);
      _maybeFireRemainingShown(state);
      return state;
    },
    orElse: () => TutorQuotaState.empty,
  );
});
