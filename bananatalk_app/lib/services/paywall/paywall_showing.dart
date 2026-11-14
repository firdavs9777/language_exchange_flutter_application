import 'package:bananatalk_app/services/paywall/paywall_flow.dart';
import 'package:bananatalk_app/services/paywall/paywall_tracker.dart';

/// One showing of a limit dialog or upgrade sheet: logs `shown` when it is
/// created, remembers whether any button was tapped, and logs `dismissed` on
/// [finish] only when none was. One showing is one [flow].
class PaywallShowing {
  PaywallShowing.begin(String placement, {String? detail, String? offerId})
    : flow = PaywallFlow.start(placement, detail: detail, offerId: offerId) {
    paywallLog(flow, PaywallAction.shown);
  }

  final PaywallFlow flow;
  bool _acted = false;
  bool _finished = false;

  /// A button other than "close" was tapped (it logs its own `cta_*`).
  void markActed() => _acted = true;

  /// Logs a CTA action on this showing and marks it acted.
  void act(String action, {String? detail}) {
    _acted = true;
    paywallLog(flow, action, detail: detail);
  }

  /// The surface closed. Logs `dismissed` unless a CTA was tapped. Idempotent.
  void finish() {
    if (_finished) return;
    _finished = true;
    if (!_acted) paywallLog(flow, PaywallAction.dismissed);
  }
}
