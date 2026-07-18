import 'package:flutter/material.dart';

/// Coin-unlockable "Premium ✨" chat wallpaper gradients (Task 12).
///
/// A single finite, hardcoded set of premium presets — no image assets, just
/// `LinearGradient`s. Both the wallpaper picker (`WallpaperPickerScreen`,
/// the write/selection side) and the conversation background resolver
/// (`_getWallpaperDecoration` in `chat_conversation_screen.dart`, the
/// read/render side) resolve preset names from this ONE list so the
/// gradient definitions never drift between the two.
///
/// Every premium preset name is prefixed with [premiumWallpaperPrefix] so
/// both sides can cheaply tell "this preset requires the `wallpaper` coin
/// unlock" apart from a free solid/gradient preset, without a lookup.
///
/// The `wallpaper` catalog key (see `GET /coins/unlock-catalog`) gates ALL
/// premium presets as a single pack — `unlocks.wallpaper >= 1` (see
/// `CoinApiClient.getUnlockedFeatures`) unlocks every preset below at once,
/// not one preset at a time.
const String premiumWallpaperFeatureKey = 'wallpaper';
const String premiumWallpaperPrefix = 'premium_';

/// Whether [name] is one of the premium (coin-gated) preset names, purely
/// by its `premium_` prefix — does not check entitlement.
bool isPremiumWallpaperName(String name) => name.startsWith(premiumWallpaperPrefix);

class PremiumWallpaper {
  final String name;
  final String label;
  final List<Color> colors;

  const PremiumWallpaper({
    required this.name,
    required this.label,
    required this.colors,
  });

  LinearGradient get gradient => LinearGradient(
        colors: colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}

/// The full premium pack — 6 gradients, shared as-is for light/dark (unlike
/// the free solid presets, a gradient reads fine in either theme so there's
/// no separate dark-mode variant list).
const List<PremiumWallpaper> premiumWallpapers = [
  PremiumWallpaper(
    name: 'premium_aurora_borealis',
    label: 'Aurora Borealis',
    colors: [Color(0xFF00C9FF), Color(0xFF92FE9D), Color(0xFFFC466B)],
  ),
  PremiumWallpaper(
    name: 'premium_golden_hour',
    label: 'Golden Hour',
    colors: [Color(0xFFFFD700), Color(0xFFFF8C00), Color(0xFFFF4500)],
  ),
  PremiumWallpaper(
    name: 'premium_galaxy',
    label: 'Galaxy',
    colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
  ),
  PremiumWallpaper(
    name: 'premium_emerald_luxe',
    label: 'Emerald Luxe',
    colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
  ),
  PremiumWallpaper(
    name: 'premium_royal_velvet',
    label: 'Royal Velvet',
    colors: [Color(0xFF360033), Color(0xFF0B8793)],
  ),
  PremiumWallpaper(
    name: 'premium_diamond_shine',
    label: 'Diamond Shine',
    colors: [Color(0xFFB993D6), Color(0xFF8CA6DB)],
  ),
];

/// Looks up a premium gradient by preset name; `null` if [name] isn't one
/// of [premiumWallpapers] (including if it isn't premium at all). Callers
/// on the render side check this AFTER the free `gradient_*` lookup so
/// existing free-preset behavior is unaffected.
LinearGradient? premiumWallpaperGradient(String name) {
  for (final wallpaper in premiumWallpapers) {
    if (wallpaper.name == name) return wallpaper.gradient;
  }
  return null;
}
