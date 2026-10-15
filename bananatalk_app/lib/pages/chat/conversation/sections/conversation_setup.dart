// lib/pages/chat/conversation/sections/conversation_setup.dart
//
// Free-function equivalents of setup helpers that lived in _ChatScreenState.
//
// _initializeAnimations is kept inline because it requires vsync: this
// (the State itself as a TickerProvider) and mutates late AnimationController
// fields — it cannot be extracted without passing the whole State.
//
// _setupThemeChangeListener is kept inline because it assigns to
// _themeChangeSubscription and closes over widget.userId, setState, and
// mounted — too many mutable State fields for a clean extraction.

import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// setupCallListeners
// ---------------------------------------------------------------------------

/// Used to register the chat screen as the call-error handler, overwriting
/// the previous one and never clearing it: errors of calls accepted outside
/// a chat went to a disposed screen and were never shown. In-call errors now
/// have one app-level presenter (`CallLauncher.showCallErrorOnOverlay`,
/// registered in main.dart), so a chat screen no longer takes them over.
/// Kept as a no-op until the chat screen drops its call.
void setupCallListeners({
  required WidgetRef ref,
  required void Function(String error) onCallError,
}) {}
