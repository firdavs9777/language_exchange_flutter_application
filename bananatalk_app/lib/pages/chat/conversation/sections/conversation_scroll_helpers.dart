// lib/pages/chat/conversation/sections/conversation_scroll_helpers.dart
//
// Free-function equivalents of the private scroll helper that lived in
// _ChatScreenState.  Extracted so call sites in the orchestrator stay
// clean without needing to pass them through the entire State class.
//
// _setupScrollListener and _scrollToMessage are kept inline in the
// orchestrator because they close over too many State fields
// (_isLoadingMore, _hasMoreMessages, _showScrollButton, _highlightedMessageId,
// ref, widget, setState, mounted) to extract cleanly.

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// scrollToBottom
// ---------------------------------------------------------------------------

/// Scrolls [controller] to the bottom (newest messages).
///
/// Pass [animated] = false for instant jumps (e.g. on initial load or
/// keyboard open) and true (the default) for smooth user-triggered scrolls.
Future<void> scrollToBottom({
  required ScrollController controller,
  bool animated = true,
}) async {
  if (!controller.hasClients) return;

  final targetPosition = controller.position.maxScrollExtent;

  if (animated && targetPosition > 0) {
    await controller.animateTo(
      targetPosition,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  } else {
    controller.jumpTo(targetPosition);
  }
}
