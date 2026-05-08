import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/presence_provider.dart';
import 'package:bananatalk_app/widgets/report_dialog.dart';
import 'package:bananatalk_app/widgets/block_user_dialog.dart';
import 'package:bananatalk_app/widgets/vip_avatar_frame.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/pages/moments/image_viewer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bananatalk_app/pages/community/widgets/community_snackbar.dart';

/// Flexible-space background (map tiles or gradient) + avatar/name/location row
/// rendered inside [FlexibleSpaceBar].
class SingleCommunityHeader extends ConsumerWidget {
  final Community community;
  final int? age;
  final String locationText;
  final VoidCallback onCopyUsername;
  final List<String> imageUrls;
  final String? profileImageUrl;

  const SingleCommunityHeader({
    super.key,
    required this.community,
    required this.age,
    required this.locationText,
    required this.onCopyUsername,
    required this.imageUrls,
    required this.profileImageUrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presenceState = ref.watch(presenceProvider);
    return Stack(
      children: [
        // Map or gradient background
        Positioned.fill(
          child: _hasValidCoordinates()
              ? _buildMapTileGrid()
              : _buildGradientBackground(),
        ),
        // Gradient overlay at bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 150,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
          ),
        ),
        // Profile info row at bottom
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Row(
            children: [
              // Avatar
              InkWell(
                onTap: () {
                  if (imageUrls.isNotEmpty) {
                    Navigator.push(
                      context,
                      AppPageRoute(
                        builder: (context) =>
                            ImageGallery(imageUrls: imageUrls),
                      ),
                    );
                  }
                },
                child: Hero(
                  tag: 'profile_${community.id}',
                  child: VipAvatarFrame(
                    isVip: community.isVip,
                    size: 80,
                    frameWidth: 3,
                    showGlow: true,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: CircleAvatar(
                        radius: 37,
                        backgroundColor: AppColors.accent,
                        backgroundImage: profileImageUrl != null
                            ? NetworkImage(profileImageUrl!)
                            : null,
                        child: profileImageUrl == null
                            ? const Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Name and info column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            community.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  offset: Offset(0, 1),
                                  blurRadius: 3,
                                  color: Colors.black45,
                                ),
                              ],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (community.isVip) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.workspace_premium,
                                  size: 12,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 2),
                                Text(
                                  'VIP',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (community.displayUsername != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            community.displayUsername!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: onCopyUsername,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                Icons.copy_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (age != null) ...[
                          Text(
                            '$age yrs',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                            ),
                          ),
                          if (locationText.isNotEmpty) ...[
                            Text(
                              ' • ',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ],
                        if (locationText.isNotEmpty) ...[
                          const Icon(
                            Icons.location_on,
                            size: 12,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              locationText,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    _buildPresencePill(context, presenceState),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPresencePill(BuildContext context, PresenceState presenceState) {
    final l10n = AppLocalizations.of(context)!;
    if (presenceState.isOnline(community.id)) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.20),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.green.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              l10n.onlineNow,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
    final lastSeen = presenceState.lastSeen[community.id];
    if (lastSeen != null) {
      return Text(
        l10n.activeAgo(timeago.format(lastSeen)),
        style: TextStyle(
          fontSize: 11,
          color: Colors.white.withValues(alpha: 0.7),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  bool _hasValidCoordinates() {
    final location = community.location;
    final coords = location.coordinates;
    if (coords.length < 2) return false;
    final lon = coords[0];
    final lat = coords[1];
    final hasValidCoords =
        lat != 0 &&
        lon != 0 &&
        lat >= -90 &&
        lat <= 90 &&
        lon >= -180 &&
        lon <= 180;
    final hasLocationInfo =
        location.city.isNotEmpty ||
        location.country.isNotEmpty ||
        location.formattedAddress.isNotEmpty;
    return hasValidCoords && hasLocationInfo;
  }

  double _roundCoordinate(double coord, {int decimals = 2}) {
    final factor = math.pow(10, decimals);
    return (coord * factor).round() / factor;
  }

  Widget _buildMapTileGrid() {
    final coords = community.location.coordinates;
    final lon = _roundCoordinate(coords[0]);
    final lat = _roundCoordinate(coords[1]);
    final zoom = 10;
    final n = 1 << zoom;
    final centerX = ((lon + 180) / 360 * n).floor();
    final latRad = lat * math.pi / 180;
    final centerY =
        ((1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) /
                2 *
                n)
            .floor();

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: AppColors.gray300),
          Positioned.fill(
            child: Row(
              children: [
                for (int dx = -1; dx <= 1; dx++)
                  Expanded(
                    child: Column(
                      children: [
                        for (int dy = 0; dy <= 1; dy++)
                          Expanded(
                            child: Image.network(
                              'https://tile.openstreetmap.org/$zoom/${centerX + dx}/${centerY + dy}.png',
                              fit: BoxFit.cover,
                              headers: const {'User-Agent': 'Bananatalk App'},
                              errorBuilder: (context, error, stackTrace) {
                                return Container(color: AppColors.gray300);
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Center(
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF00BFA5).withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF00BFA5).withValues(alpha: 0.6),
                  width: 2,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.location_city_rounded,
                  color: Color(0xFF00BFA5),
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00BFA5), Color(0xFF00ACC1), Color(0xFF26C6DA)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.location_off_rounded,
          size: 48,
          color: Colors.white.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

/// AppBar "more" menu (report / block / unblock).
/// Extracted so it can be built inline in the SliverAppBar actions list.
class SingleCommunityMoreMenu extends ConsumerWidget {
  final Community community;
  final String currentUserId;
  final bool isScrolled;
  final bool isBlocked;
  final String? profileImageUrl;
  final VoidCallback onBlocked;
  final Future<void> Function() onUnblock;

  const SingleCommunityMoreMenu({
    super.key,
    required this.community,
    required this.currentUserId,
    required this.isScrolled,
    required this.isBlocked,
    required this.profileImageUrl,
    required this.onBlocked,
    required this.onUnblock,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: isScrolled
            ? Theme.of(context).colorScheme.onSurface
            : Colors.white,
      ),
      onSelected: (value) async {
        if (value == 'report') {
          showDialog(
            context: context,
            builder: (context) => ReportDialog(
              type: 'user',
              reportedId: community.id,
              reportedUserId: community.id,
            ),
          );
        } else if (value == 'block') {
          if (currentUserId.isNotEmpty && currentUserId != community.id) {
            await BlockUserDialog.show(
              context: context,
              currentUserId: currentUserId,
              targetUserId: community.id,
              targetUserName: community.name,
              targetUserAvatar: profileImageUrl,
              ref: ref,
              onBlocked: () {
                onBlocked();
                if (context.mounted) Navigator.of(context).pop();
              },
            );
          }
        } else if (value == 'unblock') {
          await onUnblock();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'report',
          child: Row(
            children: [
              const Icon(Icons.flag_outlined, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text(l10n.reportUser),
            ],
          ),
        ),
        if (isBlocked)
          PopupMenuItem(
            value: 'unblock',
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.unblockUser,
                  style: const TextStyle(color: Colors.green),
                ),
              ],
            ),
          )
        else
          PopupMenuItem(
            value: 'block',
            child: Row(
              children: [
                const Icon(Icons.block, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Text(l10n.blockUser, style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
      ],
    );
  }
}

/// Opens the community's location in an external maps app (city-level, privacy-safe).
Future<void> openLocationInMaps(
  BuildContext context,
  Community community, {
  required String couldNotOpenMapsLabel,
}) async {
  final coords = community.location.coordinates;
  if (coords.length < 2) return;
  const decimals = 2;
  final factor = math.pow(10, decimals);
  final lon = (coords[0] * factor).round() / factor;
  final lat = (coords[1] * factor).round() / factor;
  final location = community.location;

  final Uri mapsUrl = Uri.parse(
    'https://www.openstreetmap.org/?mlat=$lat&mlon=$lon&zoom=10',
  );

  try {
    await launchUrl(mapsUrl, mode: LaunchMode.externalApplication);
  } catch (e) {
    if (context.mounted) {
      showCommunitySnackBar(
        context,
        message:
            '$couldNotOpenMapsLabel: ${location.city}, ${location.country}',
        type: CommunitySnackBarType.info,
      );
    }
  }
}
