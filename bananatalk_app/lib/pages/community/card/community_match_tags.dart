import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

enum MatchTagKind { isNew, similarAge, sharedTopic, repliesFast }

class MatchTag {
  const MatchTag(this.kind, [this.value]);

  final MatchTagKind kind;

  /// The topic name, for [MatchTagKind.sharedTopic]. Null for every other kind.
  final String? value;
}

int? _ageOf(Community user) {
  final year = int.tryParse(user.birth_year);
  if (year == null || year <= 1900) return null;
  return DateTime.now().year - year;
}

/// Why this person is worth tapping, at most two reasons, derived on-device
/// from data the list payload already carries. No network, no new field.
///
/// Order is priority, not preference: recency first (it is the most perishable
/// fact), then the two "we have something in common" signals, then
/// responsiveness. Returning fewer than two -- or none -- is a correct answer;
/// the strip renders nothing rather than inventing a reason.
List<MatchTag> communityMatchTags(Community candidate, Community? viewer) {
  final tags = <MatchTag>[];

  if (candidate.isNewUser) tags.add(const MatchTag(MatchTagKind.isNew));

  if (viewer != null) {
    final mine = _ageOf(viewer);
    final theirs = _ageOf(candidate);
    if (mine != null && theirs != null && (mine - theirs).abs() <= 3) {
      tags.add(const MatchTag(MatchTagKind.similarAge));
    }

    final shared = candidate.topics.firstWhere(
      (t) => viewer.topics.contains(t),
      orElse: () => '',
    );
    if (shared.isNotEmpty) tags.add(MatchTag(MatchTagKind.sharedTopic, shared));
  }

  final rate = candidate.responseRate;
  if (rate != null && rate >= 80) tags.add(const MatchTag(MatchTagKind.repliesFast));

  return tags.take(2).toList();
}

/// The tag strip. Renders nothing at all when no tag applies, so an empty
/// strip costs no height.
class CommunityMatchTags extends ConsumerWidget {
  const CommunityMatchTags({super.key, required this.community});

  final Community community;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewer = ref.watch(userProvider).valueOrNull;
    final tags = communityMatchTags(community, viewer);
    if (tags.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Row(
        children: [
          for (final tag in tags)
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(right: 5),
                child: _chip(context, tag),
              ),
            ),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, MatchTag tag) {
    final isBanana = tag.kind == MatchTagKind.isNew;
    final label = switch (tag.kind) {
      MatchTagKind.isNew => 'New',
      MatchTagKind.similarAge => 'Similar age',
      MatchTagKind.sharedTopic => 'Both like ${tag.value}',
      MatchTagKind.repliesFast => 'Replies fast',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: isBanana
            ? AppColors.secondary.withValues(alpha: 0.28)
            : AppColors.primary.withValues(alpha: 0.12),
        borderRadius: AppRadius.borderRound,
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.captionSmall.copyWith(
          fontWeight: FontWeight.w700,
          color: isBanana ? AppColors.secondaryDark : AppColors.primaryDark,
        ),
      ),
    );
  }
}
