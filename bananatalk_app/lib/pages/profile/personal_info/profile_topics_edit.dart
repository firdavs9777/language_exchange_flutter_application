import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/models/community/topic_model.dart';
import 'package:bananatalk_app/pages/profile/widgets/edit_screen_scaffold.dart';
import 'package:bananatalk_app/pages/profile/widgets/profile_snackbar.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

/// Screen for selecting/editing user's topics of interest
class ProfileTopicsEdit extends ConsumerStatefulWidget {
  final List<String> initialTopics;
  final bool isStandalone;
  final void Function(List<String>)? onTopicsChanged;
  final String? title;
  final String? subtitle;
  final int maxTopics;

  const ProfileTopicsEdit({
    super.key,
    this.initialTopics = const [],
    this.isStandalone = true,
    this.onTopicsChanged,
    this.title,
    this.subtitle,
    this.maxTopics = 10,
  });

  @override
  ConsumerState<ProfileTopicsEdit> createState() => _ProfileTopicsEditState();
}

class _ProfileTopicsEditState extends ConsumerState<ProfileTopicsEdit> {
  late Set<String> _selectedTopics;
  late Set<String> _initialTopics;
  String? _selectedCategory;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedTopics = Set.from(widget.initialTopics);
    _initialTopics = Set.from(widget.initialTopics);
  }

  bool get _hasChanges {
    if (_selectedTopics.length != _initialTopics.length) return true;
    return !_selectedTopics.containsAll(_initialTopics);
  }

  List<Topic> get _filteredTopics {
    if (_selectedCategory == null) {
      return Topic.defaultTopics;
    }
    return Topic.defaultTopics
        .where((t) => t.category == _selectedCategory)
        .toList();
  }

  void _toggleTopic(String topicId) {
    final l10n = AppLocalizations.of(context)!;
    HapticFeedback.selectionClick();

    setState(() {
      if (_selectedTopics.contains(topicId)) {
        _selectedTopics.remove(topicId);
      } else {
        if (_selectedTopics.length < widget.maxTopics) {
          _selectedTopics.add(topicId);
        } else {
          HapticFeedback.heavyImpact();
          showProfileSnackBar(
            context,
            message: l10n.maxTopicsAllowed(widget.maxTopics),
            type: ProfileSnackBarType.warning,
          );
          return;
        }
      }
    });

    widget.onTopicsChanged?.call(_selectedTopics.toList());
  }

  Future<void> _saveTopics() async {
    if (_isSaving) return;
    final l10n = AppLocalizations.of(context)!;

    HapticFeedback.lightImpact();
    setState(() => _isSaving = true);

    try {
      final service = ref.read(communityServiceProvider);
      await service.updateMyTopics(_selectedTopics.toList());

      ref.invalidate(userProvider);

      if (!mounted) return;
      showProfileSnackBar(
        context,
        message: l10n.topicsUpdatedSuccessfully,
        type: ProfileSnackBarType.success,
      );
      Navigator.pop(context, _selectedTopics.toList());
    } catch (e) {
      if (!mounted) return;
      showProfileSnackBar(
        context,
        message:
            '${l10n.failedToUpdateTopics}: ${e.toString().replaceFirst('Exception: ', '')}',
        type: ProfileSnackBarType.error,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (widget.isStandalone) {
      final canSave = _hasChanges && !_isSaving;
      // EditScreenScaffold is used for the AppBar pill-save button and title.
      // The body is the full-height _buildContent widget which uses Expanded
      // internally for the topic grid, so showBottomSaveButton is false and
      // the body fills the available space directly without scroll wrapping.
      // We override the scaffold's body slot with a custom layout that lets
      // _buildContent expand correctly.
      return _StandaloneTopicsScaffold(
        title: widget.title ?? l10n.editInterests,
        canSave: canSave,
        isSaving: _isSaving,
        onSave: _saveTopics,
        child: _buildContent(l10n),
      );
    }

    return _buildContent(l10n);
  }

  Widget _buildContent(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Counter card
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: _buildCounterCard(l10n),
        ),

        if (widget.subtitle != null) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              widget.subtitle!,
              style: context.bodySmall.copyWith(color: context.textSecondary),
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Category filter chips
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildCategoryChip(null, l10n.all, Icons.apps_rounded),
              ...Topic.categories.map(
                (cat) => _buildCategoryChip(
                  cat,
                  Topic.getCategoryLabel(cat),
                  _getCategoryIcon(cat),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Topics grid
        Expanded(
          child: _filteredTopics.isEmpty
              ? _buildEmptyState(l10n)
              : GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.6,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _filteredTopics.length,
                  itemBuilder: (context, index) {
                    final topic = _filteredTopics[index];
                    final isSelected = _selectedTopics.contains(topic.id);
                    final atLimit = _selectedTopics.length >= widget.maxTopics;

                    return _TopicCard(
                      topic: topic,
                      isSelected: isSelected,
                      isDisabled: !isSelected && atLimit,
                      onTap: () => _toggleTopic(topic.id),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ========== COUNTER CARD ==========
  Widget _buildCounterCard(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedCount = _selectedTopics.length;
    final progress = selectedCount / widget.maxTopics;
    final atLimit = selectedCount >= widget.maxTopics;

    final color = atLimit ? const Color(0xFFFF9800) : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: isDark ? 0.18 : 0.12),
            color.withValues(alpha: isDark ? 0.06 : 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.3 : 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  atLimit ? Icons.check_circle_rounded : Icons.favorite_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      atLimit ? 'Maximum reached' : 'Pick your interests',
                      style: context.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      atLimit
                          ? 'Deselect one to choose another'
                          : 'Tap topics that match your vibe',
                      style: context.captionSmall.copyWith(
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$selectedCount / ${widget.maxTopics}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: color.withValues(alpha: isDark ? 0.18 : 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== CATEGORY CHIP ==========
  Widget _buildCategoryChip(String? category, String label, IconData icon) {
    final isSelected = _selectedCategory == category;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedCategory = category);
          },
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF00BFA5), Color(0xFF00897B)],
                    )
                  : null,
              color: isSelected
                  ? null
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : context.containerColor),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : context.dividerColor.withValues(alpha: 0.5),
                width: 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: isSelected ? Colors.white : context.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : context.textPrimary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('hobby') || lower.contains('hobb')) {
      return Icons.palette_rounded;
    }
    if (lower.contains('sport')) return Icons.sports_basketball_rounded;
    if (lower.contains('music')) return Icons.music_note_rounded;
    if (lower.contains('food')) return Icons.restaurant_rounded;
    if (lower.contains('travel')) return Icons.flight_rounded;
    if (lower.contains('tech')) return Icons.devices_rounded;
    if (lower.contains('art')) return Icons.brush_rounded;
    if (lower.contains('book') || lower.contains('read')) {
      return Icons.menu_book_rounded;
    }
    if (lower.contains('movie') || lower.contains('film')) {
      return Icons.movie_rounded;
    }
    if (lower.contains('game')) return Icons.sports_esports_rounded;
    if (lower.contains('lifestyle')) return Icons.spa_rounded;
    if (lower.contains('learn') || lower.contains('study')) {
      return Icons.school_rounded;
    }
    return Icons.category_rounded;
  }

  // ========== EMPTY STATE ==========
  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: context.containerColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 32,
              color: context.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No topics in this category',
            style: context.titleSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: context.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ========== STANDALONE SCAFFOLD ==========
// Thin wrapper that reuses EditScreenScaffold's AppBar (pill Save button)
// but renders the body as a full-height flex container instead of
// SingleChildScrollView, because _buildContent uses Expanded internally.
class _StandaloneTopicsScaffold extends StatelessWidget {
  final String title;
  final bool canSave;
  final bool isSaving;
  final VoidCallback? onSave;
  final Widget child;

  const _StandaloneTopicsScaffold({
    required this.title,
    required this.canSave,
    required this.isSaving,
    required this.onSave,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // We borrow EditScreenScaffold's AppBar style inline rather than wrapping
    // the whole screen, because EditScreenScaffold forces a SingleChildScrollView
    // which conflicts with the Expanded grid inside _buildContent.
    final canTap = canSave && !isSaving && onSave != null;

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: context.surfaceColor,
        foregroundColor: context.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: context.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: canTap ? onSave : null,
              style: TextButton.styleFrom(
                backgroundColor: canTap
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.3),
                disabledBackgroundColor: AppColors.primary.withValues(
                  alpha: 0.2,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      AppLocalizations.of(context)!.save,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: child,
    );
  }
}

// ========== TOPIC CARD ==========
class _TopicCard extends StatelessWidget {
  final Topic topic;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  const _TopicCard({
    required this.topic,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.8),
                    ],
                  )
                : null,
            color: isSelected
                ? null
                : (isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : context.surfaceColor),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : context.dividerColor.withValues(alpha: 0.5)),
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Opacity(
            opacity: isDisabled ? 0.4 : 1.0,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Text(topic.icon, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          topic.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : context.textPrimary,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSelected)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              size: 12,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
