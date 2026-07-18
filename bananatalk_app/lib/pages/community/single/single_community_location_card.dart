import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/utils/privacy_utils.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Compact location/map card for the About tab.
///
/// Privacy note: this is a *city-level* preview (zoom 10, non-interactive)
/// — never street level, never labeled with an exact address. If the
/// viewer's location-sharing privacy settings hide the city/country, no
/// coordinates or map are shown either (mirrors the header's location chip,
/// which already goes blank via [PrivacyUtils.getLocationText]).
class SingleCommunityLocationCard extends StatelessWidget {
  final Community community;

  const SingleCommunityLocationCard({super.key, required this.community});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locationText = PrivacyUtils.getLocationText(community);

    final coordinates = community.location.coordinates;
    final hasCoords = coordinates.length >= 2 &&
        (coordinates[0] != 0.0 || coordinates[1] != 0.0);

    // Coordinates are stored in GeoJSON order: [longitude, latitude].
    final canShowMap =
        hasCoords && PrivacyUtils.shouldShowLocation(community);

    if (!canShowMap) {
      if (locationText.isEmpty) {
        return const SizedBox.shrink();
      }
      return _buildTextOnlyRow(context, isDark, locationText);
    }

    final center = LatLng(coordinates[1], coordinates[0]);
    return _buildMapCard(context, isDark, center, locationText);
  }

  Widget _buildTextOnlyRow(
    BuildContext context,
    bool isDark,
    String locationText,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : context.dividerColor,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on_rounded,
            color: context.primaryColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              locationText,
              style: context.bodyMedium.copyWith(
                color: context.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapCard(
    BuildContext context,
    bool isDark,
    LatLng center,
    String locationText,
  ) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : context.dividerColor,
          width: 0.5,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 160,
            width: double.infinity,
            child: IgnorePointer(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 10,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: isDark
                        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                        : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.bananatalk.app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: center,
                        width: 36,
                        height: 36,
                        child: Icon(
                          Icons.location_on_rounded,
                          color: context.primaryColor,
                          size: 36,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (locationText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    color: context.primaryColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      locationText,
                      style: context.bodyMedium.copyWith(
                        color: context.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
