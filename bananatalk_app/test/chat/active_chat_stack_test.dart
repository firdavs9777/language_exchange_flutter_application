import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/providers/unread_count_provider.dart';

/// Chat B opened from the in-app banner while in chat A, then closed: A must
/// be the active chat again (its messages auto-read, no banner, no unread).
void main() {
  late ProviderContainer container;
  late ChatPartnersNotifier notifier;

  setUp(() {
    container = ProviderContainer();
    notifier = container.read(chatPartnersProvider.notifier);
  });
  tearDown(() => container.dispose());

  String? active() => container.read(chatPartnersProvider).activeChatUserId;

  test('closing the chat on top makes the one under it active again', () {
    notifier.setActiveChat('a');
    notifier.setActiveChat('b');
    expect(active(), 'b');

    notifier.clearActiveChat('b');
    expect(active(), 'a');

    notifier.incrementUnread('a');
    expect(container.read(chatPartnersProvider).unreadCounts['a'], isNull,
        reason: 'a message in the chat on screen is not unread');
  });

  test('closing the last chat leaves no active chat', () {
    notifier.setActiveChat('a');
    notifier.clearActiveChat('a');
    expect(active(), isNull);
    notifier.incrementUnread('a');
    expect(container.read(chatPartnersProvider).unreadCounts['a'], 1);
  });

  test('a late close of a chat under the top does not change the top', () {
    notifier.setActiveChat('a');
    notifier.setActiveChat('b');
    notifier.clearActiveChat('a'); // a's dispose runs after b opened
    expect(active(), 'b');
  });

  test('closing a chat that is not open is a no-op', () {
    notifier.setActiveChat('a');
    notifier.clearActiveChat('zzz');
    expect(active(), 'a');
  });
}
