import 'package:bananatalk_app/l10n/app_localizations.dart';

/// Display name for a chat wallpaper preset id (`ocean`, `gradient_sunset`,
/// `premium_galaxy`…). The id is what gets stored in prefs and on the server
/// and never changes; only this label is translated. Free gradients that share
/// a solid colour's name (`gradient_ocean` → Ocean) reuse its key. An id this
/// build doesn't know is shown as-is.
String wallpaperDisplayName(AppLocalizations l10n, String id) {
  switch (id) {
    case 'default':
      return l10n.wallpaperPresetDefault;
    case 'dark':
      return l10n.wallpaperPresetDark;
    case 'midnight':
    case 'gradient_midnight':
      return l10n.wallpaperPresetMidnight;
    case 'charcoal':
      return l10n.wallpaperPresetCharcoal;
    case 'navy':
      return l10n.wallpaperPresetNavy;
    case 'ocean':
    case 'gradient_ocean':
      return l10n.wallpaperPresetOcean;
    case 'teal':
      return l10n.wallpaperPresetTeal;
    case 'forest':
    case 'gradient_forest':
      return l10n.wallpaperPresetForest;
    case 'sage':
      return l10n.wallpaperPresetSage;
    case 'wine':
      return l10n.wallpaperPresetWine;
    case 'plum':
      return l10n.wallpaperPresetPlum;
    case 'rose':
      return l10n.wallpaperPresetRose;
    case 'mocha':
      return l10n.wallpaperPresetMocha;
    case 'slate':
      return l10n.wallpaperPresetSlate;
    case 'ember':
      return l10n.wallpaperPresetEmber;
    case 'deep_sea':
      return l10n.wallpaperPresetDeepSea;
    case 'cream':
      return l10n.wallpaperPresetCream;
    case 'blush':
      return l10n.wallpaperPresetBlush;
    case 'peach':
      return l10n.wallpaperPresetPeach;
    case 'gradient_sunset':
      return l10n.wallpaperPresetSunset;
    case 'gradient_aurora':
      return l10n.wallpaperPresetAurora;
    case 'gradient_purple':
      return l10n.wallpaperPresetCosmic;
    case 'gradient_rose':
      return l10n.wallpaperPresetRoseGold;
    case 'gradient_candy':
      return l10n.wallpaperPresetCandy;
    case 'gradient_neon':
      return l10n.wallpaperPresetNeon;
    case 'gradient_fire':
      return l10n.wallpaperPresetFire;
    case 'gradient_winter':
      return l10n.wallpaperPresetWinter;
    case 'gradient_lavender':
      return l10n.wallpaperPresetLavender;
    case 'premium_aurora_borealis':
      return l10n.wallpaperPresetAuroraBorealis;
    case 'premium_golden_hour':
      return l10n.wallpaperPresetGoldenHour;
    case 'premium_galaxy':
      return l10n.wallpaperPresetGalaxy;
    case 'premium_emerald_luxe':
      return l10n.wallpaperPresetEmeraldLuxe;
    case 'premium_royal_velvet':
      return l10n.wallpaperPresetRoyalVelvet;
    case 'premium_diamond_shine':
      return l10n.wallpaperPresetDiamondShine;
  }
  return id;
}
