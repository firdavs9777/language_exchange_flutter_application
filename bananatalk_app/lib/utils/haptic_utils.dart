// lib/utils/haptic_utils.dart
import 'package:flutter/services.dart';

/// Centralized haptic feedback utility for consistent UX across the app
class HapticUtils {
  HapticUtils._();

  /// Light impact for small interactions (button taps, toggles)
  static void lightImpact() {
    HapticFeedback.lightImpact();
  }

  /// Medium impact for confirmations (save, send, complete)
  static void mediumImpact() {
    HapticFeedback.mediumImpact();
  }

  /// Heavy impact for important actions (delete, error)
  static void heavyImpact() {
    HapticFeedback.heavyImpact();
  }

  /// Selection click for navigation and list selections
  static void selectionClick() {
    HapticFeedback.selectionClick();
  }

  /// Vibrate for alerts and notifications (use sparingly)
  static void vibrate() {
    HapticFeedback.vibrate();
  }

  // Common use cases with semantic naming

  /// For like/heart button taps
  static void onLike() {
    HapticFeedback.lightImpact();
  }

  /// For message send
  static void onMessageSend() {
    HapticFeedback.selectionClick();
  }

  /// For successful action completion
  static void onSuccess() {
    HapticFeedback.mediumImpact();
  }

  /// For error or failed action
  static void onError() {
    HapticFeedback.heavyImpact();
  }

  /// For pull-to-refresh trigger
  static void onRefresh() {
    HapticFeedback.lightImpact();
  }

  /// For long press context menu
  static void onLongPress() {
    HapticFeedback.mediumImpact();
  }

  /// For item selection in list
  static void onSelect() {
    HapticFeedback.selectionClick();
  }

  /// For navigation/tab change
  static void onNavigate() {
    HapticFeedback.selectionClick();
  }

  /// For bookmark/save action
  static void onSave() {
    HapticFeedback.mediumImpact();
  }

  /// For delete action
  static void onDelete() {
    HapticFeedback.heavyImpact();
  }
}
