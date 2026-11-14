import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/services/offers/offer.dart';
import 'package:bananatalk_app/services/offers/offers_api.dart';
import 'package:bananatalk_app/services/paywall/paywall_flow.dart';
import 'package:bananatalk_app/services/paywall/paywall_tracker.dart';

/// The `GET offers` client (stateless over the ApiClient singleton).
final offersApiProvider = Provider<OffersApi>((ref) => OffersApi());

/// The clock the offer gates read; a test seam.
final offersClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// The signed-in user's current server offer, or null. Fetched only while
/// `offerEngineEnabled` is on; dropped when its `validUntil` passes.
class OffersNotifier extends StateNotifier<Offer?> {
  OffersNotifier({
    required OffersApi api,
    required bool Function() enabled,
    required DateTime Function() now,
    this.minInterval = const Duration(minutes: 2),
  }) : _api = api,
       _enabled = enabled,
       _now = now,
       super(null);

  final OffersApi _api;
  final bool Function() _enabled;
  final DateTime Function() _now;
  final Duration minInterval;

  DateTime? _lastFetch;
  Timer? _expiry;

  /// At most one request per [minInterval] unless [force]. Never throws. A
  /// failed, non-200 or malformed answer clears the offer.
  Future<void> refresh({bool force = false}) async {
    try {
      if (!_enabled()) return;
      final at = _now();
      final last = _lastFetch;
      if (!force && last != null && at.difference(last) < minInterval) return;
      _lastFetch = at;
      final offer = await _api.fetch();
      if (mounted) _set(offer);
    } catch (e) {
      debugPrint('[offers] refresh failed: $e');
      if (mounted) _set(null);
    }
  }

  void _set(Offer? offer) {
    _expiry?.cancel();
    _expiry = null;
    final now = _now();
    final valid = offer != null && offer.isValid(now) ? offer : null;
    state = valid;
    if (valid != null) {
      _expiry = Timer(valid.validUntil.difference(now), () {
        _expiry = null;
        if (mounted) state = null;
      });
    }
  }

  @override
  void dispose() {
    _expiry?.cancel();
    _expiry = null;
    super.dispose();
  }
}

/// User-scoped: sign-out invalidates it (timer cancelled in dispose), so the
/// next user starts with no offer.
final offersProvider = StateNotifierProvider<OffersNotifier, Offer?>((ref) {
  final notifier = OffersNotifier(
    api: ref.watch(offersApiProvider),
    enabled: () => ref.read(offerEngineEnabledProvider),
    now: ref.watch(offersClockProvider),
  );
  // App-config may land after the first refresh was attempted (and skipped
  // as "engine off"); fetch once the switch is known to be on.
  ref.listen<bool>(offerEngineEnabledProvider, (prev, next) {
    if (next && prev != true) notifier.refresh();
  });
  return notifier;
});

/// What one passive upsell surface does with the server's offer.
sealed class OfferGate {
  const OfferGate();
}

/// Engine off: the surface behaves exactly as before the offer engine.
class OfferGateLegacy extends OfferGate {
  const OfferGateLegacy();
}

/// Engine on, no valid offer names this surface: not drawn.
class OfferGateHidden extends OfferGate {
  const OfferGateHidden();
}

/// Engine on and the offer names this surface. Every event of the surface
/// goes on [flow].
class OfferGateShow extends OfferGate {
  const OfferGateShow(this.offer, this.flow);
  final Offer offer;
  final PaywallFlow flow;
}

/// Keyed by surface id ([OfferSurface]).
final offerGateProvider = Provider.family<OfferGate, String>((ref, surface) {
  if (!ref.watch(offerEngineEnabledProvider)) return const OfferGateLegacy();
  final offer = ref.watch(offersProvider);
  final now = ref.watch(offersClockProvider)();
  if (offer == null || offer.surface != surface || !offer.isValid(now)) {
    return const OfferGateHidden();
  }
  return OfferGateShow(offer, offerFlowFor(offer));
});

/// One flow per offer id for the life of the process.
final Map<String, PaywallFlow> _offerFlows = {};

/// Offer ids whose `shown` was already logged in this process.
final Set<String> _shownOfferIds = {};

PaywallFlow offerFlowFor(Offer offer) => _offerFlows.putIfAbsent(
  offer.id,
  () => PaywallFlow.start(
    offer.placement,
    offerId: offer.id,
    detail: offer.surface,
  ),
);

/// Logs `shown` on an offer's [flow] once per offer id per process.
void reportOfferShown(PaywallFlow flow) {
  final id = flow.offerId;
  if (id == null || !_shownOfferIds.add(id)) return;
  paywallLog(flow, PaywallAction.shown, detail: flow.detail);
}

@visibleForTesting
void resetOfferProcessStateForTest() {
  _offerFlows.clear();
  _shownOfferIds.clear();
}

/// Wraps a surface drawn for an engine offer: after the frame it is first
/// laid out (and whenever the offer changes) logs `shown` via
/// [reportOfferShown]. Never logs from build.
class OfferShownReporter extends StatefulWidget {
  const OfferShownReporter({
    super.key,
    required this.flow,
    required this.child,
  });

  final PaywallFlow flow;
  final Widget child;

  @override
  State<OfferShownReporter> createState() => _OfferShownReporterState();
}

class _OfferShownReporterState extends State<OfferShownReporter> {
  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(OfferShownReporter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.flow.offerId != widget.flow.offerId) _schedule();
  }

  void _schedule() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) reportOfferShown(widget.flow);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Fire-and-forget refresh after a purchase or unlock succeeded: what the
/// user owns changed, so the offer may have too.
void refreshOffersAfterPurchase(WidgetRef ref) {
  try {
    unawaited(ref.read(offersProvider.notifier).refresh(force: true));
  } catch (e) {
    debugPrint('[offers] refresh skipped: $e');
  }
}
