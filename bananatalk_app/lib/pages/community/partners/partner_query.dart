import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The quick chips over the Partners list. Held in a provider (not widget
/// state) so the filter sheet's live count builds the same request as the
/// list behind it.
@immutable
class PartnerQuickChips {
  const PartnerQuickChips({
    this.online = false,
    this.nearby = false,
    this.sameCity = false,
    this.gender,
    this.topicId,
    this.speaks,
    this.learns,
    this.sort,
  });

  final bool online;

  /// Swaps the list for the distance-sorted Nearby view.
  final bool nearby;
  final bool sameCity;

  /// 'female' | 'male' | null; overrides the filter sheet's gender.
  final String? gender;
  final String? topicId;

  /// "Speaks X" / "Learning Y" chips (the viewer's own languages).
  final String? speaks;
  final String? learns;

  /// null = default, 'recently_active'.
  final String? sort;

  bool get isActive =>
      online || nearby || sameCity || gender != null || topicId != null ||
      speaks != null || learns != null;

  PartnerQuickChips copyWith({
    bool? online,
    bool? nearby,
    bool? sameCity,
    ValueGetter<String?>? gender,
    ValueGetter<String?>? topicId,
    ValueGetter<String?>? speaks,
    ValueGetter<String?>? learns,
    ValueGetter<String?>? sort,
  }) =>
      PartnerQuickChips(
        online: online ?? this.online,
        nearby: nearby ?? this.nearby,
        sameCity: sameCity ?? this.sameCity,
        gender: gender != null ? gender() : this.gender,
        topicId: topicId != null ? topicId() : this.topicId,
        speaks: speaks != null ? speaks() : this.speaks,
        learns: learns != null ? learns() : this.learns,
        sort: sort != null ? sort() : this.sort,
      );

  /// Every chip off except the sort order.
  PartnerQuickChips cleared() => PartnerQuickChips(sort: sort);

  @override
  bool operator ==(Object other) =>
      other is PartnerQuickChips &&
      online == other.online &&
      nearby == other.nearby &&
      sameCity == other.sameCity &&
      gender == other.gender &&
      topicId == other.topicId &&
      speaks == other.speaks &&
      learns == other.learns &&
      sort == other.sort;

  @override
  int get hashCode =>
      Object.hash(online, nearby, sameCity, gender, topicId, speaks, learns, sort);
}

final partnerQuickChipsProvider = StateProvider<PartnerQuickChips>(
  (ref) => const PartnerQuickChips(),
);

String? _str(Object? v) {
  final s = v?.toString();
  return (s == null || s.isEmpty) ? null : s;
}

/// The `/users` params for the Partners list, from the filter sheet's
/// values ([filters] is `FilterState.toJson()` or the sheet's draft map),
/// the segment and the quick chips.
///
/// API semantics are inverted for exchange matching: the API's
/// `nativeLanguage` finds people LEARNING it, `learningLanguage` finds people
/// who SPEAK it. So "Native language: French" in the sheet is sent as
/// `learningLanguage`.
PartnerFilterParams partnerParamsFor({
  required Map<String, dynamic> filters,
  required String? myNative,
  required String? myLearning,
  required PartnerSegment segment,
  required PartnerQuickChips chips,
  required bool isVip,
  String? search,
}) {
  final filterNative = _str(filters['nativeLanguage']);
  final filterLearning = _str(filters['learningLanguage']);

  String? apiNative; // finds people LEARNING this
  String? apiLearning; // finds people who SPEAK this
  if (filterNative != null || filterLearning != null) {
    apiLearning = filterNative;
    apiNative = filterLearning;
  } else {
    apiLearning = myLearning;
    apiNative = myNative;
  }
  // Quick language chips focus on one criterion.
  if (chips.speaks != null) {
    apiLearning = chips.speaks;
    if (chips.learns == null) apiNative = null;
  }
  if (chips.learns != null) {
    apiNative = chips.learns;
    if (chips.speaks == null) apiLearning = null;
  }

  final sheetTopics = [
    for (final t in (filters['topics'] as List?) ?? const []) t.toString(),
  ];

  return PartnerFilterParams(
    nativeLanguage: apiNative,
    learningLanguage: apiLearning,
    gender: chips.gender ?? _str(filters['gender'])?.toLowerCase(),
    minAge: (filters['minAge'] as num?)?.toInt(),
    maxAge: (filters['maxAge'] as num?)?.toInt(),
    onlineOnly: filters['onlineOnly'] == true || chips.online,
    // Country is a VIP filter (2026-10-18); the server ignores it otherwise.
    country: isVip ? _str(filters['country']) : null,
    languageLevel: _str(filters['languageLevel']),
    search: (search != null && search.isNotEmpty) ? search : null,
    sort: chips.sort,
    activeWithin: segment.activeWithin,
    // "New members" is the same 7-day window whether it comes from the
    // segment or the sheet's toggle (it used to be filtered on the client).
    joinedWithin:
        segment.joinedWithin ?? (filters['newUsersOnly'] == true ? '7d' : null),
    topics: chips.topicId != null ? [chips.topicId!] : sheetTopics,
    topicsAtLeast: (filters['topicsAtLeast'] as num?)?.toInt() ?? 0,
    sameCity: chips.sameCity,
  );
}

/// Whether anything narrows the Partners list, so an empty result can offer
/// "clear filters".
bool hasActivePartnerFilters(
  Map<String, dynamic> filters,
  PartnerSegment segment,
  PartnerQuickChips chips,
) {
  final f = filters;
  return f['gender'] != null ||
      f['nativeLanguage'] != null ||
      f['learningLanguage'] != null ||
      f['languageLevel'] != null ||
      f['country'] != null ||
      (f['minAge'] != null && f['minAge'] != 18) ||
      (f['maxAge'] != null && f['maxAge'] != 100) ||
      f['onlineOnly'] == true ||
      f['newUsersOnly'] == true ||
      ((f['topics'] as List?)?.isNotEmpty ?? false) ||
      ((f['topicsAtLeast'] as num?) ?? 0) > 0 ||
      segment != PartnerSegment.all ||
      chips.isActive;
}
