# Chat Folder Restructure & UX Wins — Phase 1

**Date:** 2026-05-05
**Branch:** `refactor/chat-restructure-phase-1` (off `main`)
**Scope:** `lib/pages/chat/` only — 29 files, ~30,000 lines

## Goal

Bring the 29-file flat `chat/` tree under control:

1. Reorganize into category subfolders (`list/`, `conversation/`, `message/`, `input/`, `header/`, `panels/`, `dialogs/`, `search/`, `media/`, `bookmarks/`, `wallpaper/`, `error/`, `state/`, `models/`, `widgets/`)
2. Extract embedded models/dialogs/helpers (`ChatPartner`, `_EditMessageDialog`, `_ContextMenuItem`)
3. Split the 3 monsters (`chat_single.dart` 3,159 → ~700; `chat_main.dart` 2,535 → ~600; `chat_message_bubble.dart` 1,838 → ~600)
4. Extract `widgets/` for shared snackbar / dialog scaffold / empty state
5. Bundle UX wins: snackbar unification, empty-state polish, dark-mode pass, `withOpacity` cleanup, scroll-to-bottom FAB

Phase 2 (read receipts, reactions, voice recording, in-thread search, group chats) deferred to a separate spec.

## Current state

29 Dart files in `lib/pages/chat/`, all flat, no subfolders. Total ~30,000 lines. Top offenders:

| File | Lines | Notes |
|---|---|---|
| `chat_single.dart` | 3,159 | Conversation screen + embedded `_EditMessageDialog` |
| `chat_main.dart` | 2,535 | Chat list + embedded `ChatPartner` model |
| `chat_message_bubble.dart` | 1,838 | Message bubble + embedded `_ContextMenuItem` |
| `chat_app_bar.dart` | 695 | |
| `wallpaper_picker_screen.dart` | 649 | |
| `gif_picker_panel.dart` | 578 | |
| `chat_options_menu.dart` | 519 | |

Smells:
- ~15 inline `ScaffoldMessenger.showSnackBar(...)` blocks duplicated
- 5 nearly-identical dialog scaffolds (delete, mute, forward, options-menu, would-be-edit)
- Ad-hoc empty states across chat list / search / bookmarks / media
- Hardcoded `Colors.grey[*]` and `Colors.white` (not theme-aware) in some files
- ~30+ deprecated `withOpacity()` calls across the message bubble and panels
- `ChatPartner` data class lives at the top of `chat_main.dart` (lines 31-158) instead of in `models/`

## Target folder layout

```
lib/pages/chat/
├── chat_screen_wrapper.dart                 (untouched — 226 lines, OK)
│
├── widgets/                                 NEW shared building blocks
│   ├── chat_snackbar.dart                   showChatSnackBar()
│   ├── chat_dialog_scaffold.dart            common rounded card for dialogs
│   └── chat_empty_state.dart                MOVED from root + polished
│
├── list/                                    NEW — was chat_main.dart
│   ├── chat_list_screen.dart                ~600 (was 2535)
│   ├── chat_list_tile.dart
│   ├── chat_list_search_bar.dart
│   ├── chat_list_filter_tabs.dart
│   └── chat_list_empty_state.dart
│
├── conversation/                            NEW — was chat_single.dart
│   ├── chat_conversation_screen.dart        ~700 (was 3159)
│   ├── conversation_header.dart
│   ├── conversation_messages_view.dart
│   ├── conversation_input_area.dart
│   └── edit_message_dialog.dart             extracted from inline _EditMessageDialog
│
├── message/                                 NEW — was chat_message_bubble.dart + neighbors
│   ├── message_bubble.dart                  ~600 (was 1838)
│   ├── message_bubble/
│   │   ├── text_message_view.dart
│   │   ├── image_message_view.dart
│   │   ├── voice_message_view.dart
│   │   ├── gif_message_view.dart
│   │   └── reply_preview.dart
│   ├── messages_list.dart                   MOVED
│   ├── typing_indicator.dart                MOVED
│   ├── pinned_messages_bar.dart             MOVED
│   └── message_context_menu_item.dart       extracted from inline _ContextMenuItem
│
├── input/                                   NEW
│   ├── chat_input_bar.dart                  MOVED + slimmed
│   ├── chat_input_section.dart              MOVED
│   ├── media_option_button.dart             MOVED
│   └── sticker_button.dart                  MOVED
│
├── header/                                  NEW
│   ├── chat_app_bar.dart                    MOVED
│   ├── chat_user_info_card.dart             MOVED
│   └── user_avatar.dart                     MOVED
│
├── panels/                                  NEW — slide-up panels
│   ├── chat_media_panel.dart                MOVED
│   ├── chat_sticker_panel.dart              MOVED
│   └── gif_picker_panel.dart                MOVED
│
├── dialogs/                                 NEW
│   ├── delete_message_dialog.dart           MOVED
│   ├── forward_message_dialog.dart          MOVED
│   ├── mute_dialog.dart                     MOVED
│   ├── chat_options_menu.dart               MOVED
│   └── message_actions_bottom_sheet.dart    MOVED
│
├── search/                                  NEW
│   └── chat_search_screen.dart              MOVED
│
├── media/                                   NEW
│   └── chat_media_screen.dart               MOVED
│
├── bookmarks/                               NEW
│   └── bookmarks_screen.dart                MOVED
│
├── wallpaper/                               NEW
│   └── wallpaper_picker_screen.dart         MOVED
│
├── error/                                   NEW
│   └── chat_error_widget.dart               MOVED + polished
│
├── state/                                   NEW
│   └── chat_state_provider.dart             MOVED
│
└── models/                                  NEW
    └── chat_partner.dart                    extracted from chat_main.dart
```

29 files become ~45 after splits. No file in `chat/` ends Phase 1 over 800 lines. Most under 500.

## Shared widgets/ contents

### `widgets/chat_snackbar.dart`
```dart
enum ChatSnackBarType { success, error, info }
void showChatSnackBar(BuildContext context, {required String message, ChatSnackBarType type = ChatSnackBarType.success});
```
Same shape as `profile_snackbar` / `auth_snackbar` (intentionally — floating row+icon, hide-current, haptics). Replaces ~15 inline `ScaffoldMessenger.showSnackBar(...)` blocks.

### `widgets/chat_dialog_scaffold.dart`
```dart
class ChatDialogScaffold extends StatelessWidget {
  final IconData? heroIcon;
  final Color? heroColor;
  final String title;
  final String? body;
  final Widget? content;        // overrides body
  final List<Widget> actions;
}
```
Wraps gradient-circle-icon + title + body + actions. Replaces ~5 dialog scaffolds.

### `widgets/chat_empty_state.dart`
```dart
class ChatEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? body;
  final Widget? cta;
}
```
Generic — used by chat list / search / bookmarks / media empty states.

## File splits

### `chat_main.dart` (2,535 → ~600)
- Parent `list/chat_list_screen.dart` keeps state, scaffold, tab controller, lifecycle
- `list/chat_list_tile.dart` — per-thread row
- `list/chat_list_search_bar.dart` — top search bar
- `list/chat_list_filter_tabs.dart` — All/Unread/Partners segmented control
- `list/chat_list_empty_state.dart` — uses `widgets/chat_empty_state.dart`
- `models/chat_partner.dart` — extracted data class (was lines 31-158)

### `chat_single.dart` (3,159 → ~700)
- Parent `conversation/chat_conversation_screen.dart` keeps state class, scroll/lifecycle, message send pipeline, socket listeners, panel toggling
- `conversation/conversation_header.dart` — AppBar
- `conversation/conversation_messages_view.dart` — message list + scroll behavior
- `conversation/conversation_input_area.dart` — input bar wiring + panel toggling
- `conversation/edit_message_dialog.dart` — extracted from inline `_EditMessageDialog`

### `chat_message_bubble.dart` (1,838 → ~600)
- Parent `message/message_bubble.dart` keeps state, swipe-to-reply, context menu trigger; dispatches content rendering by message type
- `message/message_bubble/text_message_view.dart`
- `message/message_bubble/image_message_view.dart`
- `message/message_bubble/voice_message_view.dart`
- `message/message_bubble/gif_message_view.dart`
- `message/message_bubble/reply_preview.dart`
- `message/message_context_menu_item.dart` — was inline `_ContextMenuItem`

The dispatcher pattern:
```dart
Widget _buildMessageContent(Message msg) {
  return switch (msg.type) {
    MessageType.text  => TextMessageView(message: msg, ...),
    MessageType.image => ImageMessageView(message: msg, ...),
    MessageType.voice => VoiceMessageView(message: msg, ...),
    MessageType.gif   => GifMessageView(message: msg, ...),
    _                 => _FallbackMessageView(message: msg),
  };
}
```

A fallback view handles unknown types gracefully (no crashes if a system-message or deleted-message edge case slips through).

## UX wins

1. **Snackbar unification** — every chat-side `showSnackBar` migrates to `showChatSnackBar`.
2. **Empty-state polish** — chat list / search / bookmarks / media all use `ChatEmptyState`.
3. **Dark-mode pass** — sweep the 29 files for hardcoded grey/white. Apply same pattern as auth dark-mode pass (`context.scaffoldBackground / surfaceColor / textPrimary`).
4. **Deprecated `withOpacity` cleanup** — replace with `withValues(alpha:)` everywhere. Likely ~30+ sites.
5. **Scroll-to-bottom FAB** — when user scrolls up >300px from bottom in conversation, show floating "↓" button. Tap → animated scroll to latest. Hides at bottom.

## Migration plan — 11 commits

| # | Commit | Verification |
|---|---|---|
| C0 | Add `widgets/` (snackbar, dialog_scaffold, empty_state) | `flutter analyze` clean |
| C1 | Migrate ~15 inline snackbar calls to `showChatSnackBar` | snackbars still show |
| C2 | Migrate ~5 dialog files to use `ChatDialogScaffold` | dialogs render |
| C3 | Replace ad-hoc empty-state widgets with `ChatEmptyState` | empty states render |
| C4 | Extract `ChatPartner` to `models/chat_partner.dart` | app boots |
| C5 | Extract `_EditMessageDialog` to its own file | edit flow works |
| C6 | Extract `_ContextMenuItem` to its own file | context menu works |
| C7 | File moves into subfolders via `git mv` | `flutter analyze lib/` clean |
| C8 | Split `chat_main.dart` → `chat_list_screen.dart` + 4 list/ siblings | chat list works |
| C9 | Split `chat_message_bubble.dart` → `message_bubble.dart` + 5 type-views | every message type renders |
| C10 | Split `chat_single.dart` → `chat_conversation_screen.dart` + 3 conversation/ siblings + scroll-to-bottom FAB | conversation works, FAB toggles correctly |
| C11 | Dark-mode + `withOpacity` cleanup across remaining chat files | toggle dark mode, walk all screens |

Each commit gates on `flutter analyze` clean + a manual smoke test of the touched flow.

## Risks

- **Tightly coupled state in `chat_single.dart`** — split sections stay as dumb widgets receiving callbacks; the state class keeps owning controllers, listeners, the typing-indicator socket subscription. Splits are visual-only.
- **Message-type dispatcher misses edge case** (system messages, deleted placeholders) — read every branch of existing `_buildMessageContent` before extracting. Add `_FallbackMessageView` for unknown types.
- **Import sprawl from 29 file moves** — `git mv` preserves history; Python script for project-wide import sweep (proven pattern from profile + auth).
- **Riverpod provider scope** — `chat_state_provider` stays in `state/` with same lifecycle.
- **Dark-mode regression** — walk every chat screen toggling dark mode after C11.

## Out of scope (Phase 2/3)

- Read receipts (per-message delivered/read state)
- Message reactions
- Voice-message recording (only playback today)
- Message search-within-thread
- Group chats (1:1 only today)
- E2EE
- Tests for any chat widget
