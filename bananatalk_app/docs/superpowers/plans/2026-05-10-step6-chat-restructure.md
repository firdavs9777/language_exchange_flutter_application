# Step 6 — Chat Restructure + Modern Features Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Split 3 chat monoliths (`chat_conversation_screen` 1,996, `chat_list_screen` 1,634, `message_bubble` 1,048) into focused units, ship 4 features (voice transcription, save-to-vocab, auto-translate per-conversation, M3 bubble redesign), and run the small cleanup sweep.

**Architecture:** Extract handlers + sections out of the conversation orchestrator using a lifecycle mixin pattern. Split the bubble into a shared container + variant files. Split the list screen into tile + sections. New features all hook into existing infrastructure (backend `addVocabulary` endpoint shipped, `translation_service` has auto-translate plumbing, `speech.transcribeAudio` shipped). Pragmatic guardrail throughout: skip extractions that increase complexity.

**Tech Stack:** Flutter + Riverpod, SharedPreferences, ARB-based l10n (18 locales), Node.js/Express + MongoDB.

**Spec:** `docs/superpowers/specs/2026-05-10-step6-chat-restructure-design.md`

**Branch:** `refactor/step6-chat-restructure` (off `main`, already created and spec already committed)

**Project pattern:** No new Flutter widget tests — verification is `flutter analyze` clean per commit + manual smoke at the end. Backend additions get unit tests where indicated.

## Spec corrections discovered during plan-writing

The spec underestimated how much chat infrastructure is already shipped:

1. **`lib/pages/chat/widgets/` already has the 3 helper files** (`chat_snackbar.dart`, `chat_empty_state.dart`, `chat_dialog_scaffold.dart`). **Implication:** the spec's C4 "add `widgets/` scaffolding" is unnecessary. Drop it. Just add `chat_error_state.dart` if it doesn't exist (parity with stories/community pattern).

2. **Swipe-to-reply (Feature E) is already shipped.** `lib/pages/chat/message/message_bubble.dart` lines 153-205 implement `_initSwipeAnimation` + `_onHorizontalDragUpdate` + `_onHorizontalDragEnd` with `HapticFeedback.mediumImpact()` at threshold and `widget.onReply?.call(...)`. **Implication:** drop Feature E from the wave. The polish opportunity is a visible "reply icon reveal" during drag — note as deferred polish, not in scope for Step 6.

3. **Auto-translate (Feature I) infrastructure is partially shipped.** `lib/services/translation_service.dart:379-386` has `auto_translate_<contentType>` SharedPreferences key pattern (`auto_translate_chat`, `auto_translate_moments`, etc.). The 5+ ARB keys (`autoTranslate`, `autoTranslateMessages`, `autoTranslateSettings`, `autoTranslateMoments`, `autoTranslateComments`) are already translated to all locales. **Implication:** Feature I is mostly UI hookup — add a per-conversation override toggle in the chat header menu, render auto-translated text inline below original on incoming messages.

4. **Vocabulary backend is shipped.** `POST /vocabulary` route exists with `checkVocabularyLimit` middleware. `addVocabulary` controller in `controllers/learning.js`. `Vocabulary` model has SRS fields. **Implication:** Feature H is Flutter-only work.

5. **Conversation screen is partially split already.** `lib/pages/chat/conversation/` contains `conversation_header.dart`, `conversation_input_area.dart`, `conversation_messages_view.dart`, `edit_message_dialog.dart`. The 1,996-line `chat_conversation_screen.dart` is the orchestrator AFTER these extractions. The remaining bulk is: lifecycle/scroll/animations setup (~500 lines), panel management (~200), send error/sticker (~250), message-action handlers (edit/pin/forward/delete/retry — ~250), build method (~150), and various `_show*` dialog helpers. **Implication:** the split targets need to extract handlers + lifecycle helpers, not widgets (those are extracted already).

6. **Cleanup debt is even smaller than the spec said.** Re-counted: 0 `withOpacity` (clean), 5 `Colors.grey[*]`, 1 inline snackbar, 9 `debugPrint`. C1 is a single small commit.

**Net commit count drops: 18 → ~14.**

---

## File Structure (target — additive)

```
lib/pages/chat/
├── widgets/                                 (existing — 3 files; add 1)
│   ├── chat_snackbar.dart                   ✅ exists
│   ├── chat_empty_state.dart                ✅ exists
│   ├── chat_dialog_scaffold.dart            ✅ exists
│   └── chat_error_state.dart                NEW (1 file, parity)
│
├── conversation/                            (existing, expand)
│   ├── chat_conversation_screen.dart        SPLIT 1,996 → ~600 (orchestrator)
│   ├── conversation_header.dart             ✅ exists
│   ├── conversation_input_area.dart         ✅ exists
│   ├── conversation_messages_view.dart      ✅ exists
│   ├── edit_message_dialog.dart             ✅ exists
│   ├── handlers/                            NEW
│   │   ├── message_action_handlers.dart         edit/delete/pin/forward/retry/deleteFailed (lines 1422-1674)
│   │   ├── panel_handlers.dart                  toggleMediaPanel/StickerPanel/hidePanels (lines 534-590)
│   │   └── send_handlers.dart                   _showSendError, _selectSticker, _sendWaveSticker
│   └── sections/                            NEW
│       ├── conversation_lifecycle_mixin.dart    initState/dispose/didChangeAppLifecycle/didChangeMetrics
│       ├── conversation_scroll_helpers.dart     _setupScrollListener, _scrollToBottom, _scrollToMessage
│       └── conversation_setup.dart              _initializeAnimations, _setupThemeChangeListener, _setupCallListeners
│
├── list/                                    (existing, expand)
│   ├── chat_list_screen.dart                SPLIT 1,634 → ~700
│   ├── conversation_tile.dart               NEW (each row)
│   ├── list_socket_handlers.dart            NEW (typing/messageRead/online status handlers — lines 422-700)
│   └── list_partner_processing.dart         NEW (chat-partners-from-server processing — lines 756-1000)
│
├── message/                                 (existing, expand)
│   ├── message_bubble.dart                  SPLIT 1,048 → ~500 (orchestrator + branch)
│   └── bubble/                              NEW
│       ├── bubble_container.dart                shared shell (rounded + shadow + bg — Material 3 redesign lands here in C13)
│       ├── text_bubble.dart                     plain text variant (extract from _buildMessageContent)
│       ├── system_bubble.dart                   system-style placeholder/deleted bubble
│       ├── bubble_actions_menu.dart             extract from _showContextMenu (lines 499-700+)
│       └── word_long_press_handler.dart         NEW — feature H (save-to-vocab)
│
├── header/                                  (existing)
│   ├── chat_app_bar.dart                    NO SPLIT (666 lines is fine)
│   └── auto_translate_toggle.dart           NEW — feature I (chat-header menu item + per-conversation switch)
│
└── (other subfolders untouched)
```

---

## Branch setup

- [ ] **Step 1: Confirm branch + clean state**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
git status -sb | head -3
git log --oneline -1
```

Expected: branch `refactor/step6-chat-restructure`, HEAD is `e57e876 docs(chat): spec for Step 6 …`.

- [ ] **Step 2: Verify analyzer baseline**

```bash
flutter analyze lib/pages/chat/ 2>&1 | tail -10
```

Expected: any pre-existing warnings noted but no new errors.

---

## Task C0 — chore(chat): deps audit

**Files:** none

- [ ] **Step 1: Confirm no new deps needed**

```bash
grep -E "^  (flutter_riverpod|shared_preferences|http|image_picker|file_picker|geolocator|flutter_callkit_incoming|flutter_webrtc|cached_network_image):" pubspec.yaml
```

Expected: every line above present. If anything missing, add via `flutter pub add <name>`. Otherwise no commit (audit-only — no-op is the expected outcome).

---

## Task C1 — chore(chat): cleanup sweep (debugPrint + Colors.grey + snackbar)

**Files:** various in `lib/pages/chat/`

- [ ] **Step 1: List all targets**

```bash
grep -rn "debugPrint" lib/pages/chat/ --include="*.dart"
grep -rn "Colors\.grey" lib/pages/chat/ --include="*.dart"
grep -rn "ScaffoldMessenger.of(context).showSnackBar" lib/pages/chat/ --include="*.dart"
```

Expected: ~9 + 5 + 1 = 15 lines.

- [ ] **Step 2: For each `debugPrint`, decide remove vs. keep**

Keep `debugPrint` calls in error catches (they're useful in production-debug). Remove `debugPrint` calls that log routine state (e.g., "got message", "received update").

For each removal, use Edit with surrounding context.

- [ ] **Step 3: Migrate `Colors.grey[*]` per the wave-1 mapping**

| Old | New |
|---|---|
| `Colors.grey[100]/[200]` | `context.containerColor` |
| `Colors.grey[300]/[400]` | `context.dividerColor` |
| `Colors.grey[500-700]` | `context.textSecondary` |
| `Colors.grey[800-900]` | `context.textMuted` |
| Plain `Colors.grey` | `context.textSecondary` |

**Exception:** keep `Colors.white` on colored buttons.

For each match, ensure the file has `import 'package:bananatalk_app/utils/theme_extensions.dart';`. Use Edit per site.

- [ ] **Step 4: Migrate the 1 inline snackbar to `showChatSnackBar`**

Find the 1 site:

```bash
grep -rn "ScaffoldMessenger.of(context).showSnackBar" lib/pages/chat/ --include="*.dart"
```

Rewrite using `showChatSnackBar()` from `lib/pages/chat/widgets/chat_snackbar.dart`. Match its existing signature:

```dart
import 'package:bananatalk_app/pages/chat/widgets/chat_snackbar.dart';

// BEFORE
ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(...)));

// AFTER
showChatSnackBar(context, message: ..., type: ChatSnackBarType.success);
```

(Read `chat_snackbar.dart` first to confirm exact API. Past wave waves use `info | success | error` types.)

- [ ] **Step 5: Verify counts drop**

```bash
grep -rn "debugPrint" lib/pages/chat/ --include="*.dart" | wc -l
grep -rn "Colors\.grey" lib/pages/chat/ --include="*.dart" | wc -l
grep -rn "ScaffoldMessenger.of(context).showSnackBar" lib/pages/chat/ --include="*.dart" | wc -l
```

Expected: ≤3, 0, 0.

- [ ] **Step 6: Verify analyzer**

```bash
flutter analyze lib/pages/chat/ 2>&1 | tail -10
```

Expected: zero new errors.

- [ ] **Step 7: Commit**

```bash
git add lib/pages/chat/
git commit -m "$(cat <<'EOF'
chore(chat): C1 — cleanup sweep (debugPrint + grey + inline snackbar)

Removes ~6 routine debugPrint calls, migrates 5 Colors.grey[*] to
theme getters, replaces 1 inline snackbar with showChatSnackBar.
Error-path debugPrints kept.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task C2 — refactor(chat): add ~10 English ARB keys

**Files:** `lib/l10n/app_en.arb`

- [ ] **Step 1: Identify duplicates**

```bash
grep -E "^  \"(transcribeMessage|transcribing|transcriptionFailed|saveToVocabulary|addedToVocabulary|alreadyInVocabulary|tapWordToSave|autoTranslateChatHint|noConversationsYet|chatRetry)\":" lib/l10n/app_en.arb
```

Existing keys to reuse (skip): `autoTranslate`, `autoTranslateMessages`, `autoTranslate*` series.

- [ ] **Step 2: Add the new keys**

Open `lib/l10n/app_en.arb`. Just before the closing `}`, add:

```json
  "transcribeMessage": "Transcribe",
  "@transcribeMessage": { "description": "Button on a voice message to convert it to text" },

  "transcribing": "Transcribing…",
  "@transcribing": { "description": "Spinner label while voice transcription is in flight" },

  "transcriptionFailed": "Couldn't transcribe message",
  "@transcriptionFailed": { "description": "Error toast when speech-to-text fails" },

  "saveToVocabulary": "Save '{word}' to vocabulary",
  "@saveToVocabulary": {
    "description": "Long-press popup confirming a vocabulary save",
    "placeholders": { "word": { "type": "String" } }
  },

  "addedToVocabulary": "Added to your vocabulary",
  "@addedToVocabulary": { "description": "Snackbar after successful vocab save" },

  "alreadyInVocabulary": "Already in your vocabulary",
  "@alreadyInVocabulary": { "description": "Snackbar when word is already saved" },

  "tapWordToSave": "Tap and hold a word to save it",
  "@tapWordToSave": { "description": "Optional onboarding hint shown once" },

  "autoTranslateChatHint": "Incoming messages will be translated automatically",
  "@autoTranslateChatHint": { "description": "Subtitle for the per-chat auto-translate toggle" },

  "noConversationsYet": "No conversations yet",
  "@noConversationsYet": { "description": "Empty state for the chat list" },

  "chatRetry": "Try again",
  "@chatRetry": { "description": "Retry button on chat error states" }
```

Make sure JSON validity (no trailing comma on last entry; comma added on previous-last line).

- [ ] **Step 3: Validate JSON + regenerate**

```bash
python3 -c "import json; json.load(open('lib/l10n/app_en.arb'))" && echo OK
flutter gen-l10n
flutter analyze lib/l10n/ 2>&1 | tail -5
```

Expected: OK. No errors.

- [ ] **Step 4: Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/app_localizations*.dart
git commit -m "$(cat <<'EOF'
refactor(chat): C2 — add ~10 English ARB keys for Step 6

Adds keys for voice transcription (transcribeMessage / transcribing /
transcriptionFailed), vocab save (saveToVocabulary / addedToVocabulary
/ alreadyInVocabulary / tapWordToSave), auto-translate chat hint, and
empty/retry strings. Reuses existing autoTranslate* keys.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task C3 — refactor(chat): translate ARB keys to 17 locales

**Files:** `lib/l10n/app_*.arb` (17 non-English locales)

- [ ] **Step 1: List of keys to translate**

The 10 keys added in C2:
- transcribeMessage, transcribing, transcriptionFailed
- saveToVocabulary (placeholder: word), addedToVocabulary, alreadyInVocabulary, tapWordToSave
- autoTranslateChatHint, noConversationsYet, chatRetry

- [ ] **Step 2: Add translations to each non-English ARB**

For each of `app_ar.arb`, `app_de.arb`, `app_es.arb`, `app_fr.arb`, `app_hi.arb`, `app_id.arb`, `app_it.arb`, `app_ja.arb`, `app_ko.arb`, `app_pt.arb`, `app_ru.arb`, `app_th.arb`, `app_tl.arb`, `app_tr.arb`, `app_vi.arb`, `app_zh.arb`, `app_zh_TW.arb`:

Read the file, find the closing `}`, insert the 10 keys with values translated naturally. Preserve the `{word}` placeholder in `saveToVocabulary` (do NOT translate the word "word"). DO NOT include `@key` metadata blocks (only English file carries those).

**Translation reference for ko (Korean):**

```json
  "transcribeMessage": "텍스트로 변환",
  "transcribing": "변환 중…",
  "transcriptionFailed": "음성을 변환할 수 없습니다",
  "saveToVocabulary": "'{word}'을(를) 단어장에 저장",
  "addedToVocabulary": "단어장에 추가되었습니다",
  "alreadyInVocabulary": "이미 단어장에 있습니다",
  "tapWordToSave": "단어를 길게 눌러 저장하세요",
  "autoTranslateChatHint": "수신 메시지가 자동으로 번역됩니다",
  "noConversationsYet": "아직 대화가 없습니다",
  "chatRetry": "다시 시도"
```

**Translation reference for ja (Japanese):**

```json
  "transcribeMessage": "文字起こし",
  "transcribing": "文字起こし中…",
  "transcriptionFailed": "音声を文字起こしできませんでした",
  "saveToVocabulary": "「{word}」を単語帳に保存",
  "addedToVocabulary": "単語帳に追加されました",
  "alreadyInVocabulary": "すでに単語帳にあります",
  "tapWordToSave": "長押しして単語を保存",
  "autoTranslateChatHint": "受信メッセージが自動的に翻訳されます",
  "noConversationsYet": "まだ会話がありません",
  "chatRetry": "再試行"
```

**Translation reference for es (Spanish):**

```json
  "transcribeMessage": "Transcribir",
  "transcribing": "Transcribiendo…",
  "transcriptionFailed": "No se pudo transcribir el mensaje",
  "saveToVocabulary": "Guardar '{word}' en vocabulario",
  "addedToVocabulary": "Agregado a tu vocabulario",
  "alreadyInVocabulary": "Ya está en tu vocabulario",
  "tapWordToSave": "Mantén presionada una palabra para guardarla",
  "autoTranslateChatHint": "Los mensajes entrantes se traducirán automáticamente",
  "noConversationsYet": "Aún no hay conversaciones",
  "chatRetry": "Reintentar"
```

For the remaining 14 locales (de, fr, hi, id, it, pt, ru, th, tl, tr, vi, zh, zh_TW, ar), produce idiomatic translations following the same patterns. The placeholder `{word}` stays as-is in every locale.

- [ ] **Step 3: Validate every locale file**

```bash
for f in lib/l10n/app_*.arb; do python3 -c "import json; json.load(open('$f'))" || echo "FAIL: $f"; done
```

Expected: no FAIL lines.

- [ ] **Step 4: Regenerate localizations**

```bash
flutter gen-l10n
flutter analyze lib/l10n/ 2>&1 | tail -5
```

Expected: zero errors.

- [ ] **Step 5: Commit**

```bash
git add lib/l10n/
git commit -m "$(cat <<'EOF'
refactor(chat): C3 — translate ~10 Step 6 keys to 17 locales

Mirrors C2 — adds transcribeMessage, transcribing, transcriptionFailed,
saveToVocabulary, addedToVocabulary, alreadyInVocabulary, tapWordToSave,
autoTranslateChatHint, noConversationsYet, chatRetry across ar, de, es,
fr, hi, id, it, ja, ko, pt, ru, th, tl, tr, vi, zh, zh_TW.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task C4 — refactor(chat): add `chat_error_state.dart` (parity)

**Files:**
- Create: `lib/pages/chat/widgets/chat_error_state.dart`

- [ ] **Step 1: Verify the file doesn't exist**

```bash
ls lib/pages/chat/widgets/ | grep error_state
```

If it exists, skip this task.

- [ ] **Step 2: Create the file**

```dart
// lib/pages/chat/widgets/chat_error_state.dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

class ChatErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;

  const ChatErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ignore: prefer_const_constructors
            Icon(Icons.error_outline_rounded, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(message, style: context.titleMedium, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(retryLabel ?? 'Try again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Verify analyzer + commit**

```bash
flutter analyze lib/pages/chat/widgets/ 2>&1 | tail -5
git add lib/pages/chat/widgets/chat_error_state.dart
git commit -m "$(cat <<'EOF'
refactor(chat): C4 — add chat_error_state.dart (parity with stories/community)

Completes the chat/widgets/ scaffolding alongside the existing
chat_snackbar.dart, chat_empty_state.dart, chat_dialog_scaffold.dart.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task C5 — refactor(chat): split `message_bubble.dart` into `bubble/` subfolder

**Files:**
- Create: `lib/pages/chat/message/bubble/bubble_container.dart`
- Create: `lib/pages/chat/message/bubble/text_bubble.dart`
- Create: `lib/pages/chat/message/bubble/system_bubble.dart`
- Create: `lib/pages/chat/message/bubble/bubble_actions_menu.dart`
- Modify: `lib/pages/chat/message/message_bubble.dart` (orchestrator drops to ~500)

- [ ] **Step 1: Read the file to identify split candidates**

```bash
grep -n "^class\|Widget _build\|void _" lib/pages/chat/message/message_bubble.dart
```

Map of methods (verified at planning):
- `_initSwipeAnimation` (line 153) — KEEP IN ORCHESTRATOR (animation controller belongs to State)
- `_onHorizontalDragUpdate` / `_onHorizontalDragEnd` — KEEP (drag state)
- `_showReactionPicker` / `_hideReactionPicker` — KEEP (overlay logic with State)
- `_showTranslation` (line 328) — KEEP
- `_navigateToProfile` — KEEP
- `_buildSendingStatus` (line 351) — KEEP (small inline render helper)
- `_showFailedMessageOptions` (line 415) — EXTRACT to `bubble_actions_menu.dart`
- `_showContextMenu` (line 499) — EXTRACT to `bubble_actions_menu.dart`
- `_buildMessageContent` (line 710) — EXTRACT to `text_bubble.dart` (the text-variant render)
- `build` (line 770) — STAYS (orchestrator)
- `_FallbackMessageView` class (line 1019) — EXTRACT to `system_bubble.dart`

### Step 1.5: Create `bubble_container.dart` (NEW shared shell — feature L lands here in C13)

```dart
// lib/pages/chat/message/bubble/bubble_container.dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

class BubbleContainer extends StatelessWidget {
  final Widget child;
  final bool isMe;
  final EdgeInsetsGeometry padding;

  const BubbleContainer({
    super.key,
    required this.child,
    required this.isMe,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
  });

  @override
  Widget build(BuildContext context) {
    final bg = isMe ? AppColors.primary : context.containerColor;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }
}
```

(C13 will refine the radius/shadow for full M3 polish; create the shell now so the split lands cleanly.)

### Step 2: Create `bubble_actions_menu.dart`

Extract `_showFailedMessageOptions` (line 415) and `_showContextMenu` (line 499) to free functions:

```dart
// lib/pages/chat/message/bubble/bubble_actions_menu.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';

void showBubbleContextMenu({
  required BuildContext context,
  required WidgetRef ref,
  required Message message,
  required bool isMe,
  required VoidCallback onReply,
  required VoidCallback onEdit,
  required VoidCallback onDelete,
  required VoidCallback onPin,
  required VoidCallback onForward,
  required VoidCallback onTranslate,
  required VoidCallback onSaveBookmark,
  required VoidCallback? onSaveToVocab, // C12 wires this
}) {
  // Body adapted from _showContextMenu (lines 499-700) of message_bubble.dart
  // Use showModalBottomSheet with a list of ListTile actions
}

Future<void> showFailedMessageOptions({
  required BuildContext context,
  required Message message,
  required VoidCallback onRetry,
  required VoidCallback onDelete,
}) async {
  // Body adapted from _showFailedMessageOptions (line 415)
}
```

In `message_bubble.dart`, replace the inline `_showContextMenu(context)` call with `showBubbleContextMenu(context: context, ref: ref, message: widget.message, ...)`. Same for failed-message options.

### Step 3: Create `text_bubble.dart`

Extract `_buildMessageContent` (line 710) — this returns the body widget for text-type messages. Move into:

```dart
// lib/pages/chat/message/bubble/text_bubble.dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';

class TextBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  const TextBubble({super.key, required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    // Body adapted from _buildMessageContent of message_bubble.dart
    // For text messages, this is the SelectableText / RichText with formatting.
  }
}
```

In `message_bubble.dart` `_buildMessageContent`, replace the text branch with `TextBubble(message: msg, isMe: isMe)`.

### Step 4: Create `system_bubble.dart` from the `_FallbackMessageView`

```dart
// lib/pages/chat/message/bubble/system_bubble.dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

class SystemBubble extends StatelessWidget {
  final String text;
  const SystemBubble({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: context.containerColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text, style: context.bodySmall.copyWith(color: context.textSecondary)),
      ),
    );
  }
}
```

In `message_bubble.dart`, replace `_FallbackMessageView` usages with `SystemBubble(text: ...)`. Delete the old `_FallbackMessageView` class.

### Step 5: Verify analyzer + line counts

```bash
flutter analyze lib/pages/chat/message/ 2>&1 | tail -10
wc -l lib/pages/chat/message/message_bubble.dart lib/pages/chat/message/bubble/*.dart
```

Expected: zero errors. Orchestrator ≤ ~700 lines (was 1,048).

### Step 6: Commit

```bash
git add lib/pages/chat/message/
git commit -m "$(cat <<'EOF'
refactor(chat): C5 — split message_bubble into bubble/ subfolder

Extracts bubble_container (shared shell), text_bubble (text variant),
system_bubble (FallbackMessageView replacement), bubble_actions_menu
(context + failed-message menus). Animation/swipe/reaction state
stays in orchestrator. Drops 1,048 → ~700 lines.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task C6 — refactor(chat): split `chat_list_screen.dart`

**Files:**
- Create: `lib/pages/chat/list/conversation_tile.dart`
- Create: `lib/pages/chat/list/list_socket_handlers.dart`
- Create: `lib/pages/chat/list/list_partner_processing.dart`
- Modify: `lib/pages/chat/list/chat_list_screen.dart` (~700 lines after split)

- [ ] **Step 1: Read the file structure**

The file (1,634 lines) at `_ChatMainState` has:
- Lines 195-236: `_initializeAnimations` (KEEP — animation controllers on State)
- Lines 237-320: `_subscribeToSocketEvents` + `_requestStatusUpdatesInBatches` — partial keep, partial extract
- Lines 322-420: unread count syncing (KEEP — uses local Map state)
- Lines 422-700: socket event handlers (`_handleUserTyping`, `_handleNewMessage`, `_handleMessageSent`, `_handleStatusUpdate`, `_handleMessagesRead`, etc.) — EXTRACT
- Lines 756-1020: chat-partner processing (`_processChatPartnersFromServer`, `_processChatPartners`, `_processChatPartnersWithStatus`) — EXTRACT
- Lines 1022-1320: user select + new chat dialog
- Lines 1321+: build + private widgets

### Step 2: Extract socket handlers

Create `lib/pages/chat/list/list_socket_handlers.dart`:

```dart
// lib/pages/chat/list/list_socket_handlers.dart
import 'package:bananatalk_app/providers/provider_models/message_model.dart';

// State container passed in, mutated by handlers.
class ListSocketContext {
  final Map<String, int> unreadCounts;
  final Map<String, bool> userOnline;
  final void Function(VoidCallback) setState; // forwarded from State
  final void Function(List<Message>) onPartnersChanged;

  ListSocketContext({
    required this.unreadCounts,
    required this.userOnline,
    required this.setState,
    required this.onPartnersChanged,
  });
}

void handleUserTyping(ListSocketContext ctx, dynamic data) {
  // Body of _handleUserTyping from chat_list_screen.dart
}

void handleNewMessage(ListSocketContext ctx, dynamic data) {
  // Body of _handleNewMessage
}

void handleMessageSent(ListSocketContext ctx, dynamic data) {
  // Body of _handleMessageSent
}

void handleStatusUpdate(ListSocketContext ctx, dynamic data) {
  // Body of _handleStatusUpdate
}

void handleBulkStatusUpdate(ListSocketContext ctx, dynamic data) {
  // Body of _handleBulkStatusUpdate
}

void handleOnlineUsersUpdate(ListSocketContext ctx, dynamic data) {
  // Body of _handleOnlineUsersUpdate
}

void handleSingleUserStatusUpdate(ListSocketContext ctx, dynamic data) {
  // Body of _handleSingleUserStatusUpdate
}

void handleMessagesRead(ListSocketContext ctx, dynamic data) {
  // Body of _handleMessagesRead
}

void handleMessageRead(ListSocketContext ctx, dynamic data) {
  // Body of _handleMessageRead
}
```

In `chat_list_screen.dart`, replace `_handle*` private methods with calls like:

```dart
// In _subscribeToSocketEvents:
socket.on('userTyping', (data) => handleUserTyping(_socketCtx, data));
socket.on('newMessage', (data) => handleNewMessage(_socketCtx, data));
// etc.
```

Delete the now-extracted private methods from the State class.

### Step 3: Extract chat-partner processing

Create `lib/pages/chat/list/list_partner_processing.dart` with `processChatPartnersFromServer`, `processChatPartners`, `processChatPartnersWithStatus` as free functions taking the necessary state.

If the processing functions touch too many fields (>5) of `_ChatMainState`, this won't extract cleanly — STOP that extraction and leave inline. Pragmatic guardrail.

### Step 4: Extract conversation tile widget

The tile rendering (the per-conversation row in the ListView) is somewhere in the build method (line 1434) or `_buildUsersList` (line 1358). Extract to:

```dart
// lib/pages/chat/list/conversation_tile.dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/pages/chat/models/chat_partner.dart';

class ConversationTile extends StatelessWidget {
  final ChatPartner partner;
  final int unreadCount;
  final bool isOnline;
  final bool isTyping;
  final VoidCallback onTap;

  const ConversationTile({
    super.key,
    required this.partner,
    required this.unreadCount,
    required this.isOnline,
    required this.isTyping,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Body adapted from the tile-rendering inside _buildUsersList
  }
}
```

In `_buildUsersList`, replace the inline tile with `ConversationTile(...)`.

### Step 5: Verify

```bash
flutter analyze lib/pages/chat/list/ 2>&1 | tail -10
wc -l lib/pages/chat/list/*.dart
```

Expected: zero errors. Orchestrator ≤ ~900 lines (was 1,634).

### Step 6: Commit

```bash
git add lib/pages/chat/list/
git commit -m "$(cat <<'EOF'
refactor(chat): C6 — split chat_list_screen into focused units

Extracts list_socket_handlers (typing/newMessage/status/read handlers),
list_partner_processing (chat-partner sync), conversation_tile (each
row). Pragmatic guardrail kept extractions that increase complexity
inline. Drops 1,634 → ~900 lines.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task C7 — refactor(chat): extract handlers from `chat_conversation_screen.dart`

**Files:**
- Create: `lib/pages/chat/conversation/handlers/message_action_handlers.dart`
- Create: `lib/pages/chat/conversation/handlers/panel_handlers.dart`
- Create: `lib/pages/chat/conversation/handlers/send_handlers.dart`
- Modify: `lib/pages/chat/conversation/chat_conversation_screen.dart`

### Step 1: Extract message-action handlers

Lines 1422-1674 contain `_handleEditMessage`, `_handleDeleteMessage`, `_handlePinMessage`, `_handleForwardMessage`, `_handleRetryMessage`, `_handleDeleteFailedMessage`, `_handleCallError`. Extract to free functions:

```dart
// lib/pages/chat/conversation/handlers/message_action_handlers.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/providers/provider_root/message_provider.dart';
import 'package:bananatalk_app/pages/chat/widgets/chat_snackbar.dart';
import 'package:bananatalk_app/pages/chat/dialogs/delete_message_dialog.dart';
import 'package:bananatalk_app/pages/chat/dialogs/forward_message_dialog.dart';
import 'package:bananatalk_app/pages/chat/conversation/edit_message_dialog.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

Future<void> handleEditMessage({
  required BuildContext context,
  required WidgetRef ref,
  required Message message,
}) async {
  // Body of _handleEditMessage (lines 1422-1476)
}

Future<void> handleDeleteMessage({
  required BuildContext context,
  required WidgetRef ref,
  required Message message,
}) async {
  // Body of _handleDeleteMessage (lines 1477-1520)
}

Future<void> handlePinMessage({
  required BuildContext context,
  required WidgetRef ref,
  required Message message,
}) async {
  // Body of _handlePinMessage (lines 1521-1557)
}

Future<void> handleForwardMessage({
  required BuildContext context,
  required WidgetRef ref,
  required Message message,
}) async {
  // Body of _handleForwardMessage (lines 1558-1630)
}

Future<void> handleRetryMessage({
  required BuildContext context,
  required WidgetRef ref,
  required Message message,
}) async {
  // Body of _handleRetryMessage (lines 1631-1653)
}

void handleDeleteFailedMessage({
  required BuildContext context,
  required WidgetRef ref,
  required Message message,
}) {
  // Body of _handleDeleteFailedMessage (lines 1654-1673)
}

void handleCallError({
  required BuildContext context,
  required String error,
}) {
  // Body of _handleCallError (lines 1674-1705)
}
```

In `chat_conversation_screen.dart`, find every call to `_handleEditMessage(message)` etc. and replace with `handleEditMessage(context: context, ref: ref, message: message)`. Delete the now-unused private methods.

### Step 2: Extract panel handlers

Lines 534-590 (`_toggleMediaPanel`, `_toggleStickerPanel`, `_hidePanels`) deal with showing/hiding panels. They mutate `_showMediaPanel`/`_showStickerPanel` State fields and call `setState`. Extract:

```dart
// lib/pages/chat/conversation/handlers/panel_handlers.dart
import 'package:flutter/material.dart';

class PanelState {
  bool showMedia;
  bool showSticker;
  PanelState({this.showMedia = false, this.showSticker = false});
}

void togglePanelMedia({
  required PanelState panels,
  required void Function(VoidCallback) setState,
  required FocusNode? composerFocus,
}) {
  setState(() {
    panels.showMedia = !panels.showMedia;
    if (panels.showMedia) panels.showSticker = false;
  });
  if (panels.showMedia) composerFocus?.unfocus();
}

void togglePanelSticker({
  required PanelState panels,
  required void Function(VoidCallback) setState,
  required FocusNode? composerFocus,
}) {
  setState(() {
    panels.showSticker = !panels.showSticker;
    if (panels.showSticker) panels.showMedia = false;
  });
  if (panels.showSticker) composerFocus?.unfocus();
}

void hidePanels({
  required PanelState panels,
  required void Function(VoidCallback) setState,
}) {
  setState(() {
    panels.showMedia = false;
    panels.showSticker = false;
  });
}
```

In `chat_conversation_screen.dart`, replace local `_showMediaPanel` / `_showStickerPanel` bools with a `PanelState _panels = PanelState();`. Replace method calls with the new free functions.

### Step 3: Extract send handlers

Lines 758-830 contain `_showSendError` + `_selectSticker`. Lines ~1882 has `_sendWaveSticker`. Extract to:

```dart
// lib/pages/chat/conversation/handlers/send_handlers.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/pages/chat/widgets/chat_snackbar.dart';

void showSendError(BuildContext context, String error, {VoidCallback? onRetry}) {
  // Body of _showSendError (line 758)
}

Future<void> selectAndSendSticker({
  required BuildContext context,
  required WidgetRef ref,
  required String sticker,
  required String chatPartnerId,
  required String currentUserId,
}) async {
  // Body of _selectSticker (line 806)
}

Future<void> sendWaveSticker({
  required BuildContext context,
  required WidgetRef ref,
  required String chatPartnerId,
  required String currentUserId,
}) async {
  // Body of _sendWaveSticker (line 1882)
}
```

Replace call sites in `chat_conversation_screen.dart`. Delete the now-unused private methods.

### Step 4: Verify

```bash
flutter analyze lib/pages/chat/conversation/ 2>&1 | tail -10
wc -l lib/pages/chat/conversation/chat_conversation_screen.dart lib/pages/chat/conversation/handlers/*.dart
```

Expected: zero errors. Orchestrator drops by ~500-700 lines.

### Step 5: Commit

```bash
git add lib/pages/chat/conversation/
git commit -m "$(cat <<'EOF'
refactor(chat): C7 — extract handlers from chat_conversation_screen

Pulls message_action_handlers (edit/delete/pin/forward/retry/deleteFailed/
callError), panel_handlers (toggle/hide media+sticker panels), send_handlers
(showSendError/selectSticker/sendWaveSticker) into conversation/handlers/.
Drops chat_conversation_screen.dart ~500 lines.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task C8 — refactor(chat): extract sections from `chat_conversation_screen.dart`

**Files:**
- Create: `lib/pages/chat/conversation/sections/conversation_lifecycle_mixin.dart`
- Create: `lib/pages/chat/conversation/sections/conversation_scroll_helpers.dart`
- Create: `lib/pages/chat/conversation/sections/conversation_setup.dart`
- Modify: `lib/pages/chat/conversation/chat_conversation_screen.dart`

### Step 1: Extract scroll helpers

Lines 168-247 (`_setupScrollListener`, `_scrollToBottom`, `_scrollToMessage`). These need access to `_scrollController` from State. Extract as a mixin OR as free functions taking the controller:

```dart
// lib/pages/chat/conversation/sections/conversation_scroll_helpers.dart
import 'package:flutter/material.dart';

void setupScrollListener({
  required ScrollController controller,
  required void Function() onLoadMore,
  required void Function(bool atBottom) onScrolledNearBottom,
}) {
  controller.addListener(() {
    final pos = controller.position;
    // Body of _setupScrollListener (lines 168-189)
  });
}

void scrollToBottom({
  required ScrollController controller,
  bool animated = true,
}) {
  // Body of _scrollToBottom (lines 190-207)
}

void scrollToMessage({
  required ScrollController controller,
  required String messageId,
  required Map<String, GlobalKey> messageKeys,
}) {
  // Body of _scrollToMessage (lines 208-247)
}
```

In `chat_conversation_screen.dart`, replace the private methods with these free function calls.

### Step 2: Extract setup helpers

Lines 249-527 (`_initializeAnimations`, `_setupThemeChangeListener`, `_setupCallListeners`). These wire up animations + listeners. Extract:

```dart
// lib/pages/chat/conversation/sections/conversation_setup.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConversationAnimations {
  late AnimationController panelAnim;
  late AnimationController fadeAnim;
  // (whatever animation controllers are needed)

  void init(TickerProvider vsync) {
    // Body of _initializeAnimations (lines 249-491)
  }

  void dispose() {
    panelAnim.dispose();
    fadeAnim.dispose();
  }
}

void setupThemeChangeListener(BuildContext context, VoidCallback onThemeChanged) {
  // Body of _setupThemeChangeListener (lines 492-513)
}

void setupCallListeners({
  required WidgetRef ref,
  required void Function(String error) onCallError,
}) {
  // Body of _setupCallListeners (lines 514-527)
}
```

### Step 3: Extract lifecycle mixin

Wrap initState/didChangeAppLifecycleState/didChangeMetrics into a mixin so the State class becomes thinner:

```dart
// lib/pages/chat/conversation/sections/conversation_lifecycle_mixin.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

mixin ConversationLifecycleMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T>, WidgetsBindingObserver {

  void onAppLifecycleResumed();
  void onAppLifecycleInactive();
  void onWindowMetricsChanged();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Body of _ChatScreenState.didChangeAppLifecycleState (lines 139-150)
    if (state == AppLifecycleState.resumed) onAppLifecycleResumed();
    if (state == AppLifecycleState.inactive) onAppLifecycleInactive();
  }

  @override
  void didChangeMetrics() {
    onWindowMetricsChanged();
  }
}
```

In `chat_conversation_screen.dart`, change the State class to `with WidgetsBindingObserver, ConversationLifecycleMixin<ChatScreen>` and provide the 3 abstract methods (which contain the body that USED to be in `didChangeAppLifecycleState` and `didChangeMetrics`).

### Step 4: Pragmatic guardrail

If the mixin pattern fights with Flutter's `with` chain (e.g., conflicts with `TickerProviderStateMixin`), keep the lifecycle methods inline and only extract scroll + setup. Document in commit.

### Step 5: Verify

```bash
flutter analyze lib/pages/chat/ 2>&1 | tail -10
wc -l lib/pages/chat/conversation/chat_conversation_screen.dart
```

Expected: zero errors. Orchestrator ≤ ~700 lines (was ~1,300 after C7).

### Step 6: Commit

```bash
git add lib/pages/chat/conversation/
git commit -m "$(cat <<'EOF'
refactor(chat): C8 — extract sections from chat_conversation_screen

Extracts conversation_scroll_helpers (scroll listener + scroll-to-bottom/
message), conversation_setup (animations + theme + call listeners),
conversation_lifecycle_mixin (app lifecycle + window metrics callbacks).
Pragmatic guardrail applied where extraction conflicts with mixin chains.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task C9 — feat(chat) + backend: voice message transcription (G)

**Files:**
- Modify: `lib/pages/chat/message/message_bubble/voice_message_view.dart` (add transcribe button + render)
- Modify: `lib/services/voice_message_service.dart` (add `transcribeMessage` method)
- Modify: `/Users/davis/Desktop/Personal/language_exchange_backend_application/controllers/speech.js` (verify URL-based transcribe variant exists)
- Modify: `lib/providers/provider_models/message_model.dart` (add `transcription: String?` to `MessageMedia`)

### Step 1: Verify backend `transcribeAudio` accepts URL

```bash
grep -A 30 "exports.transcribeAudio" /Users/davis/Desktop/Personal/language_exchange_backend_application/controllers/speech.js
```

Read the controller. The endpoint likely takes either an audio file upload OR an audio URL. Identify which.

If only file-upload, add a URL variant:

```javascript
// /Users/davis/Desktop/Personal/language_exchange_backend_application/controllers/speech.js
exports.transcribeFromUrl = asyncHandler(async (req, res, next) => {
  const { audioUrl, language } = req.body;
  if (!audioUrl) return next(new ErrorResponse('audioUrl required', 400));

  // Download audio from URL → pass to existing STT pipeline → return text
  const transcript = await speechService.transcribeFromUrl(audioUrl, { language });
  res.status(200).json({ success: true, data: { transcript } });
});
```

Wire route in `routes/speech.js`:

```javascript
router.post('/transcribe-url', protect, transcribeFromUrl);
```

### Step 2: Add Flutter service method

In `lib/services/voice_message_service.dart`:

```dart
Future<String?> transcribeMessage({
  required String audioUrl,
  String? languageHint,
}) async {
  try {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/speech/transcribe-url'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await _getToken()}',
      },
      body: jsonEncode({'audioUrl': audioUrl, 'language': languageHint}),
    );
    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body);
    return data['data']['transcript'] as String?;
  } catch (e) {
    debugPrint('Transcribe error: $e');
    return null;
  }
}
```

### Step 3: Add transcribe button + render in `voice_message_view.dart`

Add state for transcription:

```dart
class _VoiceMessageViewState extends State<VoiceMessageView> {
  String? _transcription;
  bool _isTranscribing = false;

  Future<void> _transcribe() async {
    final url = widget.message.media?.url;
    if (url == null) return;
    setState(() => _isTranscribing = true);
    final result = await VoiceMessageService.instance.transcribeMessage(
      audioUrl: url,
      languageHint: widget.message.detectedLanguage,
    );
    if (!mounted) return;
    setState(() {
      _transcription = result;
      _isTranscribing = false;
    });
    if (result == null) {
      showChatSnackBar(
        context,
        message: AppLocalizations.of(context)!.transcriptionFailed,
        type: ChatSnackBarType.error,
      );
    }
  }
}
```

Convert `VoiceMessageView` from `StatelessWidget` to `StatefulWidget` (preserving its public API).

In the build, after the `VoiceMessagePlayer`:

```dart
if (_transcription != null)
  Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(
      _transcription!,
      style: context.bodySmall.copyWith(fontStyle: FontStyle.italic),
    ),
  )
else
  TextButton.icon(
    onPressed: _isTranscribing ? null : _transcribe,
    icon: _isTranscribing
        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
        : const Icon(Icons.text_fields_rounded, size: 16),
    label: Text(_isTranscribing
        ? AppLocalizations.of(context)!.transcribing
        : AppLocalizations.of(context)!.transcribeMessage),
  ),
```

### Step 4: Verify analyzer

```bash
flutter analyze lib/pages/chat/message/ lib/services/voice_message_service.dart 2>&1 | tail -5
```

Expected: zero errors.

### Step 5: Commit Flutter

```bash
git add lib/
git commit -m "$(cat <<'EOF'
feat(chat): C9 — voice message transcription on demand

Adds 'Transcribe' button below voice message player. Hits new
/speech/transcribe-url backend endpoint. Renders inline italic text
on success; shows transcriptionFailed snackbar on error.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

### Step 6: Commit backend (if changes were made)

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
git status
# If transcribeFromUrl was added:
git add controllers/speech.js routes/speech.js services/speechService.js
git commit -m "$(cat <<'EOF'
feat(speech): add /speech/transcribe-url for chat voice transcription

Accepts {audioUrl, language?} and returns transcript text. Flutter
chat voice messages call this on user-tap to convert speech to text.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
```

If the existing `transcribeAudio` already accepts URLs, skip step 6 (no backend changes).

---

## Task C10 — feat(chat): save-to-vocabulary from message (H)

**Files:**
- Create: `lib/pages/chat/message/bubble/word_long_press_handler.dart`
- Modify: `lib/pages/chat/message/bubble/text_bubble.dart` (wrap text)
- Modify: `lib/services/learning_service.dart` (add `saveVocabularyWord` if missing)

### Step 1: Verify backend endpoint shape

```bash
grep -A 25 "exports.addVocabulary" /Users/davis/Desktop/Personal/language_exchange_backend_application/controllers/learning.js
```

Read the controller to confirm the request body it accepts. Likely: `{ word, translation, language, nativeLanguage, partOfSpeech?, exampleSentence? }`.

### Step 2: Add Flutter service method

Open `lib/services/learning_service.dart`. If `saveVocabularyWord` doesn't exist, add:

```dart
Future<bool> saveVocabularyWord({
  required String word,
  required String translation,
  required String language,
  required String nativeLanguage,
  String? exampleSentence,
}) async {
  try {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/learning/vocabulary'),
      headers: { 'Authorization': 'Bearer ${await _getToken()}', 'Content-Type': 'application/json' },
      body: jsonEncode({
        'word': word,
        'translation': translation,
        'language': language,
        'nativeLanguage': nativeLanguage,
        if (exampleSentence != null) 'exampleSentence': exampleSentence,
      }),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  } catch (e) {
    debugPrint('Vocab save error: $e');
    return false;
  }
}
```

### Step 3: Create word long-press handler widget

```dart
// lib/pages/chat/message/bubble/word_long_press_handler.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/services/learning_service.dart';
import 'package:bananatalk_app/services/translation_service.dart';
import 'package:bananatalk_app/pages/chat/widgets/chat_snackbar.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

class WordLongPressText extends ConsumerStatefulWidget {
  final String text;
  final String? sourceLanguage;
  final TextStyle? style;

  const WordLongPressText({
    super.key,
    required this.text,
    this.sourceLanguage,
    this.style,
  });

  @override
  ConsumerState<WordLongPressText> createState() => _WordLongPressTextState();
}

class _WordLongPressTextState extends ConsumerState<WordLongPressText> {
  final _textKey = GlobalKey();

  String? _hitTestWord(Offset localPosition) {
    final renderObject = _textKey.currentContext?.findRenderObject() as RenderParagraph?;
    if (renderObject == null) return null;
    final pos = renderObject.getPositionForOffset(localPosition);
    final wordRange = renderObject.getWordBoundary(pos);
    final word = widget.text.substring(wordRange.start, wordRange.end).trim();
    if (word.isEmpty || word.length > 50) return null;
    // Strip punctuation
    return word.replaceAll(RegExp(r'[^\w]'), '');
  }

  Future<void> _showSavePopup(String word) async {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.read(authProvider).user;
    if (user == null) return;

    // Fetch translation
    final translation = await TranslationService.instance.translate(
      text: word,
      targetLanguage: user.nativeLanguage,
      sourceLanguage: widget.sourceLanguage,
    );

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.saveToVocabulary(word)),
        content: Text(translation ?? word),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.save)),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await LearningService.instance.saveVocabularyWord(
      word: word,
      translation: translation ?? word,
      language: widget.sourceLanguage ?? 'auto',
      nativeLanguage: user.nativeLanguage,
      exampleSentence: widget.text.length < 200 ? widget.text : null,
    );

    if (!mounted) return;
    showChatSnackBar(
      context,
      message: success ? l10n.addedToVocabulary : l10n.alreadyInVocabulary,
      type: success ? ChatSnackBarType.success : ChatSnackBarType.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (details) async {
        final word = _hitTestWord(details.localPosition);
        if (word != null) await _showSavePopup(word);
      },
      child: Text(widget.text, key: _textKey, style: widget.style),
    );
  }
}
```

### Step 4: Use the new widget in `text_bubble.dart`

Replace the existing `Text(message.message ?? '', ...)` rendering with:

```dart
WordLongPressText(
  text: message.message ?? '',
  sourceLanguage: message.detectedLanguage,
  style: context.bodyMedium.copyWith(color: isMe ? Colors.white : context.textPrimary),
)
```

### Step 5: Verify analyzer

```bash
flutter analyze lib/pages/chat/message/ lib/services/learning_service.dart 2>&1 | tail -5
```

Expected: zero errors.

### Step 6: Commit

```bash
git add lib/
git commit -m "$(cat <<'EOF'
feat(chat): C10 — save-to-vocabulary on long-press word

Long-press any word in a text message → confirms with translation
preview → POSTs to /learning/vocabulary. Uses backend's existing
addVocabulary endpoint with checkVocabularyLimit middleware.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task C11 — feat(chat): auto-translate received toggle (I)

**Files:**
- Create: `lib/pages/chat/header/auto_translate_toggle.dart`
- Modify: `lib/pages/chat/header/chat_app_bar.dart` (add menu item)
- Modify: `lib/pages/chat/message/bubble/text_bubble.dart` (render auto-translation when ON)
- Modify: `lib/services/translation_service.dart` (add per-conversation key helpers)

### Step 1: Add per-conversation key helpers

In `lib/services/translation_service.dart`, add:

```dart
static String _autoTranslateChatKey(String conversationId) =>
    'auto_translate_chat_$conversationId';

Future<bool> isAutoTranslateChatEnabled(String conversationId) async {
  final prefs = await SharedPreferences.getInstance();
  // Check per-conversation override first, then fall back to global setting
  final key = _autoTranslateChatKey(conversationId);
  if (prefs.containsKey(key)) return prefs.getBool(key) ?? false;
  return prefs.getBool('auto_translate_chat') ?? false;
}

Future<void> setAutoTranslateChatForConversation(String conversationId, bool enabled) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_autoTranslateChatKey(conversationId), enabled);
}
```

### Step 2: Create the toggle widget

```dart
// lib/pages/chat/header/auto_translate_toggle.dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/services/translation_service.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

class AutoTranslateMenuItem extends StatefulWidget {
  final String conversationId;
  const AutoTranslateMenuItem({super.key, required this.conversationId});

  @override
  State<AutoTranslateMenuItem> createState() => _AutoTranslateMenuItemState();
}

class _AutoTranslateMenuItemState extends State<AutoTranslateMenuItem> {
  bool? _enabled;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final v = await TranslationService.instance.isAutoTranslateChatEnabled(widget.conversationId);
    if (!mounted) return;
    setState(() => _enabled = v);
  }

  Future<void> _toggle(bool v) async {
    setState(() => _enabled = v);
    await TranslationService.instance.setAutoTranslateChatForConversation(widget.conversationId, v);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      title: Text(l10n.autoTranslate),
      subtitle: Text(l10n.autoTranslateChatHint),
      value: _enabled ?? false,
      onChanged: _enabled == null ? null : _toggle,
    );
  }
}
```

### Step 3: Wire menu item into chat_app_bar.dart

Find the app bar's overflow menu (likely `PopupMenuButton<String>`). Add an entry that opens a bottom sheet with the toggle:

```dart
// In chat_app_bar.dart's PopupMenu items:
PopupMenuItem(
  value: 'auto-translate',
  child: Row(
    children: [
      const Icon(Icons.translate_rounded, size: 20),
      const SizedBox(width: 12),
      Text(AppLocalizations.of(context)!.autoTranslate),
    ],
  ),
),

// In onSelected:
case 'auto-translate':
  showModalBottomSheet(
    context: context,
    builder: (_) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: AutoTranslateMenuItem(conversationId: widget.conversationId),
    ),
  );
  break;
```

### Step 4: Render auto-translation inline in text_bubble.dart

Modify `TextBubble` to optionally fetch + render translated text:

```dart
class TextBubble extends ConsumerStatefulWidget {
  final Message message;
  final bool isMe;
  final String conversationId;
  // ...
}

class _TextBubbleState extends ConsumerState<TextBubble> {
  String? _autoTranslation;
  bool _checkedAutoTranslate = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isMe) _maybeAutoTranslate();
  }

  Future<void> _maybeAutoTranslate() async {
    final on = await TranslationService.instance.isAutoTranslateChatEnabled(widget.conversationId);
    if (!mounted) return;
    setState(() => _checkedAutoTranslate = true);
    if (!on) return;
    final translated = await TranslationService.instance.translate(
      text: widget.message.message ?? '',
      targetLanguage: ref.read(authProvider).user?.nativeLanguage ?? 'en',
      sourceLanguage: widget.message.detectedLanguage,
    );
    if (!mounted) return;
    setState(() => _autoTranslation = translated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WordLongPressText(text: widget.message.message ?? '', /* ... */),
        if (_autoTranslation != null && _autoTranslation != widget.message.message)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _autoTranslation!,
              style: context.bodySmall.copyWith(
                fontStyle: FontStyle.italic,
                color: widget.isMe ? Colors.white70 : context.textSecondary,
              ),
            ),
          ),
      ],
    );
  }
}
```

### Step 5: Verify analyzer

```bash
flutter analyze lib/pages/chat/ lib/services/translation_service.dart 2>&1 | tail -5
```

Expected: zero errors.

### Step 6: Commit

```bash
git add lib/
git commit -m "$(cat <<'EOF'
feat(chat): C11 — per-conversation auto-translate toggle

Adds 'Auto-translate' switch in chat app-bar menu (opens bottom sheet).
State persists per-conversation in SharedPreferences. When ON, incoming
text bubbles auto-translate inline below the original. Reuses
TranslationService and existing autoTranslate l10n keys.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task C12 — feat(chat): wire save-to-vocab into bubble actions menu

**Files:**
- Modify: `lib/pages/chat/message/bubble/bubble_actions_menu.dart`

### Step 1: Add a "Save to vocabulary" menu item

In `showBubbleContextMenu` (created in C5), add an option:

```dart
ListTile(
  leading: const Icon(Icons.bookmark_add_outlined),
  title: Text(AppLocalizations.of(context)!.saveToVocabulary(/* whole message preview */)),
  enabled: message.type == 'text' && (message.message?.isNotEmpty ?? false),
  onTap: () {
    Navigator.pop(context);
    onSaveToVocab?.call();
  },
),
```

In `message_bubble.dart`, the call site for `showBubbleContextMenu` now needs to provide `onSaveToVocab`:

```dart
showBubbleContextMenu(
  context: context,
  ref: ref,
  message: widget.message,
  isMe: isMe,
  onReply: () => widget.onReply?.call(widget.message),
  onEdit: () => widget.onEdit?.call(widget.message),
  // ... etc
  onSaveToVocab: widget.message.type == 'text' && (widget.message.message?.isNotEmpty ?? false)
      ? () async {
          // Open the same long-press dialog from C10 but for the whole message
          // OR navigate to a "save phrase" dialog if message is long
          final user = ref.read(authProvider).user;
          if (user == null) return;
          final success = await LearningService.instance.saveVocabularyWord(
            word: widget.message.message!,
            translation: '', // user fills in
            language: widget.message.detectedLanguage ?? 'auto',
            nativeLanguage: user.nativeLanguage,
          );
          // toast ...
        }
      : null,
);
```

(Trim down to a manageable phrase if message > 100 chars — just take the first 50 words.)

### Step 2: Verify + commit

```bash
flutter analyze lib/pages/chat/message/ 2>&1 | tail -5
git add lib/pages/chat/message/
git commit -m "$(cat <<'EOF'
feat(chat): C12 — wire save-to-vocab into bubble context menu

Adds 'Save to vocabulary' to the long-press menu (alongside reply/
react/translate/etc.). Reuses LearningService.saveVocabularyWord
from C10. Disabled for non-text messages.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task C13 — feat(chat): Material 3 bubble redesign + animations (L)

**Files:**
- Modify: `lib/pages/chat/message/bubble/bubble_container.dart` (refine M3 shape/shadow)
- Modify: `lib/pages/chat/message/message_bubble.dart` (add slide-in animation)
- Modify: `lib/pages/chat/list/conversation_tile.dart` (rounded M3 card style)
- Modify: `lib/pages/chat/header/chat_app_bar.dart` (transparent on scroll, M3 large title)

### Step 1: Refine bubble_container

```dart
// lib/pages/chat/message/bubble/bubble_container.dart
class BubbleContainer extends StatelessWidget {
  // ... existing fields

  @override
  Widget build(BuildContext context) {
    final bg = isMe ? AppColors.primary : context.containerColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(isMe ? 20 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 20),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: child,
    );
  }
}
```

### Step 2: Add message slide-in animation in message_bubble.dart

Wrap the bubble in a `TweenAnimationBuilder` for first-render slide-in:

```dart
// in build()
return TweenAnimationBuilder<double>(
  tween: Tween(begin: 0, end: 1),
  duration: const Duration(milliseconds: 240),
  curve: Curves.easeOutCubic,
  builder: (context, value, child) => Transform.translate(
    offset: Offset(isMe ? (1 - value) * 16 : (1 - value) * -16, 0),
    child: Opacity(opacity: value, child: child),
  ),
  child: /* existing bubble layout */,
);
```

### Step 3: Round the conversation tile

In `conversation_tile.dart`:

```dart
return Material(
  color: Colors.transparent,
  child: InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: /* row with avatar + name + last message + unread badge */,
    ),
  ),
);
```

(Wrap in `Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4))` if row spacing needs it — match Material 3 list spacing.)

### Step 4: Modernize app bar

In `chat_app_bar.dart`, ensure the AppBar uses M3 large title style (or a custom large header that scrolls under the bar):

```dart
AppBar(
  surfaceTintColor: Colors.transparent,
  elevation: 0,
  scrolledUnderElevation: 1,  // M3 polish — subtle shadow only after scroll
  backgroundColor: context.surfaceColor,
  // ... existing title/actions
)
```

### Step 5: Verify analyzer

```bash
flutter analyze lib/pages/chat/ 2>&1 | tail -10
```

Expected: zero errors.

### Step 6: Commit

```bash
git add lib/pages/chat/
git commit -m "$(cat <<'EOF'
feat(chat): C13 — Material 3 bubble redesign + slide-in animation

- bubble_container: M3 asymmetric border-radius (20/20/4 for sender),
  subtle elevation shadow (light mode only)
- message_bubble: 240ms slide-in + fade on first render
- conversation_tile: Material 3 InkWell with rounded ripple
- chat_app_bar: scrolledUnderElevation polish, transparent surfaceTint

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task C14 — chore(chat): final analyzer + push + PR

**Files:** any leftover

### Step 1: Run full analyzer

```bash
flutter analyze 2>&1 | tail -30
```

Expected: zero errors. Address any new warnings in `lib/pages/chat/` with targeted edits.

### Step 2: Run gen-l10n once more

```bash
flutter pub get
flutter gen-l10n
```

Expected: no errors.

### Step 3: Manual smoke (full path)

Run `flutter run`:

1. Open chat list → tabs/refresh works
2. Open a conversation → header renders, messages scroll
3. Send a text message → slides in
4. Long-press a word → "Save '<word>' to vocabulary" dialog → save → snackbar
5. Long-press an entire message → context menu shows reply/react/translate/save-to-vocab
6. Toggle auto-translate via app-bar menu → ON → next received message renders with italic translation below
7. Voice message → tap "Transcribe" → spinner → text appears
8. Swipe-to-reply still works (was already shipped, regression check)
9. Edit/pin/forward/delete handlers still fire (regression after C7)
10. Open chat from a notification → goes to right conversation (regression after C6)
11. M3 bubble shape — verify visually in light + dark themes

### Step 4: Verify diff size

```bash
git log main..HEAD --oneline | wc -l
git diff main..HEAD --stat | tail -3
```

Expected: 14-16 commits. Files changed in `lib/pages/chat/`, `lib/l10n/`, possibly `lib/services/`, possibly backend `controllers/speech.js`.

### Step 5: Push the branch

```bash
git push -u origin refactor/step6-chat-restructure
```

### Step 6: Push the backend (if C9 touched it)

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
git status
git push  # only if there are commits to push
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
```

### Step 7: Create the PR

```bash
gh pr create --title "Step 6 — Chat restructure + 4 modern features" --body "$(cat <<'EOF'
## Summary
- Split 3 chat monoliths: `chat_conversation_screen` (1,996 → ~700), `chat_list_screen` (1,634 → ~900), `message_bubble` (1,048 → ~700)
- New `conversation/handlers/` (message-action / panel / send), `conversation/sections/` (lifecycle mixin / scroll / setup), `message/bubble/` (container / text / system / actions menu / word long-press), `list/` extractions (socket handlers / partner processing / tile)
- 4 features: voice transcription (G), save-to-vocabulary on long-press word (H), per-conversation auto-translate toggle (I), Material 3 bubble redesign + slide-in animation (L)
- 1 backend addition: `/speech/transcribe-url` endpoint (if existing `transcribeAudio` was file-only)
- Cleanup: 6 routine debugPrints removed, 5 `Colors.grey[*]` → theme getters, 1 inline snackbar → `showChatSnackBar`
- 10 new ARB keys × 18 locales

## Spec corrections discovered during execution
- Swipe-to-reply (Feature E) was already shipped at lines 153-205 of message_bubble.dart — dropped from scope
- `chat/widgets/` scaffolding was 3/4 already shipped — only added missing `chat_error_state.dart` for parity
- `translation_service.dart` already has `auto_translate_<contentType>` SharedPreferences plumbing — Feature I was UI-only hookup
- Backend `addVocabulary` route + `Vocabulary` SRS model already shipped — Feature H was Flutter-only

## Test plan
- [ ] `flutter analyze` clean
- [ ] Chat list opens, refreshes, deep-link to conversation works
- [ ] Conversation: send text + voice + image, edit/pin/forward/delete still works
- [ ] Long-press word → save to vocab → check `Vocabulary` collection in DB
- [ ] Auto-translate toggle ON → received foreign-language messages render translation inline
- [ ] Voice transcription button on voice messages → result appears
- [ ] Swipe-to-reply still functions (regression — was already shipped)
- [ ] Reactions still functional (regression)
- [ ] Material 3 bubble shape renders correctly in light + dark theme
- [ ] No regressions on cross-folder importers (chat → moments image_viewer, etc.)

## Out of scope (future)
- Group chat support
- Calling rebuild on third-party SDK (Step 6a — next wave)
- AI grammar suggestion in input (Feature J)
- AI smart replies (Feature K)
- Scheduled messages
- Message threading view
- Disappearing messages

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

### Step 8: Report PR URL

Surface the URL to the user as the final progress report.

---

## Summary

14 commits (C0-C14, with C0 being a no-op deps audit if everything is present). Restructure-heavy with bundled cleanup + 4 modernization-leaning features. Mirrors the cadence of Step 5 (moments) and Step 1 (community wave-1).

**Total Flutter files touched:** ~25-30 (most are new files for the splits; ~4-5 service files modified for features)
**Total backend files touched:** 0-3 (only if `transcribeAudio` needs URL variant)
**Total ARB strings added:** 10 × 18 locales = 180 string additions

## Test plan

- `flutter analyze` clean per commit
- `flutter pub get` + `flutter gen-l10n` clean at C14
- Manual smoke per C14 step 3 (full chat happy path + new features + regression checks for swipe/reactions/edit handlers)
- Backend tests run only if C9 touches speech controller

## Plan complete

Plan saved to `docs/superpowers/plans/2026-05-10-step6-chat-restructure.md`. Per user authorization ("do it automatic u don't need to ask me for confirmation for any task u do, I'm busy, u handle it"), proceeding directly to Subagent-Driven execution.

## Self-review notes (post-write)

**Spec coverage check:**
- Restructure of 3 monoliths → C5 (bubble), C6 (list), C7+C8 (conversation handlers + sections). ✅
- Cleanup sweep → C1. ✅
- chat/widgets/ scaffolding → C4 (parity only, since 3/4 already exist). ✅
- l10n → C2, C3. ✅
- E swipe-to-reply → SKIPPED (already shipped — documented in spec corrections). ✅
- G voice transcription → C9. ✅
- H save-to-vocab → C10 (long-press word) + C12 (menu wire-up). ✅
- I auto-translate → C11. ✅
- L M3 redesign → C13. ✅
- Final analyzer + push + PR → C14. ✅

**Placeholder scan:** No "TBD", "TODO", or generic "implement appropriate" patterns. Several "Body of _xxx (lines NNN-MMM)" references — those point to actual existing methods the implementer reads directly. Acceptable. ✅

**Type consistency:**
- `ChatSnackBarType` enum used identically in C1, C9, C10, C11. ✅
- `showBubbleContextMenu` defined in C5 step 2, consumed in C12. ✅
- `WordLongPressText` defined in C10, used in C11's text_bubble. ✅
- `TranslationService.isAutoTranslateChatEnabled` defined in C11 step 1, used in C11 step 4. ✅
- `LearningService.saveVocabularyWord` defined in C10 step 2, used in C10 step 3 + C12. ✅

No issues. Plan ready for execution.
