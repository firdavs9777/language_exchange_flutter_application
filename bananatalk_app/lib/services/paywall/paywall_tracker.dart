import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/providers/app_provider_container.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/services/paywall/paywall_api.dart';
import 'package:bananatalk_app/services/paywall/paywall_flow.dart';

/// Sends a batch; true when accepted. A false result or a throw drops it.
typedef PaywallSend = Future<bool> Function(List<Map<String, dynamic>> events);

/// In-memory, batched paywall funnel events. Telemetry: nothing is retried,
/// nothing is written to disk, and nothing here may throw into the caller.
class PaywallTracker {
  PaywallTracker({
    required this.send,
    required this.enabled,
    DateTime Function()? now,
    this.flushAfter = const Duration(seconds: 10),
    this.maxQueue = 20,
  }) : _now = now ?? DateTime.now;

  final PaywallSend send;

  /// Read at every [log], so a config refresh applies without a rebuild.
  final bool Function() enabled;
  final DateTime Function() _now;
  final Duration flushAfter;
  final int maxQueue;

  static const int _maxBatch = 50;
  static const int _maxDetail = 40;

  final List<Map<String, dynamic>> _queue = [];
  Timer? _timer;

  void log(PaywallFlow flow, String action, {String? detail}) {
    if (!enabled()) {
      _queue.clear();
      _timer?.cancel();
      _timer = null;
      return;
    }
    var d = detail ?? flow.detail;
    if (d != null && d.length > _maxDetail) d = d.substring(0, _maxDetail);
    _queue.add({
      'placement': flow.placement,
      'action': action,
      'flowId': flow.flowId,
      if (d != null) 'detail': d,
      if (flow.offerId != null) 'offerId': flow.offerId,
      'clientAt': _now().toUtc().toIso8601String(),
    });
    if (_queue.length >= maxQueue) {
      flush();
      return;
    }
    _timer ??= Timer(flushAfter, flush);
  }

  Future<void> flush() async {
    _timer?.cancel();
    _timer = null;
    if (_queue.isEmpty) return;
    final all = List<Map<String, dynamic>>.from(_queue);
    // Cleared BEFORE any await so a concurrent flush cannot send it twice.
    _queue.clear();
    for (var i = 0; i < all.length; i += _maxBatch) {
      final end = i + _maxBatch < all.length ? i + _maxBatch : all.length;
      final chunk = all.sublist(i, end);
      try {
        final ok = await send(chunk);
        if (!ok) debugPrint('[paywall] batch refused, ${chunk.length} dropped');
      } catch (e) {
        debugPrint('[paywall] flush failed, ${chunk.length} dropped: $e');
      }
    }
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

/// Flushes when the app leaves the foreground (same shape as the feed-open
/// tracker's observer).
class _PauseFlush with WidgetsBindingObserver {
  _PauseFlush(this._tracker);
  final PaywallTracker _tracker;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _tracker.flush();
  }
}

/// One app-wide instance (user-scoped: reset on sign-out).
final paywallTrackerProvider = Provider<PaywallTracker>((ref) {
  final api = PaywallApi();
  final tracker = PaywallTracker(
    send: api.send,
    enabled: () => ref.read(paywallEventsEnabledProvider),
  );
  final observer = _PauseFlush(tracker);
  WidgetsBinding.instance.addObserver(observer);
  ref.onDispose(() {
    WidgetsBinding.instance.removeObserver(observer);
    tracker.dispose();
  });
  return tracker;
});

/// Test seam: sees every [paywallLog] call, whatever the flag says.
@visibleForTesting
void Function(PaywallFlow flow, String action, String? detail)? paywallLogSpy;

/// Fire-and-forget entry point for any surface. Never throws.
void paywallLog(PaywallFlow flow, String action, {String? detail}) {
  try {
    paywallLogSpy?.call(flow, action, detail);
    appProviderContainer
        .read(paywallTrackerProvider)
        .log(flow, action, detail: detail);
  } catch (e) {
    debugPrint('[paywall] log skipped: $e');
  }
}
