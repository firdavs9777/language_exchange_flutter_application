# Global Badge Count System

## Overview
This system ensures that unread message counts update in real-time across all tabs, even when the ChatMain screen is not visible.

## Architecture

### Components

1. **`GlobalChatListener`** (`lib/services/global_chat_listener.dart`)
   - Singleton service that listens to socket events globally
   - Initialized at app startup in `main.dart`
   - Automatically updates unread counts when messages arrive or are read
   - Works independently of UI state

2. **`ChatPartnersNotifier`** (`lib/providers/unread_count_provider.dart`)
   - Manages unread counts per chat partner
   - Automatically updates `badgeCountProvider` when counts change
   - Provides `incrementUnread()`, `clearUnread()`, and `updateUnreadCount()` methods

3. **`BadgeCountNotifier`** (`lib/providers/badge_count_provider.dart`)
   - Global badge count state (messages and notifications)
   - Updated automatically by `ChatPartnersNotifier`
   - Watched by `TabBarMenu` to display badge counts

4. **`TabBarMenu`** (`lib/pages/menu_tab/TabBarMenu.dart`)
   - Watches `badgeCountProvider` directly
   - Automatically rebuilds when badge count changes
   - Displays unread count in the chat tab badge

## How It Works

### Flow for New Messages:
1. Socket receives `newMessage` event
2. `ChatSocketService` emits to `onNewMessage` stream
3. `GlobalChatListener` receives the event
4. Extracts sender ID and increments unread count via `chatPartnersProvider.notifier.incrementUnread()`
5. `ChatPartnersNotifier` updates its state and automatically calls `badgeCountProvider.notifier.updateMessageCount()`
6. `BadgeCountNotifier` updates its state
7. `TabBarMenu` rebuilds (because it watches `badgeCountProvider`) and shows the new count

### Flow for Read Messages:
1. Socket receives `messageRead` event
2. `GlobalChatListener` receives the event
3. Clears unread count via `chatPartnersProvider.notifier.clearUnread()`
4. Same update chain as above, but count decreases

## Usage

### To get the current badge count:
```dart
final badgeCount = ref.watch(badgeCountProvider);
final messageCount = badgeCount.messages;
final notificationCount = badgeCount.notifications;
```

### To manually update unread count (if needed):
```dart
// Increment for a specific user
ref.read(chatPartnersProvider.notifier).incrementUnread(userId);

// Clear for a specific user
ref.read(chatPartnersProvider.notifier).clearUnread(userId);

// Set specific count
ref.read(chatPartnersProvider.notifier).updateUnreadCount(userId, count);
```

### To reset all badge counts (on logout):
```dart
ref.read(chatPartnersProvider.notifier).reset();
ref.read(badgeCountProvider.notifier).reset();
```

## Key Files

- `lib/services/global_chat_listener.dart` - Global socket event listener
- `lib/services/chat_socket_service.dart` - Socket service with event streams
- `lib/providers/unread_count_provider.dart` - Unread count state management
- `lib/providers/badge_count_provider.dart` - Global badge count state
- `lib/pages/menu_tab/TabBarMenu.dart` - UI that displays the badge
- `lib/main.dart` - Initializes `GlobalChatListener` at app startup

## Notes

- The system works automatically - no manual intervention needed
- Badge counts update in real-time, even when on other tabs
- The listener persists across tab switches and app lifecycle events
- Badge counts are reset on logout automatically

