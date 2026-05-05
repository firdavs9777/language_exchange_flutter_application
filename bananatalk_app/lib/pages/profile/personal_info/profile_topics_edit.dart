import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/models/community/topic_model.dart';
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
  String? _selectedCategory;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedTopics = Set.from(widget.initialTopics);
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.maxTopicsAllowed(widget.maxTopics)),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          );
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(l10n.topicsUpdatedSuccessfully)),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
      Navigator.pop(context, _selectedTopics.toList());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${l10n.failedToUpdateTopics}: '
            '${e.toString().replaceFirst('Exception: ', '')}',
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (widget.isStandalone) {
      final canSave = !_isSaving;
      return Scaffold(
        backgroundColor: context.scaffoldBackground,
        appBar: AppBar(
          title: Text(
            widget.title ?? l10n.editInterests,
            style: context.titleLarge.copyWith(fontWeight: FontWeight.w700),
          ),
          backgroundColor: context.surfaceColor,
          foregroundColor: context.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton(
                onPressed: canSave ? _saveTopics : null,
                style: TextButton.styleFrom(
                  backgroundColor: canSave
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
                child: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        l10n.save,
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
        body: _buildContent(l10n),
      );
    }

    return _buildContent(l10n);
  }

  Widget _buildContent(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: Spacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.title != null && !widget.isStandalone)
                Text(
                  widget.title!,
                  style: context.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (widget.subtitle != null) ...[
                Spacing.gapSM,
                Text(
                  widget.subtitle!,
                  style: context.bodyMedium.copyWith(
                    color: context.textSecondary,
                  ),
                ),
              ],
              Spacing.gapMD,
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  l10n.selectedCount(_selectedTopics.length, widget.maxTopics),
                  style: TextStyle(
                    color: _selectedTopics.length >= widget.maxTopics
                        ? Colors.orange
                        : AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _buildCategoryChip(null, l10n.all),
              ...Topic.categories.map(
                (cat) => _buildCategoryChip(cat, Topic.getCategoryLabel(cat)),
              ),
            ],
          ),
        ),

        Spacing.gapLG,

        Expanded(
          child: GridView.builder(
            padding: Spacing.screenPadding,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _filteredTopics.length,
            itemBuilder: (context, index) {
              final topic = _filteredTopics[index];
              final isSelected = _selectedTopics.contains(topic.id);

              return _TopicCard(
                topic: topic,
                isSelected: isSelected,
                onTap: () => _toggleTopic(topic.id),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String? category, String label) {
    final isSelected = _selectedCategory == category;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() => _selectedCategory = category);
        },
        selectedColor: AppColors.primary,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : context.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: context.containerColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  final Topic topic;
  final bool isSelected;
  final VoidCallback onTap;

  const _TopicCard({
    required this.topic,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.15)
                : context.containerColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Text(
                      topic.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        topic.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? AppColors.primary
                              : context.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
