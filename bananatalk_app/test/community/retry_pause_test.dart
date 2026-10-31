import 'package:bananatalk_app/pages/community/partners/retry_pause.dart';
import 'package:flutter_test/flutter_test.dart';

/// Nearby asked for the next page on every scroll event after a failure (an
/// offline retry storm; audit 2026-10-30). After a failure, scroll-driven
/// loads wait 5 s; the Retry button skips the wait.
void main() {
  test('blocks scroll loads for 5 s after a failure; Retry is never blocked', () {
    var now = DateTime(2026, 10, 31, 12);
    final pause = RetryPause(clock: () => now);
    expect(pause.blocks(), isFalse);
    pause.failed();
    expect(pause.hasFailed, isTrue);
    expect(pause.blocks(), isTrue);
    expect(pause.blocks(force: true), isFalse);
    now = now.add(const Duration(seconds: 4));
    expect(pause.blocks(), isTrue);
    now = now.add(const Duration(seconds: 1));
    expect(pause.blocks(), isFalse);
  });

  test('a success clears the failure', () {
    final pause = RetryPause()..failed();
    pause.succeeded();
    expect(pause.hasFailed, isFalse);
    expect(pause.blocks(), isFalse);
  });
}
