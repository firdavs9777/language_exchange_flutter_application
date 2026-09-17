import 'package:flutter/material.dart';

import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// The topic slugs the server accepts, in display order.
///
/// Must stay in step with `GATHERING_TOPICS` in `lib/gatheringFilters.js`. A
/// value the server does not know is dropped from the query rather than
/// rejected, so a drifted list here fails silently — hence the test that pins
/// the two together.
const kGatheringTopics = <String>[
  'conversation',
  'exam_prep',
  'grammar',
  'pronunciation',
  'culture',
  'media',
  'games',
  'business',
  'travel',
];

/// The time windows, matching `timeWindow()` server-side.
const kGatheringWindows = <String>['today', 'week', 'weekend'];

/// What the learner has narrowed the list to.
///
/// Immutable so a rebuild cannot mutate the filters mid-request, and `==` is
/// defined so the tab can skip a refetch when nothing actually changed.
@immutable
class GatheringFilters {
  const GatheringFilters({this.topic, this.when, this.hasSeat = false});

  final String? topic;
  final String? when;
  final bool hasSeat;

  bool get isEmpty => topic == null && when == null && !hasSeat;

  /// How many chips are lit — drives the "clear" affordance and its count.
  int get activeCount =>
      (topic == null ? 0 : 1) + (when == null ? 0 : 1) + (hasSeat ? 1 : 0);

  GatheringFilters copyWith({
    Object? topic = _unset,
    Object? when = _unset,
    bool? hasSeat,
  }) => GatheringFilters(
    // A sentinel, because null is a meaningful value here: passing
    // `topic: null` must CLEAR the topic, not mean "leave it alone".
    topic: identical(topic, _unset) ? this.topic : topic as String?,
    when: identical(when, _unset) ? this.when : when as String?,
    hasSeat: hasSeat ?? this.hasSeat,
  );

  static const Object _unset = Object();

  @override
  bool operator ==(Object other) =>
      other is GatheringFilters &&
      other.topic == topic &&
      other.when == when &&
      other.hasSeat == hasSeat;

  @override
  int get hashCode => Object.hash(topic, when, hasSeat);
}

/// The display name for a topic slug.
///
/// Top-level so a gathering card can label its chip without constructing a
/// filter bar — the two must read identically, and the only way to guarantee
/// that is for both to call the same function.
String gatheringTopicLabel(AppLocalizations l10n, String topic) =>
    switch (topic) {
      'conversation' => l10n.topicConversation,
      'exam_prep' => l10n.topicExamPrep,
      'grammar' => l10n.topicGrammar,
      'pronunciation' => l10n.topicPronunciation,
      'culture' => l10n.topicCulture,
      'media' => l10n.topicMedia,
      'games' => l10n.topicGames,
      'business' => l10n.topicBusiness,
      'travel' => l10n.topicTravel,
      // A slug the server knows and this build does not: show the raw value
      // rather than mislabel it as Travel.
      _ => topic,
    };

/// A single horizontal row of filter chips above the gatherings list.
///
/// A row rather than a sheet: with three axes and nine topics, a modal would
/// hide the current state behind a tap, and the state is the point — someone
/// looking at an unexpectedly short list needs to see why without opening
/// anything.
class GatheringFilterBar extends StatelessWidget {
  const GatheringFilterBar({
    super.key,
    required this.filters,
    required this.onChanged,
  });

  final GatheringFilters filters;
  final ValueChanged<GatheringFilters> onChanged;

  String _windowLabel(AppLocalizations l10n, String when) => switch (when) {
    'today' => l10n.gatheringToday,
    'week' => l10n.filterThisWeek,
    _ => l10n.filterThisWeekend,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
        children: [
          if (!filters.isEmpty) ...[
            ActionChip(
              key: const Key('filter-clear'),
              avatar: const Icon(Icons.close_rounded, size: 16),
              label: Text(l10n.filterClear(filters.activeCount)),
              onPressed: () => onChanged(const GatheringFilters()),
            ),
            const SizedBox(width: 8),
          ],

          // Seats first: it is the only filter that answers "can I actually
          // join this", which is the question a full list makes urgent.
          FilterChip(
            key: const Key('filter-has-seat'),
            selected: filters.hasSeat,
            onSelected: (v) => onChanged(filters.copyWith(hasSeat: v)),
            label: Text(l10n.filterHasSeat),
            showCheckmark: false,
            avatar: Icon(
              Icons.event_seat_rounded,
              size: 16,
              color: filters.hasSeat
                  ? AppColors.primary
                  : context.textSecondary,
            ),
          ),
          const SizedBox(width: 8),

          for (final w in kGatheringWindows) ...[
            FilterChip(
              key: Key('filter-when-$w'),
              selected: filters.when == w,
              // Tapping the lit chip clears it, so the row needs no separate
              // "any time" option taking up space.
              onSelected: (v) =>
                  onChanged(filters.copyWith(when: v ? w : null)),
              label: Text(_windowLabel(l10n, w)),
              showCheckmark: false,
            ),
            const SizedBox(width: 8),
          ],

          Container(
            width: 1,
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            color: context.dividerColor,
          ),
          const SizedBox(width: 8),

          for (final t in kGatheringTopics) ...[
            FilterChip(
              key: Key('filter-topic-$t'),
              selected: filters.topic == t,
              onSelected: (v) =>
                  onChanged(filters.copyWith(topic: v ? t : null)),
              label: Text(gatheringTopicLabel(l10n, t)),
              showCheckmark: false,
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}
