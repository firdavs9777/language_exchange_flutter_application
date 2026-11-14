import 'package:flutter/material.dart';

import 'package:bananatalk_app/pages/coins/coin_shop_screen.dart';
import 'package:bananatalk_app/pages/vip/vip_plans_screen.dart';
import 'package:bananatalk_app/services/paywall/paywall_flow.dart';
import 'package:bananatalk_app/services/paywall/paywall_tracker.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';

/// Which route class a call site used before it moved to these helpers.
enum PaywallRoute { material, app }

Route<T> _route<T>(PaywallRoute route, WidgetBuilder builder) =>
    route == PaywallRoute.app
    ? AppPageRoute<T>(builder: builder)
    : MaterialPageRoute<T>(builder: builder);

/// The one way to open the VIP plans screen. Logs `cta_vip` on [flow], then
/// pushes. Pass [navigator] when the site captured one before an await or
/// uses a root / keyed navigator; otherwise `Navigator.of(context)`.
Future<T?> openVipPlans<T>(
  BuildContext context,
  PaywallFlow flow, {
  String? userId,
  PaywallRoute route = PaywallRoute.material,
  bool logCta = true,
  NavigatorState? navigator,
}) {
  final nav = navigator ?? Navigator.of(context);
  if (logCta) paywallLog(flow, PaywallAction.ctaVip);
  return nav.push<T>(
    _route<T>(route, (_) => VipPlansScreen(userId: userId, flow: flow)),
  );
}

/// The one way to open the coin shop. Logs `cta_coins` on [flow], then pushes.
Future<T?> openCoinShop<T>(
  BuildContext context,
  PaywallFlow flow, {
  PaywallRoute route = PaywallRoute.material,
  bool logCta = true,
  NavigatorState? navigator,
}) {
  final nav = navigator ?? Navigator.of(context);
  if (logCta) paywallLog(flow, PaywallAction.ctaCoins);
  return nav.push<T>(_route<T>(route, (_) => CoinShopScreen(flow: flow)));
}
