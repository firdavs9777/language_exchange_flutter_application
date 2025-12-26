import 'package:flutter/material.dart';
import 'package:bananatalk_app/services/moments_service.dart';

class SaveMomentButton extends StatefulWidget {
  final String momentId;
  final bool initialSaved;
  final int initialSaveCount;
  final VoidCallback? onSaveChanged;
  final bool showCount;
  final double iconSize;
  final Color? savedColor;
  final Color? unsavedColor;

  const SaveMomentButton({
    Key? key,
    required this.momentId,
    this.initialSaved = false,
    this.initialSaveCount = 0,
    this.onSaveChanged,
    this.showCount = false,
    this.iconSize = 24,
    this.savedColor,
    this.unsavedColor,
  }) : super(key: key);

  @override
  State<SaveMomentButton> createState() => _SaveMomentButtonState();
}

class _SaveMomentButtonState extends State<SaveMomentButton>
    with SingleTickerProviderStateMixin {
  late bool _isSaved;
  late int _saveCount;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _isSaved = widget.initialSaved;
    _saveCount = widget.initialSaveCount;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _toggleSave() async {
    if (_isLoading) return;

    // Optimistic update
    setState(() {
      _isSaved = !_isSaved;
      _saveCount = _isSaved ? _saveCount + 1 : _saveCount - 1;
    });

    // Play animation
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    setState(() => _isLoading = true);

    try {
      final result = await MomentsService.toggleSave(
        momentId: widget.momentId,
        currentlySaved: !_isSaved, // Note: we already toggled
      );

      if (mounted) {
        if (result['success'] != true) {
          // Revert on failure
          setState(() {
            _isSaved = !_isSaved;
            _saveCount = _isSaved ? _saveCount + 1 : _saveCount - 1;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Failed to save moment'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          // Update with server values if available
          if (result['data'] != null) {
            setState(() {
              _saveCount = result['data']['saveCount'] ?? _saveCount;
              _isSaved = result['data']['isSaved'] ?? _isSaved;
            });
          }
          widget.onSaveChanged?.call();
        }
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        // Revert on error
        setState(() {
          _isSaved = !_isSaved;
          _saveCount = _isSaved ? _saveCount + 1 : _saveCount - 1;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final savedColor = widget.savedColor ?? Theme.of(context).primaryColor;
    final unsavedColor = widget.unsavedColor ?? Colors.grey[600];

    return GestureDetector(
      onTap: _toggleSave,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isSaved ? Icons.bookmark : Icons.bookmark_border,
              size: widget.iconSize,
              color: _isSaved ? savedColor : unsavedColor,
            ),
            if (widget.showCount && _saveCount > 0) ...[
              const SizedBox(width: 4),
              Text(
                _formatCount(_saveCount),
                style: TextStyle(
                  fontSize: 12,
                  color: _isSaved ? savedColor : unsavedColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

/// Share moment button with share functionality
class ShareMomentButton extends StatefulWidget {
  final String momentId;
  final int initialShareCount;
  final bool showCount;
  final double iconSize;
  final Color? color;

  const ShareMomentButton({
    Key? key,
    required this.momentId,
    this.initialShareCount = 0,
    this.showCount = false,
    this.iconSize = 24,
    this.color,
  }) : super(key: key);

  @override
  State<ShareMomentButton> createState() => _ShareMomentButtonState();
}

class _ShareMomentButtonState extends State<ShareMomentButton> {
  late int _shareCount;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _shareCount = widget.initialShareCount;
  }

  Future<void> _shareMoment() async {
    if (_isSharing) return;

    setState(() => _isSharing = true);

    try {
      // Track share on backend
      final result = await MomentsService.shareMoment(momentId: widget.momentId);

      if (result['success'] == true) {
        setState(() {
          _shareCount = result['shareCount'] ?? _shareCount + 1;
        });
      }

      // Get shareable link
      final link = MomentsService.getShareableLink(widget.momentId);

      if (mounted) {
        // Show share options
        _showShareOptions(link);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  void _showShareOptions(String link) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Share Moment',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy Link'),
              onTap: () {
                // Copy to clipboard
                // Clipboard.setData(ClipboardData(text: link));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copied!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share via...'),
              onTap: () {
                Navigator.pop(context);
                // Use share_plus package for native sharing
                // Share.share('Check out this moment! $link');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Colors.grey[600];

    return GestureDetector(
      onTap: _shareMoment,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _isSharing
              ? SizedBox(
                  width: widget.iconSize,
                  height: widget.iconSize,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                )
              : Icon(
                  Icons.share_outlined,
                  size: widget.iconSize,
                  color: color,
                ),
          if (widget.showCount && _shareCount > 0) ...[
            const SizedBox(width: 4),
            Text(
              _formatCount(_shareCount),
              style: TextStyle(
                fontSize: 12,
                color: color,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

