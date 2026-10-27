import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/providers/unread_count_provider.dart';

/// The chat list used to keep any local count over the server's, including
/// the 0s kept on purpose, so counts drifted until restart: messages missed
/// while offline stayed at 0, reads on web left a stale badge.
void main() {
  late ProviderContainer container;
  late ChatPartnersNotifier notifier;

  setUp(() {
    container = ProviderContainer();
    notifier = container.read(chatPartnersProvider.notifier);
  });
  tearDown(() => container.dispose());

  int? count(String id) => container.read(chatPartnersProvider).unreadCounts[id];

  test('the server count replaces a stale local 0', () {
    notifier.updateUnreadCount('a', 0); // e.g. opened earlier this session
    final shown = notifier.applyServerCounts({'a': 3});
    expect(shown['a'], 3);
    expect(count('a'), 3);
  });

  test('read elsewhere: the server 0 clears a local count', () {
    notifier.updateUnreadCount('a', 5);
    notifier.applyServerCounts({'a': 0});
    expect(count('a'), 0);
  });

  test('just read here: a server count from before the read is ignored', () {
    notifier.updateUnreadCount('a', 2);
    notifier.clearUnread('a');
    notifier.applyServerCounts({'a': 2});
    expect(count('a'), 0);
  });

  test('after the grace period the server wins again', () {
    notifier.clearUnread('a');
    notifier.applyServerCounts(
      {'a': 4},
      now: DateTime.now().add(ChatPartnersNotifier.readSyncGrace * 2),
    );
    expect(count('a'), 4);
  });

  test('the chat on screen always shows 0', () {
    notifier.setActiveChat('a');
    notifier.applyServerCounts({'a': 7});
    expect(count('a'), 0);
  });

  test('the total follows the applied counts', () {
    notifier.applyServerCounts({'a': 2, 'b': 3});
    expect(container.read(chatPartnersProvider).totalUnread, 5);
  });
}
