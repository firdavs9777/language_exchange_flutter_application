import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/models/community/topic_model.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';

/// Screen for selecting/editing user's topics of interest
/// Can be used in registration flow or profile editing
class ProfileTopicsEdit extends ConsumerStatefulWidget {
  /// Initial selected topic IDs
  final List<String> initialTopics;

  /// If true, shows as a standalone screen with save button
  /// If false, can be embedded and uses callback
  final bool isStandalone;

  /// Callback when topics are selected (for embedded use)
  final void Function(List<String>)? onTopicsChanged;

  /// Title to show (defaults to "Select Your Interests")
  final String? title;

  /// Subtitle/description
  final String? subtitle;

  /// Maximum topics allowed (default 10)
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
    HapticFeedback.selectionClick();

    setState(() {
      if (_selectedTopics.contains(topicId)) {
        _selectedTopics.remove(topicId);
      } else {
        if (_selectedTopics.length < widget.maxTopics) {
          _selectedTopics.add(topicId);
        } else {
          // Show max limit reached
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Maximum ${widget.maxTopics} topics allowed'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    });

    // Notify parent if callback provided
    widget.onTopicsChanged?.call(_selectedTopics.toList());
  }

  Future<void> _saveTopics() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final service = ref.read(communityServiceProvider);
      await service.updateMyTopics(_selectedTopics.toList());

      // Refresh user data
      ref.invalidate(userProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Topics updated successfully!'),
              ],
            ),
            backgroundColor: const Color(0xFF00BFA5),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context, _selectedTopics.toList());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update topics: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isStandalone) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title ?? 'Edit Interests'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          actions: [
            TextButton(
              onPressed: _isSaving ? null : _saveTopics,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(
                        color: Color(0xFF00BFA5),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
        body: _buildContent(),
      );
    }

    return _buildContent();
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.title != null && !widget.isStandalone)
                Text(
                  widget.title!,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (widget.subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  widget.subtitle!,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[600],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              // Selected count
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00BFA5).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_selectedTopics.length}/${widget.maxTopics} selected',
                  style: TextStyle(
                    color: _selectedTopics.length >= widget.maxTopics
                        ? Colors.orange
                        : const Color(0xFF00BFA5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Category tabs
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _buildCategoryChip(null, 'All'),
              ...Topic.categories.map(
                (cat) => _buildCategoryChip(cat, Topic.getCategoryLabel(cat)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Topics grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
        selectedColor: const Color(0xFF00BFA5),
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: Colors.grey[100],
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00BFA5).withValues(alpha: 0.15)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF00BFA5) : Colors.transparent,
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
                            ? const Color(0xFF00BFA5)
                            : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Checkmark for selected
            if (isSelected)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00BFA5),
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
    );
  }
}
