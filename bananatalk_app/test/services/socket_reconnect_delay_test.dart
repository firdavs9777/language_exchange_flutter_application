import 'package:bananatalk_app/services/chat_socket_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// The chat socket never gives up while the app is open (2026-10-18): fast
/// backoff first, then a steady retry every minute.
void main() {
  test('fast backoff, then every 60s forever', () {
    expect(reconnectDelayFor(0, 10), const Duration(seconds: 1));
    expect(reconnectDelayFor(3, 10), const Duration(seconds: 8));
    expect(reconnectDelayFor(9, 10), const Duration(seconds: 64));
    expect(reconnectDelayFor(10, 10), const Duration(seconds: 60));
    expect(reconnectDelayFor(500, 10), const Duration(seconds: 60));
  });
}
