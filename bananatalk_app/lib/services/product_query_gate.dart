/// Whether `initializeStore` must query the store again. A connected store
/// with no products is not an answer: the query failed or came back empty,
/// and the next caller asks again instead of being handed the empty list.
bool storeNeedsProductQuery({
  required bool available,
  required bool subscribed,
  required bool hasProducts,
}) =>
    !(available && subscribed && hasProducts);

/// At most one run of an async job at a time: a caller that arrives while it
/// runs gets that run's future instead of starting (or skipping) another.
class SingleFlight<T> {
  Future<T>? _running;

  /// Forgets a run that is still going (sign-out), so it cannot block the
  /// next session's call; the old run's own result is ignored.
  void reset() => _running = null;

  Future<T> run(Future<T> Function() job) {
    final running = _running;
    if (running != null) return running;
    final started = job();
    _running = started;
    // Cleared on success and failure, so a failed run is retried by the next
    // caller. The identity check keeps a late finish from clearing a newer run.
    void clear() {
      if (identical(_running, started)) _running = null;
    }

    started.then<void>((_) => clear(), onError: (Object _) => clear());
    return started;
  }
}
