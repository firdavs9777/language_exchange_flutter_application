import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/models/coin_transaction.dart';
import 'package:bananatalk_app/services/coin_api_client.dart';

/// Coins v1 (Workstream F) — Riverpod wiring for the coin balance + live
/// unlock catalog. See `docs/superpowers/specs/2026-07-13-coins-v1-design.md`.

final coinApiClientProvider = Provider<CoinApiClient>((ref) => CoinApiClient());

/// Current coin balance. `FutureProvider` rather than a `StateNotifier`
/// because the value is always server-derived — after a purchase or
/// unlock, callers invalidate this provider (see [refreshCoinBalance])
/// instead of locally mutating a cached number, so the UI never drifts
/// from the ledger.
final coinBalanceProvider = FutureProvider<int>((ref) async {
  final client = ref.watch(coinApiClientProvider);
  return client.getBalance();
});

/// Live per-featureKey unlock cost/grant (`GET /coins/unlock-catalog`).
/// Fetched once and cached for the provider's lifetime — costs rarely
/// change mid-session, and every "Unlock N for 💎X" CTA reads from here
/// rather than hardcoding values.
final coinUnlockCatalogProvider =
    FutureProvider<Map<String, CoinUnlockEntry>>((ref) async {
  final client = ref.watch(coinApiClientProvider);
  return client.getUnlockCatalog();
});

/// Whether today's (UTC) daily coin reward has already been claimed
/// (Coins v2 — Task 17). Backs the "Earn free coins" section's initial
/// claim-button state so it renders disabled up front rather than only
/// after a failed claim reveals it was already claimed.
final dailyRewardStatusProvider = FutureProvider<bool>((ref) async {
  final client = ref.watch(coinApiClientProvider);
  return client.getDailyRewardStatus();
});

/// Refreshes the coin balance after a purchase or unlock succeeds, so the
/// balance pill and coin shop reflect the new value immediately rather
/// than waiting for their next natural rebuild.
void refreshCoinBalance(WidgetRef ref) {
  ref.invalidate(coinBalanceProvider);
}

/// Refreshes the daily-reward claimed status after a successful claim, so
/// reopening/remounting the coin shop re-fetches `claimedToday: true`
/// instead of serving the stale pre-claim cached value forever (this
/// provider is not `autoDispose`, so without an explicit invalidate here
/// it stays cached for the whole session).
void refreshDailyRewardStatus(WidgetRef ref) {
  ref.invalidate(dailyRewardStatusProvider);
}
