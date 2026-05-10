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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/call_provider.dart';

// ---------------------------------------------------------------------------
// setupCallListeners
// ---------------------------------------------------------------------------

/// Registers the call-error callback on [CallNotifier] in a post-frame
/// callback so it is safe to call from initState.
///
/// [onCallError] is invoked (with the error string) whenever the call
/// provider encounters an error.
void setupCallListeners({
  required WidgetRef ref,
  required void Function(String error) onCallError,
}) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final callNotifier = ref.read(callProvider.notifier);
    // Incoming call callback is set globally in main.dart; only the error
    // callback is wired here so the screen can surface it locally.
    callNotifier.setCallErrorCallback(onCallError);
  });
}
