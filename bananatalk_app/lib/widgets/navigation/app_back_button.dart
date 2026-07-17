import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Guaranteed return-path back button for screens that can be reached via a
/// push notification deep-link.
///
/// Background: [NotificationRouter.handleNotification] (in
/// lib/services/notification_router.dart) opens a deep-linked screen by
/// doing `goRouter.go('/home')` followed by a delayed `goRouter.push(...)`.
/// Depending on the launch path (especially cold-start from a terminated
/// app, where GoRouter's `initialLocation` is `/splash`), that sequence
/// doesn't reliably leave a poppable back stack behind. Screens that rely on
/// Flutter's *automatic* AppBar back arrow (`automaticallyImplyLeading`)
/// only render an arrow when `canPop()` is true at build time — so on some
/// notification-tap paths, no arrow appears at all and the user is stuck
/// with no way back.
///
/// [AppBackButton] sidesteps that timing dependency entirely: it always
/// renders a visible arrow, and on tap it pops if there's something to pop,
/// otherwise it falls back to `/home`. There is always a safe action.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.color, this.onOverride});

  /// Icon color. Defaults to the theme's primary text color.
  final Color? color;

  /// Optional override for the tap handler. When provided, this runs
  /// instead of the default pop-or-go-home behavior.
  final VoidCallback? onOverride;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back, color: color ?? context.textPrimary),
      onPressed: onOverride ??
          () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
    );
  }
}
