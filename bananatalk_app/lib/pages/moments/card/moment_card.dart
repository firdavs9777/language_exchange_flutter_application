import 'package:bananatalk_app/pages/community/single/single_community_screen.dart';
import 'package:bananatalk_app/pages/moments/card/moment_card_double_tap.dart';
import 'package:bananatalk_app/pages/moments/card/moment_card_gradient.dart';
import 'package:bananatalk_app/pages/moments/card/moment_card_header.dart';
import 'package:bananatalk_app/pages/moments/card/moment_card_media.dart';
import 'package:bananatalk_app/pages/moments/corrections/correction_sheet.dart';
import 'package:bananatalk_app/pages/moments/create/create_moment.dart';
import 'package:bananatalk_app/pages/moments/single/single_moment.dart';
import 'package:bananatalk_app/pages/moments/viewer/video_player_widget.dart';
import 'package:bananatalk_app/pages/moments/feed/muted_users_provider.dart';
import 'package:bananatalk_app/pages/moments/widgets/moments_snackbar.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:bananatalk_app/services/moments_service.dart' as api;
import 'package:bananatalk_app/services/ad_service.dart';
import 'package:bananatalk_app/providers/provider_root/comments_providers.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:bananatalk_app/widgets/report_dialog.dart';
import 'package:bananatalk_app/widgets/language_selection/show_language_picker.dart';
import 'package:bananatalk_app/widgets/moment_translate_chip.dart';
import 'package:bananatalk_app/widgets/translated_moment_widget.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';

class MomentCard extends ConsumerStatefulWidget {
  final Moments moments;
  final VoidCallback? onRefresh;

  const MomentCard({super.key, required this.moments, this.onRefresh});

  @override
  _MomentCardState createState() => _MomentCardState();
}

class _MomentCardState extends ConsumerState<MomentCard> {
  bool isLiked = false;
  late int likeCount;
  bool isSaved = false;
  bool isExpanded = false;
  bool _likePending = false;
  bool _showTranslation = false;
  // Target language picked when the user opened the translate chip — feeds
  // into TranslatedMomentWidget so it skips auto-detect.
  String? _translationTargetCode;
  String _cachedUserId = '';
  final GlobalKey _likeButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    likeCount = widget.moments.likeCount;
    _initLikeStatus();
    _loadSavedStatus();
  }

  @override
  void didUpdateWidget(covariant MomentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // MomentsFeedWidget keys each card with a stable ValueKey(id), so this
    // State survives feed refetches (e.g. invalidateMomentFeeds landing
    // after another user's like/comment) — resync the local like/save
    // snapshot from the fresh `widget.moments` instead of silently going
    // stale until the widget is destroyed/recreated. Mirrors
    // `_CommentItemState.didUpdateWidget` in comments_main.dart. Only
    // fires when the same moment's underlying object actually changed
    // (not on every rebuild), and skips the like/count resync while a
    // like request is in flight so we don't clobber the optimistic update
    // with a stale server snapshot.
    if (oldWidget.moments.id != widget.moments.id ||
        identical(oldWidget.moments, widget.moments)) {
      return;
    }
    if (_cachedUserId.isNotEmpty) {
      if (!_likePending) {
        likeCount = widget.moments.likeCount;
        isLiked = widget.moments.likedUsers?.contains(_cachedUserId) ?? false;
      }
      isSaved = widget.moments.savedBy.contains(_cachedUserId);
    }
  }

  Future<void> _initLikeStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getString('userId');
    if (mounted && currentUserId != null) {
      setState(() {
        isLiked = widget.moments.likedUsers?.contains(currentUserId) ?? false;
        _cachedUserId = currentUserId;
      });
    }
  }

  Future<void> _loadSavedStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getString('userId');
    if (mounted && currentUserId != null) {
      setState(() {
        isSaved = widget.moments.savedBy.contains(currentUserId);
      });
    }
  }

  Future<void> _toggleSave() async {
    final previousSaved = isSaved;
    setState(() => isSaved = !isSaved);

    final result = await api.MomentsService.toggleSave(
      momentId: widget.moments.id,
      currentlySaved: previousSaved,
    );

    if (result['success'] == true) {
      if (mounted) {
        showMomentsSnackBar(
          context,
          message: isSaved
              ? AppLocalizations.of(context)!.momentSaved
              : AppLocalizations.of(context)!.momentUnsaved,
          type: MomentsSnackBarType.success,
          duration: const Duration(seconds: 1),
        );
      }
    } else {
      if (mounted) {
        setState(() => isSaved = previousSaved);
        showMomentsSnackBar(
          context,
          message: result['error'] ?? AppLocalizations.of(context)!.failedToSave,
          type: MomentsSnackBarType.error,
        );
      }
    }
  }

  void toggleLike() async {
    if (_likePending) return;
    _likePending = true;

    final previousLiked = isLiked;
    final previousCount = likeCount;

    setState(() {
      if (isLiked) {
        likeCount--;
      } else {
        likeCount++;
      }
      isLiked = !isLiked;
    });

    try {
      Map<String, dynamic> result;
      if (previousLiked) {
        result = await ref
            .read(momentsServiceProvider)
            .dislikeMoment(widget.moments.id);
      } else {
        result = await ref
            .read(momentsServiceProvider)
            .likeMoment(widget.moments.id);
      }

      if (mounted) {
        setState(() {
          isLiked = result['isLiked'] ?? !previousLiked;
          likeCount = result['likeCount'] ?? previousCount;
        });
        invalidateMomentFeeds(ref);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLiked = previousLiked;
          likeCount = previousCount;
        });
        showMomentsSnackBar(
          context,
          message: e.toString().replaceFirst('Exception: ', ''),
          type: MomentsSnackBarType.error,
          duration: const Duration(seconds: 2),
        );
      }
    } finally {
      _likePending = false;
    }
  }

  /// Like-only variant for double-tap-to-like (Instagram-style): a no-op on
  /// the like state when the post is already liked, so an accidental
  /// double-tap on an already-liked post never silently unlikes it. The
  /// heart-burst animation in [MomentCardDoubleTap] still plays either way.
  void likeOnlyDoubleTap() {
    if (isLiked) return;
    toggleLike();
  }

  void _showReactionPicker(BuildContext context) {
    final renderBox =
        _likeButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final buttonPos = renderBox.localToGlobal(Offset.zero);
    final overlay = Overlay.of(context);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => entry.remove(),
              behavior: HitTestBehavior.opaque,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            left: buttonPos.dx - 20,
            top: buttonPos.dy - 52,
            child: Material(
              elevation: 12,
              shadowColor: Colors.black26,
              borderRadius: BorderRadius.circular(28),
              color: Theme.of(this.context).colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: ['❤️', '🔥', '😂', '😢', '😮', '👏'].map((emoji) {
                    return GestureDetector(
                      onTap: () {
                        entry.remove();
                        _reactToMoment(emoji);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(emoji, style: const TextStyle(fontSize: 28)),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(entry);
  }

  Future<void> _reactToMoment(String emoji) async {
    try {
      await api.MomentsService.reactToMoment(
        momentId: widget.moments.id,
        emoji: emoji,
      );
      invalidateMomentFeeds(ref);
    } catch (e) {
      debugPrint('React to moment error: $e');
    }
  }

  Map<String, int> _groupMomentReactions() {
    final map = <String, int>{};
    for (final r in widget.moments.reactions) {
      map[r.emoji] = (map[r.emoji] ?? 0) + 1;
    }
    return Map.fromEntries(
      map.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  String _getCurrentUserId() => _cachedUserId;

  /// Opens the full detail screen for this moment. Fetches a fresh copy of
  /// the moment (so the like/comment counts shown in the detail screen
  /// reflect the latest server state even if this card is stale) and
  /// refreshes its comments before pushing. Shared by all three tap
  /// targets that open the detail screen (card body, comment-icon button,
  /// "N comments" text) so they behave identically instead of two of them
  /// pushing the stale `widget.moments` snapshot directly.
  Future<void> _openMomentDetail() async {
    final singleMoment = await ref
        .read(momentsServiceProvider)
        .getSingleMoment(id: widget.moments.id);

    ref.refresh(commentsProvider(singleMoment.id));

    // SingleMoment actually renders comments via CommentsMain(paginated:
    // true) (paginatedCommentsProvider), not the plain commentsProvider
    // above (that one only serves the non-paginated profile moments path).
    // Refresh it too so reopening a moment after e.g. liking/replying
    // elsewhere shows current comments — guarded to page <= 1 (mirrors
    // create_comment.dart / single_moment.dart's poll timer) so we don't
    // blow away pages the user already loaded via "Load more comments".
    // Gated on `ref.exists` so a first-ever open doesn't lazily spin up a
    // provider we're about to immediately navigate away from watching.
    if (ref.exists(paginatedCommentsProvider(singleMoment.id))) {
      final paginatedState =
          ref.read(paginatedCommentsProvider(singleMoment.id)).valueOrNull;
      if (paginatedState == null || paginatedState.page <= 1) {
        ref
            .read(paginatedCommentsProvider(singleMoment.id).notifier)
            .refresh();
      }
    }

    if (!mounted) return;
    await Navigator.push(
      context,
      AppPageRoute(
        builder: (context) => SingleMoment(moment: singleMoment),
      ),
    );

    // Throttled interstitial when returning from a moment (every 3rd
    // open, min 90s apart) — see AdService.maybeShowInterstitial.
    AdService().maybeShowInterstitial(
      everyN: 3,
      minGap: const Duration(seconds: 90),
    );
  }

  void _shareMoment(BuildContext context, String id) {
    final momentText = AppLocalizations.of(context)!.checkOutMoment;
    final momentUrl = 'https://banatalk.com/moment/$id';
    Share.share('$momentText\n\n$momentUrl');
  }

  Future<void> _suggestCorrection(BuildContext context) async {
    await showCorrectionSheet(
      context,
      momentText: widget.moments.description,
      onSubmit: (original, corrected, explanation) async {
        await ref.read(commentsServiceProvider).createComment(
              title: ' ',
              id: widget.moments.id,
              correction: {
                'originalText': original,
                'correctedText': corrected,
                if (explanation != null) 'explanation': explanation,
              },
            );
        ref.invalidate(commentsProvider(widget.moments.id));
        invalidateMomentFeeds(ref);
        if (mounted) {
          showMomentsSnackBar(
            this.context,
            message: AppLocalizations.of(this.context)!.commentAddedSuccessfully,
            type: MomentsSnackBarType.success,
          );
        }
      },
    );
  }

  // Picker-first translate flow — opens the full language picker, and only
  // expands the translation panel once the user has chosen a target. Avoids
  // the surprise of seeing "Translation unavailable" when the auto-detected
  // target happened to match the original language.
  Future<void> _handleTranslateChipTap() async {
    final picked = await showLanguagePickerSheet(context);
    if (picked == null || !mounted) return;
    debugPrint('🌐 [moment-card] user picked '
        'code=${picked.code} name=${picked.name} '
        'momentId=${widget.moments.id} '
        'momentLanguage=${widget.moments.language}');
    setState(() {
      _translationTargetCode = picked.code;
      _showTranslation = true;
    });
  }

  void _showMoreOptions(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getString('userId');
    final isOwnMoment = currentUserId == widget.moments.user.id;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.dividerColor,
                  borderRadius: AppRadius.borderXS,
                ),
              ),
              ListTile(
                leading: Icon(
                  isSaved ? Icons.bookmark : Icons.bookmark_outline,
                  color: const Color(0xFF00BFA5),
                ),
                title: Text(
                  isSaved
                      ? AppLocalizations.of(context)!.removeFromSaved
                      : AppLocalizations.of(context)!.saveMoment,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _toggleSave();
                },
              ),
              ListTile(
                leading: const Icon(Icons.share, color: Color(0xFF00BFA5)),
                title: Text(AppLocalizations.of(context)!.share),
                onTap: () {
                  Navigator.pop(context);
                  _shareMoment(context, widget.moments.id);
                },
              ),
              if (!isOwnMoment)
                ListTile(
                  leading: const Icon(Icons.visibility_off_outlined),
                  title: Text(AppLocalizations.of(context)!.hideThisUser),
                  onTap: () async {
                    Navigator.pop(context);
                    await ref
                        .read(mutedMomentsProvider.notifier)
                        .mute(widget.moments.user.id);
                    if (!mounted) return;
                    showMomentsSnackBar(
                      context,
                      message: AppLocalizations.of(context)!.momentsHidden,
                      type: MomentsSnackBarType.success,
                    );
                  },
                ),
              if (!isOwnMoment)
                ListTile(
                  leading: const Icon(Icons.spellcheck_rounded, color: Color(0xFF00BFA5)),
                  title: const Text('Suggest a correction'),
                  onTap: () {
                    Navigator.pop(context);
                    _suggestCorrection(context);
                  },
                ),
              if (!isOwnMoment)
                ListTile(
                  leading: Icon(Icons.flag_outlined, color: Colors.orange[700]),
                  title: Text(AppLocalizations.of(context)!.reportMoment),
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) => ReportDialog(
                        type: 'moment',
                        reportedId: widget.moments.id,
                        reportedUserId: widget.moments.user.id,
                      ),
                    );
                  },
                ),
              if (!isOwnMoment)
                ListTile(
                  leading: Icon(
                    Icons.report_problem,
                    color: Colors.orange[700],
                  ),
                  title: Text(AppLocalizations.of(context)!.reportUser),
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) => ReportDialog(
                        type: 'user',
                        reportedId: widget.moments.user.id,
                        reportedUserId: widget.moments.user.id,
                      ),
                    );
                  },
                ),
              if (isOwnMoment) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.blue),
                  title: Text(AppLocalizations.of(context)!.edit),
                  onTap: () async {
                    Navigator.pop(context);
                    final result = await Navigator.push(
                      context,
                      AppPageRoute(
                        builder: (context) => CreateMoment(
                          momentToEdit: widget.moments,
                        ),
                      ),
                    );
                    if (result == true) {
                      widget.onRefresh?.call();
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: Text(
                    AppLocalizations.of(context)!.delete,
                    style: const TextStyle(color: Colors.red),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    final l10n = AppLocalizations.of(context)!;
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: Text(l10n.deleteMoment),
                        content: Text(l10n.thisActionCannotBeUndone),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(l10n.cancel),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: Text(l10n.delete),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true && mounted) {
                      try {
                        await ref
                            .read(momentsServiceProvider)
                            .deleteUserMoment(id: widget.moments.id);
                        final l10n = AppLocalizations.of(context)!;
                        showMomentsSnackBar(
                          context,
                          message: l10n.momentDeleted,
                        );
                        widget.onRefresh?.call();
                      } catch (e) {
                        showMomentsSnackBar(
                          context,
                          message: 'Error: $e',
                          type: MomentsSnackBarType.error,
                        );
                      }
                    }
                  },
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final fullText = widget.moments.description;
    final shouldShowMore = fullText.length > 150;
    final displayText = !isExpanded && shouldShowMore
        ? '${fullText.substring(0, 150)}...'
        : fullText;

    final isGradient =
        (widget.moments.mediaType == 'text' ||
            widget.moments.backgroundColor.isNotEmpty) &&
        widget.moments.images.isEmpty &&
        !widget.moments.hasVideo;

    return GestureDetector(
      onTap: _openMomentDetail,
      child: Container(
        margin: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            MomentCardHeader(
              moment: widget.moments,
              onAvatarTap: () async {
                final community = await ref
                    .read(communityServiceProvider)
                    .getSingleCommunity(id: widget.moments.user.id);

                if (community == null) {
                  if (mounted) {
                    showMomentsSnackBar(
                      context,
                      message: AppLocalizations.of(context)!.userNotFound,
                    );
                  }
                  return;
                }

                Navigator.push(
                  context,
                  AppPageRoute(
                    builder: (context) =>
                        SingleCommunity(community: community),
                  ),
                );
              },
              onMenuTap: () => _showMoreOptions(context),
            ),

            // ── Caption (skipped for gradient posts) ────────────────────────
            // The original text always shows; the translation panel
            // expands directly underneath when the user opts in via the
            // inline "Translate" chip (more discoverable than the action
            // row's translate icon was).
            if (!isGradient)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayText,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (shouldShowMore)
                      GestureDetector(
                        onTap: () {
                          setState(() => isExpanded = !isExpanded);
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            isExpanded
                                ? AppLocalizations.of(context)!.showLess
                                : AppLocalizations.of(context)!.showMore,
                            style: context.labelMedium
                                .copyWith(color: context.textSecondary),
                          ),
                        ),
                      ),
                    if (!_showTranslation)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: MomentTranslateChip(
                          onTap: _handleTranslateChipTap,
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: TranslatedMomentWidget(
                          momentId: widget.moments.id,
                          originalText: displayText,
                          originalLanguage: widget.moments.language,
                          existingTranslations:
                              widget.moments.translations.isNotEmpty
                                  ? widget.moments.translations
                                  : null,
                          initialTargetCode: _translationTargetCode,
                          onTranslationAdded: () {
                            widget.onRefresh?.call();
                          },
                          onDismiss: () => setState(() {
                            _showTranslation = false;
                            _translationTargetCode = null;
                          }),
                        ),
                      ),
                  ],
                ),
              ),

            // ── Media area ──────────────────────────────────────────────────
            if (isGradient)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MomentCardDoubleTap(
                    onDoubleTap: likeOnlyDoubleTap,
                    child: MomentCardGradient(moment: widget.moments),
                  ),
                  // Translate chip for text/gradient moments too (e.g. a
                  // prompt answer written in the target language) — these
                  // previously had no translate affordance.
                  if (widget.moments.description.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                      child: !_showTranslation
                          ? MomentTranslateChip(onTap: _handleTranslateChipTap)
                          : TranslatedMomentWidget(
                              momentId: widget.moments.id,
                              originalText: widget.moments.description,
                              originalLanguage: widget.moments.language,
                              existingTranslations:
                                  widget.moments.translations.isNotEmpty
                                      ? widget.moments.translations
                                      : null,
                              initialTargetCode: _translationTargetCode,
                              onTranslationAdded: () {
                                widget.onRefresh?.call();
                              },
                              onDismiss: () => setState(() {
                                _showTranslation = false;
                                _translationTargetCode = null;
                              }),
                            ),
                    ),
                ],
              )
            else if (widget.moments.hasVideo && widget.moments.video != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: MomentCardDoubleTap(
                    onDoubleTap: likeOnlyDoubleTap,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          AppPageRoute(
                            builder: (context) => FullScreenVideoPlayer(
                              video: widget.moments.video!,
                            ),
                          ),
                        );
                      },
                      child: MomentVideoPlayer(
                        video: widget.moments.video!,
                        height: 280,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              )
            else if (widget.moments.hasAudio)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: MomentCardDoubleTap(
                  onDoubleTap: likeOnlyDoubleTap,
                  child: MomentCardMedia(
                    imageUrls: widget.moments.imageUrls,
                    audio: widget.moments.audio,
                  ),
                ),
              )
            else if (widget.moments.imageUrls.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: MomentCardDoubleTap(
                  onDoubleTap: likeOnlyDoubleTap,
                  child: MomentCardMedia(imageUrls: widget.moments.imageUrls),
                ),
              ),

            // ── Actions row ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  GestureDetector(
                    key: _likeButtonKey,
                    onTap: toggleLike,
                    onLongPress: () => _showReactionPicker(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            size: 22,
                            color:
                                isLiked ? AppColors.error : context.iconColor,
                          ),
                          if (likeCount > 0) ...[
                            const SizedBox(width: 4),
                            Text(
                              likeCount > 999
                                  ? '${(likeCount / 1000).toStringAsFixed(1)}k'
                                  : '$likeCount',
                              style: TextStyle(
                                fontSize: 13,
                                color: isLiked
                                    ? AppColors.error
                                    : context.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  _buildActionButton(
                    icon: Icons.chat_bubble_outline,
                    count: widget.moments.commentCount,
                    color: context.iconColor,
                    onTap: _openMomentDetail,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.share_outlined,
                      color: context.iconColor,
                      size: 22,
                    ),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                    onPressed: () =>
                        _shareMoment(context, widget.moments.id),
                  ),
                  IconButton(
                    icon: Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_border,
                      size: 22,
                      color: isSaved ? AppColors.primary : context.iconColor,
                    ),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                    onPressed: _toggleSave,
                  ),
                ],
              ),
            ),

            // NOTE on the correction-count chip: MomentCard does not load
            // this moment's comments (only commentCount, a plain int, comes
            // back on the feed payload), so a client-side "N corrections"
            // chip can't be computed here without an extra fetch per card.
            // Per the Task 7 brief, we skip the chip on the card and only
            // surface the count in the single_moment view, where comments
            // are already loaded via commentsProvider.

            // ── Engagement counts ────────────────────────────────────────────
            if (likeCount > 0 || widget.moments.commentCount > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (likeCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          '$likeCount ${likeCount == 1 ? "like" : "likes"}',
                          style: context.bodySmall
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    if (widget.moments.commentCount > 0)
                      GestureDetector(
                        onTap: _openMomentDetail,
                        child: Text(
                          widget.moments.commentCount == 1
                              ? '1 comment'
                              : '${widget.moments.commentCount} comments',
                          style: context.bodySmall
                              .copyWith(color: context.textMuted),
                        ),
                      ),
                  ],
                ),
              ),

            // ── Reaction chips ───────────────────────────────────────────────
            if (widget.moments.reactions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children:
                      _groupMomentReactions().entries.map((entry) {
                    final currentUserId = _getCurrentUserId();
                    final isMyReaction = widget.moments.reactions.any(
                      (r) =>
                          r.emoji == entry.key &&
                          r.userId == currentUserId,
                    );
                    return GestureDetector(
                      onTap: () => _reactToMoment(entry.key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isMyReaction
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                          border: isMyReaction
                              ? Border.all(
                                  color: AppColors.primary, width: 1)
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(entry.key,
                                style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 4),
                            Text(
                              '${entry.value}',
                              style: TextStyle(
                                  fontSize: 12, color: context.textMuted),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers kept inline (only called from actions row once each)
  // ---------------------------------------------------------------------------

  Widget _buildActionButton({
    required IconData icon,
    required int count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                count > 999
                    ? '${(count / 1000).toStringAsFixed(1)}k'
                    : '$count',
                style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

