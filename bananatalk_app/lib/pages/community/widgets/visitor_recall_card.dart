import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/profile/visitors_screen.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/services/profile_visitor_service.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/utils/string_sanitizer.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Compact "people visited your profile" card shown on the Community screen.
///
/// Renders up to 5 recent visitors as an overlapping avatar stack in a single
/// row alongside the count text. Each avatar is individually tappable and
/// navigates to that user's profile via the `/profile/:userId` go_router route.
///
/// Returns [SizedBox.shrink] when there are no visitors so the card is
/// invisible until real data arrives.
class VisitorRecallCard extends ConsumerStatefulWidget {
  const VisitorRecallCard({super.key});

  @override
  ConsumerState<VisitorRecallCard> createState() => _VisitorRecallCardState();
}

class _VisitorRecallCardState extends ConsumerState<VisitorRecallCard> {
  List<Map<String, dynamic>> _visitors = [];
  int _totalCount = 0;
  bool _isLoaded = false;

  // Avatar sizing for the overlapping stack.
  static const double _avatarSize = 38;
  static const double _avatarOverlap = 14; // how much each avatar overlaps

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final myId = ref.read(authServiceProvider).userId;
    if (myId.isEmpty) {
      setState(() => _isLoaded = true);
      return;
    }
    try {
      final result = await ProfileVisitorService.getProfileVisitors(
        userId: myId,
        limit: 5,
      );
      if (!mounted) return;
      if (result['success'] == true) {
        final list = (result['visitors'] as List?) ?? [];
        setState(() {
          _visitors = list
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          _totalCount = (result['count'] as int?) ?? _visitors.length;
          _isLoaded = true;
        });
      } else {
        setState(() => _isLoaded = true);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoaded = true);
    }
  }

  // ---------------------------------------------------------------------------
  // Field helpers — the backend aggregates visitors as:
  //   { user: { _id, name, imageUrls: [String], ... }, lastVisit, visitCount, source }
  // (matches the shape consumed by visitors_screen.dart)
  // ---------------------------------------------------------------------------

  String? _avatarUrl(Map<String, dynamic> v) {
    final user = v['user'];
    if (user is Map) {
      final imageUrls = user['imageUrls'];
      if (imageUrls is List && imageUrls.isNotEmpty) {
        return imageUrls[0]?.toString();
      }
      final images = user['images'];
      if (images is List && images.isNotEmpty) {
        return images[0]?.toString();
      }
      final avatar = user['avatar'];
      if (avatar is String && avatar.isNotEmpty) return avatar;
    }
    final topAvatar = v['avatar'];
    if (topAvatar is String && topAvatar.isNotEmpty) return topAvatar;
    return null;
  }

  String? _userId(Map<String, dynamic> v) {
    final user = v['user'];
    if (user is Map) {
      final id = user['_id'] ?? user['id'];
      if (id != null) return id.toString();
    }
    final visitor = v['visitor'];
    if (visitor is Map) {
      final id = visitor['_id'] ?? visitor['id'];
      if (id != null) return id.toString();
    }
    final topId = v['userId'] ?? v['_id'];
    return topId?.toString();
  }

  String _userName(Map<String, dynamic> v) {
    final user = v['user'];
    if (user is Map) {
      final name = user['name'];
      if (name is String && name.isNotEmpty) return sanitize(name);
    }
    final visitor = v['visitor'];
    if (visitor is Map) {
      final name = visitor['name'];
      if (name is String && name.isNotEmpty) return sanitize(name);
    }
    final topName = v['name'];
    if (topName is String && topName.isNotEmpty) return sanitize(topName);
    return '';
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _visitors.isEmpty) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    final myId = ref.read(authServiceProvider).userId;

    void openVisitors() {
      Navigator.push(
        context,
        AppPageRoute(builder: (_) => ProfileVisitorsScreen(userId: myId)),
      );
    }

    return GestureDetector(
      onTap: openVisitors,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: context.cardBackground,
          borderRadius: AppRadius.borderLG,
          border: Border.all(color: context.dividerColor),
        ),
        child: Row(
          children: [
            _buildAvatarStack(context),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  const Icon(
                    Icons.visibility_outlined,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.visitedYourProfile(_totalCount),
                      style: context.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarStack(BuildContext context) {
    final shown = _visitors.take(5).toList();
    final step = _avatarSize - _avatarOverlap;
    final stackWidth = _avatarSize + (shown.length - 1) * step;

    return SizedBox(
      width: stackWidth,
      height: _avatarSize,
      child: Stack(
        children: [
          for (int i = 0; i < shown.length; i++)
            Positioned(left: i * step, child: _buildAvatar(context, shown[i])),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, Map<String, dynamic> v) {
    final id = _userId(v);
    final avatar = _avatarUrl(v);
    final name = _userName(v);

    return GestureDetector(
      onTap: () {
        if (id != null && id.isNotEmpty) {
          context.push('/profile/$id');
        }
      },
      child: Container(
        width: _avatarSize,
        height: _avatarSize,
        padding: const EdgeInsets.all(
          2,
        ), // ring that separates overlapping avatars
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: context.cardBackground,
        ),
        child: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
          backgroundImage: (avatar != null && avatar.isNotEmpty)
              ? NetworkImage(avatar)
              : null,
          child: (avatar == null || avatar.isEmpty)
              ? Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
