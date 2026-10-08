import 'package:flutter/material.dart';

import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/router/app_router.dart';
import 'package:bananatalk_app/screens/active_call_screen.dart';
import 'package:bananatalk_app/screens/incoming_call_screen.dart';

/// Call screens live on the overlay navigator under fixed route names, so
/// CallManager can close exactly them — and nothing else — from anywhere.
class CallRoutes {
  const CallRoutes._();

  static const incoming = 'call/incoming';
  static const active = 'call/active';

  static bool isCallRoute(String? name) => name == incoming || name == active;

  static Route<void> incomingRoute(CallModel call) => MaterialPageRoute<void>(
        settings: const RouteSettings(name: incoming),
        fullscreenDialog: true,
        builder: (_) => IncomingCallScreen(call: call),
      );

  static Route<void> activeRoute(CallModel call) => MaterialPageRoute<void>(
        settings: const RouteSettings(name: active),
        fullscreenDialog: true,
        builder: (_) => ActiveCallScreen(call: call),
      );

  static void openIncoming(CallModel call) =>
      callOverlayNavigatorKey.currentState?.push(incomingRoute(call));

  static void openActive(CallModel call) =>
      callOverlayNavigatorKey.currentState?.push(activeRoute(call));

  static void closeAll() => callOverlayNavigatorKey.currentState
      ?.popUntil((route) => !isCallRoute(route.settings.name));
}
