import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';

/// Quick reaction bar for stories
class StoryReactionBar extends StatefulWidget {
  final String? currentReaction;
  final Function(String) onReact;
  final VoidCallback? onRemoveReaction;

  const StoryReactionBar({
    Key? key,
    this.currentReaction,
    required this.onReact,
    this.onRemoveReaction,
  }) : super(key: key);

  @override
  State<StoryReactionBar> createState() => _StoryReactionBarState();
}

class _StoryReactionBarState extends State<StoryReactionBar> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleExpand,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(30),
        ),
        child: _isExpanded ? _buildExpandedBar() : _buildCollapsedBar(),
      ),
    );
  }

  Widget _buildCollapsedBar() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.currentReaction != null) ...[
          Text(
            widget.currentReaction!,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              widget.onRemoveReaction?.call();
            },
            child: const Icon(Icons.close, color: Colors.white, size: 16),
          ),
        ] else ...[
          const Icon(Icons.favorite_border, color: Colors.white, size: 24),
          const SizedBox(width: 4),
          const Text(
            'React',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ],
    );
  }

  Widget _buildExpandedBar() {
    return Wrap(
      spacing: 8,
      children: [
        for (final emoji in StoryReactionEmojis.all)
          GestureDetector(
            onTap: () {
              widget.onReact(emoji);
              _toggleExpand();
            },
            child: AnimatedScale(
              scale: widget.currentReaction == emoji ? 1.3 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: widget.currentReaction == emoji
                    ? BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      )
                    : null,
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Floating reaction animation
class StoryReactionAnimation extends StatefulWidget {
  final String emoji;
  final VoidCallback onComplete;

  const StoryReactionAnimation({
    Key? key,
    required this.emoji,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<StoryReactionAnimation> createState() => _StoryReactionAnimationState();
}

class _StoryReactionAnimationState extends State<StoryReactionAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _positionAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.5), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.5, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _opacityAnimation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.3, curve: Curves.easeIn),
      ),
    );

    _positionAnimation = Tween(
      begin: const Offset(0, 0),
      end: const Offset(0, -100),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward().then((_) {
      widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: _positionAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Text(
                widget.emoji,
                style: const TextStyle(fontSize: 80),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Reactions summary row
class StoryReactionsSummary extends StatelessWidget {
  final List<StoryReaction> reactions;
  final int totalCount;
  final VoidCallback? onTap;

  const StoryReactionsSummary({
    Key? key,
    required this.reactions,
    required this.totalCount,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (totalCount == 0) return const SizedBox.shrink();

    // Get unique emojis (up to 3)
    final uniqueEmojis = reactions
        .map((r) => r.emoji)
        .toSet()
        .take(3)
        .toList();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...uniqueEmojis.map((emoji) => Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Text(emoji, style: const TextStyle(fontSize: 14)),
            )),
            const SizedBox(width: 4),
            Text(
              totalCount.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

