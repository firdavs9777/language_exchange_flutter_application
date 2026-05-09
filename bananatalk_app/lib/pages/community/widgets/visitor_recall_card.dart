import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/services/profile_visitor_service.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Horizontal scroller card shown on the Community main screen.
///
/// Loads up to 5 recent profile visitors for the current user and renders
/// them as tappable circle-avatars. Tapping navigates to that user's profile
/// via the registered `/profile/:userId` go_router route.
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
    // Primary path: v['user']['imageUrls'][0]
    final user = v['user'];
    if (user is Map) {
      final imageUrls = user['imageUrls'];
      if (imageUrls is List && imageUrls.isNotEmpty) {
        return imageUrls[0]?.toString();
      }
      // Fallback paths used by some older API responses
      final images = user['images'];
      if (images is List && images.isNotEmpty) {
        return images[0]?.toString();
      }
      final avatar = user['avatar'];
      if (avatar is String && avatar.isNotEmpty) return avatar;
    }
    // Top-level fallback (e.g. denormalised responses)
    final topAvatar = v['avatar'];
    if (topAvatar is String && topAvatar.isNotEmpty) return topAvatar;
    return null;
  }

  String? _userId(Map<String, dynamic> v) {
    // Primary: v['user']['_id']
    final user = v['user'];
    if (user is Map) {
      final id = user['_id'] ?? user['id'];
      if (id != null) return id.toString();
    }
    // Fallback for alternative shapes
    final visitor = v['visitor'];
    if (visitor is Map) {
      final id = visitor['_id'] ?? visitor['id'];
      if (id != null) return id.toString();
    }
    final topId = v['userId'] ?? v['_id'];
    return topId?.toString();
  }

  String _userName(Map<String, dynamic> v) {
    // Primary: v['user']['name']
    final user = v['user'];
    if (user is Map) {
      final name = user['name'];
      if (name is String && name.isNotEmpty) return name;
    }
    // Fallback
    final visitor = v['visitor'];
    if (visitor is Map) {
      final name = visitor['name'];
      if (name is String && name.isNotEmpty) return name;
    }
    final topName = v['name'];
    if (topName is String && topName.isNotEmpty) return topName;
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: AppRadius.borderLG,
        border: Border.all(color: context.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              const Icon(Icons.visibility_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.visitedYourProfile(_totalCount),
                  style: context.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Horizontal avatar scroller
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _visitors.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final v = _visitors[i];
                final id = _userId(v);
                final avatar = _avatarUrl(v);
                final name = _userName(v);
                return GestureDetector(
                  onTap: () {
                    if (id != null && id.isNotEmpty) {
                      context.push('/profile/$id');
                    }
                  },
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.15),
                        backgroundImage:
                            (avatar != null && avatar.isNotEmpty)
                                ? NetworkImage(avatar)
                                : null,
                        child: (avatar == null || avatar.isEmpty)
                            ? Text(
                                name.isNotEmpty
                                    ? name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
