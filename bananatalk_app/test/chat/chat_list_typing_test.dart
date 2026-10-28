import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/pages/chat/list/list_socket_handlers.dart';

/// Each partner's "typing…" clears on its own timer. One shared timer meant
/// a second partner typing cancelled the first one's, leaving it stuck.
void main() {
  testWidgets('two partners typing both clear after 5 s', (tester) async {
    final typing = <String, bool>{};
    final timers = <String, Timer>{};
    final ctx = ListSocketContext(
      typingUsers: typing,
      userStatuses: {},
      getChatPartners: () => [],
      setChatPartners: (_) {},
      currentUserId: 'me',
      doSetState: (fn) => fn(),
      readProviderUnreadCount: (_) => 0,
      syncUnreadCounts: () {},
      processChatPartnersWithStatus: () {},
      typingTimers: timers,
    );

    handleUserTyping(ctx, {'userId': 'a'});
    await tester.pump(const Duration(seconds: 1));
    handleUserTyping(ctx, {'userId': 'b'});
    expect(typing, {'a': true, 'b': true});

    await tester.pump(const Duration(seconds: 4));
    expect(typing['a'], isFalse);
    expect(typing['b'], isTrue);

    await tester.pump(const Duration(seconds: 1));
    expect(typing['b'], isFalse);
    expect(timers, isEmpty);
  });

  testWidgets('typing again from the same partner restarts only theirs', (
    tester,
  ) async {
    final typing = <String, bool>{};
    final ctx = ListSocketContext(
      typingUsers: typing,
      userStatuses: {},
      getChatPartners: () => [],
      setChatPartners: (_) {},
      currentUserId: 'me',
      doSetState: (fn) => fn(),
      readProviderUnreadCount: (_) => 0,
      syncUnreadCounts: () {},
      processChatPartnersWithStatus: () {},
      typingTimers: {},
    );

    handleUserTyping(ctx, {'userId': 'a'});
    await tester.pump(const Duration(seconds: 4));
    handleUserTyping(ctx, {'userId': 'a'});
    await tester.pump(const Duration(seconds: 4));
    expect(typing['a'], isTrue);
    await tester.pump(const Duration(seconds: 1));
    expect(typing['a'], isFalse);
  });
}
