/// After a failed page load, scroll-driven loads wait [pause]: scroll events
/// fire continuously at the end of a list, so without it a dropped
/// connection became a stream of requests. A tap on Retry passes `force`.
class RetryPause {
  RetryPause({
    this.pause = const Duration(seconds: 5),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final Duration pause;
  final DateTime Function() _clock;
  DateTime? _failedAt;

  bool get hasFailed => _failedAt != null;

  bool blocks({bool force = false}) {
    final failedAt = _failedAt;
    if (force || failedAt == null) return false;
    return _clock().difference(failedAt) < pause;
  }

  void failed() => _failedAt = _clock();
  void succeeded() => _failedAt = null;
}
