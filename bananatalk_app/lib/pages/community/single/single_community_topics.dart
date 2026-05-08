import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/pages/profile/edit/topics_edit.dart';

/// Displays the "Mutual Interests" card on a user's profile detail screen.
///
/// Shows topics the profile owner and the current viewer share (highlighted)
/// alongside non-shared topics (muted), up to 6 visible at a time. A "See
/// all" button opens a full-list dialog when there are more than 6. When
/// either party has no topics, a CTA prompts the viewer to add their own.
class SingleCommunityTopics extends ConsumerWidget {
  final Community community;

  const SingleCommunityTopics({super.key, required this.community});

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Returns the current user's topic list from the Riverpod userProvider.
  ///
  /// userProvider is FutureProvider<Community>; we use valueOrNull so that
  /// loading / error states gracefully degrade to an empty list.
  List<String> _getMyTopics(WidgetRef ref) {
    final myUser = ref.watch(userProvider).valueOrNull;
    return myUser?.topics ?? const <String>[];
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final myTopics = _getMyTopics(ref);
    final theirTopics = community.topics;

    if (theirTopics.isEmpty || myTopics.isEmpty) {
      return _buildEmptyCard(context, ref, l10n);
    }

    final shared = theirTopics.where((t) => myTopics.contains(t)).toList();
    final notShared = theirTopics.where((t) => !myTopics.contains(t)).toList();
    final visible = [...shared, ...notShared].take(6).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: AppRadius.borderLG,
        border: Border.all(color: context.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Text(l10n.mutualInterests, style: context.titleSmall),
          const SizedBox(height: 4),
          // Subtitle: "X interests in common"
          Text(
            l10n.interestsInCommon(shared.length),
            style: context.bodySmall.copyWith(color: context.textSecondary),
          ),
          const SizedBox(height: 12),
          // Chip grid
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: visible.map((topicId) {
              final isShared = shared.contains(topicId);
              return Chip(
                label: Text(topicId),
                avatar: isShared
                    ? const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: Colors.white,
                      )
                    : null,
                backgroundColor: isShared
                    ? AppColors.primary
                    : context.containerColor,
                labelStyle: TextStyle(
                  color: isShared ? Colors.white : context.textSecondary,
                  fontSize: 13,
                ),
                side: BorderSide(
                  color: isShared ? AppColors.primary : context.dividerColor,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              );
            }).toList(),
          ),
          // "See all" button when truncated
          if (theirTopics.length > 6)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () =>
                    _showAllTopics(context, theirTopics, shared, l10n),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(l10n.interestsInCommonSeeAll),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Empty state — viewer has no topics yet
  // ---------------------------------------------------------------------------

  Widget _buildEmptyCard(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: AppRadius.borderLG,
        border: Border.all(color: context.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            l10n.mutualInterests,
            style: context.titleSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            l10n.interestsInCommonAddSubtitle,
            textAlign: TextAlign.center,
            style: context.bodySmall.copyWith(color: context.textMuted),
          ),
          const SizedBox(height: 10),
          TextButton(
            // TODO(C16): verify this navigation — ProfileTopicsEdit is reached
            // via Navigator.push with AppPageRoute in personal_section.dart.
            // No named route exists; using direct push mirrors that pattern.
            onPressed: () => Navigator.push(
              context,
              AppPageRoute(
                builder: (_) => const ProfileTopicsEdit(
                  initialTopics: [],
                  isStandalone: true,
                ),
              ),
            ),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: Text(l10n.interestsInCommonAddCta),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Full-list dialog
  // ---------------------------------------------------------------------------

  void _showAllTopics(
    BuildContext context,
    List<String> all,
    List<String> shared,
    AppLocalizations l10n,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.mutualInterests),
        content: SingleChildScrollView(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: all.map((t) {
              final isShared = shared.contains(t);
              return Chip(
                label: Text(t),
                avatar: isShared
                    ? const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: Colors.white,
                      )
                    : null,
                backgroundColor: isShared ? AppColors.primary : null,
                labelStyle: TextStyle(
                  color: isShared ? Colors.white : null,
                  fontSize: 13,
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
