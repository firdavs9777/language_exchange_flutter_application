import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/models/notification_models.dart';
import 'package:bananatalk_app/providers/badge_count_provider.dart';
import 'package:bananatalk_app/providers/unread_count_provider.dart';

/// sync-badges counts unread in chats with deleted/hidden partners, which
/// the chat list never shows and the user can never clear; the tab badge
/// flipped between that total and the list's sum (live: 20 vs 8).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  BadgeCount server(int messages) =>
      BadgeCount.fromJson({'messages': messages, 'notifications': 3});

  test('before the chat list loads, the server total is used', () {
    final badge = container.read(badgeCountProvider.notifier);
    expect(badge.withChatListMessages(server(20)).messages, 20);
  });

  test('once the chat list has loaded, its sum wins over sync-badges', () {
    container
        .read(chatPartnersProvider.notifier)
        .applyServerCounts({'a': 5, 'b': 3});
    final badge = container.read(badgeCountProvider.notifier);
    final merged = badge.withChatListMessages(server(20));
    expect(merged.messages, 8);
    expect(merged.notifications, 3, reason: 'other counts still from server');
  });

  test('a later live increment keeps the list total current', () {
    final partners = container.read(chatPartnersProvider.notifier);
    partners.applyServerCounts({'a': 1});
    partners.incrementUnread('a');
    final badge = container.read(badgeCountProvider.notifier);
    expect(badge.withChatListMessages(server(20)).messages, 2);
  });
}
