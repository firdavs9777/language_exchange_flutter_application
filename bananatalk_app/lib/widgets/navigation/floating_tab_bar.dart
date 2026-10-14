import 'package:flutter/widgets.dart';

class FloatingTabBar {
  static const double height = 56;
  static const double _gapNoInset = 8;
  static const double _breathing = 12;

  /// Space a tab page must leave at its bottom so content scrolls clear of
  /// the floating bar (spec §8.2). Mirrors the bar's own positioning.
  static double clearance(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).bottom;
    final gap = inset > 0 ? inset - 4 : _gapNoInset;
    return gap + height + _breathing;
  }
}
