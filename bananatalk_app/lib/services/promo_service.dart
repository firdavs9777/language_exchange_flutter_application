import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/providers/ad_providers.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';

/// The three rotating "feature spotlight" promos surfaced on the home shell.
enum PromoType { coins, rooms, voice }

/// Fixed rotation order the spotlight cycles through. Kept stable so the
/// stored `promo_rotation_index` always means the same thing across app
/// versions/releases.
const List<PromoType> _rotationOrder = [
  PromoType.coins,
  PromoType.rooms,
  PromoType.voice,
];

const String _lastShownDateKey = 'promo_last_shown_date';
const String _rotationIndexKey = 'promo_rotation_index';
const String _dismissCountKey = 'promo_dismiss_count';

/// Stop showing any promo once the user has dismissed (without engaging)
/// this many times — they've made it clear they're not interested.
const int _maxDismissCount = 5;

/// How long a "Don't show this again" promo stays hidden before it's
/// eligible to rotate back in.
const Duration _hiddenDuration = Duration(days: 7);

String _hiddenUntilKey(PromoType type) => 'promo_hidden_until_${type.name}';

String _dateOnly(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Picks the promo to show right now, or `null` if none should show.
///
/// Rules (checked in order):
/// 1. Global stop: if the user has dismissed `_maxDismissCount` or more
///    promos without engaging, never show again.
/// 2. Once-per-day: if a promo was already shown today, show nothing.
/// 3. Eligibility: `coins` only shows when `AppConfig.coinsEnabled` is true
///    AND the user is not VIP/ad-free (`showAdsProvider` — ad-free users
///    likely already bought/are VIP, so the coins pitch isn't relevant).
///    `rooms` and `voice` are always eligible for now.
/// 4. Per-promo snooze: a promo the user asked not to see again
///    (`promo_hidden_until_<type>`) is skipped until that date passes.
/// 5. Rotation: starting from the stored `promo_rotation_index`, walk the
///    fixed rotation order and return the first eligible, non-hidden promo;
///    advance the stored index past it so tomorrow starts from the next one.
Future<PromoType?> pickPromo(WidgetRef ref) async {
  final prefs = await SharedPreferences.getInstance();

  final dismissCount = prefs.getInt(_dismissCountKey) ?? 0;
  if (dismissCount >= _maxDismissCount) return null;

  final today = _dateOnly(DateTime.now());
  if (prefs.getString(_lastShownDateKey) == today) return null;

  final coinsEnabled = ref.read(appConfigProvider).maybeWhen(
        data: (config) => config?.coinsEnabled ?? false,
        orElse: () => false,
      );
  // showAdsProvider is true for non-VIP users; ad-free (VIP) users have
  // likely already paid, so the coins upsell isn't relevant to them.
  final showAds = ref.read(showAdsProvider);
  final eligible = <PromoType>{
    if (coinsEnabled && showAds) PromoType.coins,
    PromoType.rooms,
    PromoType.voice,
  };
  if (eligible.isEmpty) return null;

  final now = DateTime.now();
  final startIndex =
      (prefs.getInt(_rotationIndexKey) ?? 0) % _rotationOrder.length;

  for (var offset = 0; offset < _rotationOrder.length; offset++) {
    final idx = (startIndex + offset) % _rotationOrder.length;
    final type = _rotationOrder[idx];
    if (!eligible.contains(type)) continue;

    final hiddenUntilIso = prefs.getString(_hiddenUntilKey(type));
    if (hiddenUntilIso != null) {
      final hiddenUntil = DateTime.tryParse(hiddenUntilIso);
      if (hiddenUntil != null && now.isBefore(hiddenUntil)) continue;
    }

    await prefs.setInt(_rotationIndexKey, (idx + 1) % _rotationOrder.length);
    return type;
  }

  return null;
}

/// Records that [type] was shown today — enforces the once-per-day cap.
Future<void> markShown(PromoType type) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_lastShownDateKey, _dateOnly(DateTime.now()));
}

/// Records that the user asked not to see [type] again. Hidden for
/// [_hiddenDuration] rather than forever, so it can resurface later if the
/// feature becomes newly relevant to them.
Future<void> markDontShowAgain(PromoType type) async {
  final prefs = await SharedPreferences.getInstance();
  final hiddenUntil = DateTime.now().add(_hiddenDuration);
  await prefs.setString(_hiddenUntilKey(type), hiddenUntil.toIso8601String());
}

/// Records a dismissal (the user closed the spotlight without engaging).
/// Once this reaches [_maxDismissCount], [pickPromo] stops surfacing any
/// promo — a clear enough "not interested" signal that we shouldn't keep
/// interrupting them.
Future<void> incrementDismiss() async {
  final prefs = await SharedPreferences.getInstance();
  final current = prefs.getInt(_dismissCountKey) ?? 0;
  await prefs.setInt(_dismissCountKey, current + 1);
}
