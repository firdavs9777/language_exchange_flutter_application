import 'package:flutter/widgets.dart';

import 'package:bananatalk_app/models/announcement.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/services/announcement_seen_store.dart';
import 'package:bananatalk_app/services/launch_modal_coordinator.dart';
import 'package:bananatalk_app/services/promo_service.dart';
import 'package:bananatalk_app/widgets/promo/ads_notice_modal.dart';
import 'package:bananatalk_app/widgets/promo/announcement_modal.dart';
import 'package:bananatalk_app/widgets/promos/feature_spotlight_sheet.dart';

/// The guide-period answer for this launch. `isGuidePeriodProvider` throws
/// when the user cannot be loaded; unknown takes the restrictive answer
/// (true), so a new user never gets the full pop-up set by accident.
Future<bool> launchGuidePeriod(Future<bool> Function() read) async {
  try {
    return await read();
  } catch (e) {
    debugPrint('launch: guide period unknown ($e); restrictive');
    return true;
  }
}

class AnnouncementCandidate implements LaunchCandidate {
  AnnouncementCandidate({required this.config});

  final AppConfig? config;
  Announcement? _picked;

  @override
  String get id => 'announcement';

  @override
  bool get allowedForNewUsers => false;

  @override
  Future<bool> isDue() async {
    final c = config;
    if (c == null) return false;
    final seen = await AnnouncementSeenStore.read();
    if (seen == null) return false;
    _picked = pickAnnouncement(
      live: c.announcements,
      legacy: Announcement.fromLegacy(c.announcement),
      seen: seen,
    );
    return _picked != null;
  }

  /// Marked seen once the sheet is on screen, never when the push fails.
  @override
  Future<void> show(BuildContext context) async {
    final a = _picked;
    if (a == null || !context.mounted) return;
    final dismissed = AnnouncementModal.show(context, a);
    await AnnouncementSeenStore.add(a.id);
    await dismissed;
  }
}

class AdsNoticeCandidate implements LaunchCandidate {
  @override
  String get id => 'ads_notice';

  /// Not in the guide period: the notice tells existing users that ads
  /// arrived, which means nothing to a brand-new user, and showing it at a
  /// new user's first launch spent the one-per-launch [PopupBudget] that
  /// notification priming (spec §4.2) needs in that same first session.
  /// It shows once, as before, on the first launch after the guide period.
  @override
  bool get allowedForNewUsers => false;

  @override
  Future<bool> isDue() => AdsNoticeModal.isDue();

  @override
  Future<void> show(BuildContext context) => AdsNoticeModal.show(context);
}

class FeatureSpotlightCandidate implements LaunchCandidate {
  FeatureSpotlightCandidate({required this.pick, required this.onTry});

  final Future<PromoType?> Function() pick;
  final void Function(PromoType) onTry;
  PromoType? _picked;

  @override
  String get id => 'feature_spotlight';

  @override
  bool get allowedForNewUsers => false;

  @override
  Future<bool> isDue() async {
    _picked = await pick();
    return _picked != null;
  }

  @override
  Future<void> show(BuildContext context) async {
    final p = _picked;
    if (p == null) return;
    await showFeatureSpotlight(context, p, onTry: () => onTry(p));
    await markShown(p);
  }
}

/// Spec §4.1 order after the update dialog (which ran in splash):
/// announcement → ads notice → feature spotlight. Inside the guide period
/// none of them runs (only the update dialog, in splash).
List<LaunchCandidate> standardLaunchCandidates({
  required AppConfig? config,
  required Future<PromoType?> Function() pickSpotlight,
  required void Function(PromoType) onSpotlightTry,
}) =>
    [
      AnnouncementCandidate(config: config),
      AdsNoticeCandidate(),
      FeatureSpotlightCandidate(pick: pickSpotlight, onTry: onSpotlightTry),
    ];
