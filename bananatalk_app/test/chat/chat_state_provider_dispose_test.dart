import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/providers/chat_state_provider.dart';

/// Every opened chat used to keep its notifier (socket subscriptions, the
/// status timer, a lifecycle observer) alive until logout. It now goes away
/// a short while after its last screen closes.
void main() {
  final params = ChatProviderParams(chatPartnerId: 'p', currentUserId: 'me');

  testWidgets('released after the grace period once nobody listens', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final sub = container.listen(chatStateProvider(params), (_, __) {});
    final notifier = container.read(chatStateProvider(params).notifier);
    sub.close();

    await tester.pump(
      ChatStateNotifier.releaseDelay - const Duration(seconds: 1),
    );
    expect(notifier.mounted, isTrue);

    await tester.pump(const Duration(seconds: 2));
    expect(notifier.mounted, isFalse);
  });

  testWidgets('reopening within the grace period keeps the same notifier', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final first = container.listen(chatStateProvider(params), (_, __) {});
    final notifier = container.read(chatStateProvider(params).notifier);
    first.close();
    await tester.pump(const Duration(seconds: 10));

    final second = container.listen(chatStateProvider(params), (_, __) {});
    await tester.pump(ChatStateNotifier.releaseDelay * 2);
    expect(container.read(chatStateProvider(params).notifier), same(notifier));
    expect(notifier.mounted, isTrue);
    second.close();
    await tester.pump(ChatStateNotifier.releaseDelay);
    expect(notifier.mounted, isFalse);
  });
}
