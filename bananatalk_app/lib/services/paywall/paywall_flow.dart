import 'dart:math';

/// Server-accepted `placement` values for paywall events.
class PaywallPlacement {
  PaywallPlacement._();
  static const visitorList = 'visitor_list';
  static const conversationCap = 'conversation_cap';
  static const translationCap = 'translation_cap';
  static const adRemoval = 'ad_removal';
  static const discoveryPriority = 'discovery_priority';
  static const waveCap = 'wave_cap';
  static const extraMatches = 'extra_matches';
  static const momentCap = 'moment_cap';
  static const commentCap = 'comment_cap';
  static const storyCap = 'story_cap';
  static const dmCap = 'dm_cap';
  static const profileViewCap = 'profile_view_cap';
  static const tutorQuota = 'tutor_quota';
  static const studyLock = 'study_lock';
  static const boost = 'boost';
  static const nearbyRadius = 'nearby_radius';
  static const countryFilter = 'country_filter';
  static const vipEntry = 'vip_entry';
  static const coinEntry = 'coin_entry';
  static const notEnoughCoins = 'not_enough_coins';
  static const matchesEmpty = 'matches_empty';
  static const other = 'other';
}

/// Server-accepted `action` values for paywall events.
class PaywallAction {
  PaywallAction._();
  static const shown = 'shown';
  static const dismissed = 'dismissed';
  static const converted = 'converted';
  static const ctaVip = 'cta_vip';
  static const ctaCoins = 'cta_coins';
  static const ctaAd = 'cta_ad';
  static const plansViewed = 'plans_viewed';
  static const shopViewed = 'shop_viewed';
  static const purchaseStarted = 'purchase_started';
  static const purchaseSucceeded = 'purchase_succeeded';
  static const purchaseFailed = 'purchase_failed';
  static const unlockSucceeded = 'unlock_succeeded';
}

/// One upsell flow: every event of one showing of one surface shares a
/// [flowId]. An engine offer also carries [offerId] on each event.
class PaywallFlow {
  const PaywallFlow({
    required this.placement,
    required this.flowId,
    this.offerId,
    this.detail,
  });

  /// Starts a flow with a fresh id.
  factory PaywallFlow.start(
    String placement, {
    String? detail,
    String? offerId,
  }) =>
      PaywallFlow(
        placement: placement,
        flowId: _newFlowId(),
        offerId: offerId,
        detail: detail,
      );

  final String placement;
  final String flowId;
  final String? offerId;
  final String? detail;

  static const _alphabet =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';

  /// 22 url-safe characters (matches the server's `^[A-Za-z0-9_-]{1,40}$`).
  static String _newFlowId() {
    final r = Random.secure();
    return String.fromCharCodes(
      List.generate(22, (_) => _alphabet.codeUnitAt(r.nextInt(64))),
    );
  }
}
