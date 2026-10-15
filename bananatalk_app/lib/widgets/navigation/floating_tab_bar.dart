import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Decides whether the floating tab bar shows, from the primary vertical
/// scroll of the visible tab (spec §8.2). Pure, so it is unit-tested.
///
/// Downward scrolling past [hideAfter] hides the bar; any upward scroll,
/// reaching the top, or reaching the end shows it again, so the bar can
/// never be stranded off screen.
class BarScrollState {
  static const double hideAfter = 24;
  bool _visible = true;
  double _down = 0;

  bool get visible => _visible;

  void onScroll({
    required double delta,
    required bool atTop,
    required bool atEnd,
  }) {
    if (atTop || atEnd || delta < 0) {
      _down = 0;
      _visible = true;
      return;
    }
    _down += delta;
    if (_down > hideAfter) _visible = false;
  }

  void reset() {
    _down = 0;
    _visible = true;
  }

  /// Feeds a tab page's scroll notification through [onScroll]. Only
  /// vertical scroll updates count; horizontal carousels and pagers never
  /// move the bar. Returns whether [visible] changed.
  ///
  /// A [ScrollMetricsNotification] (content changed size without a scroll)
  /// that leaves the list at its top or end — e.g. search results that now
  /// fit the viewport — shows the bar too.
  bool onNotification(Notification n) {
    final before = _visible;
    if (n is ScrollMetricsNotification) {
      final m = n.metrics;
      if (m.axis == Axis.vertical &&
          (m.pixels <= m.minScrollExtent || m.pixels >= m.maxScrollExtent)) {
        reset();
      }
      return before != _visible;
    }
    if (n is! ScrollUpdateNotification || n.metrics.axis != Axis.vertical) {
      return false;
    }
    onScroll(
      delta: n.scrollDelta ?? 0,
      atTop: n.metrics.pixels <= n.metrics.minScrollExtent,
      atEnd: n.metrics.pixels >= n.metrics.maxScrollExtent,
    );
    return before != _visible;
  }
}

/// Re-tapping the active tab bumps [seq]; a tab with a list scrolls to top.
/// Tabs without a list ignore it.
final tabReselectProvider = StateProvider<({int tab, int seq})>(
  (ref) => (tab: -1, seq: 0),
);

const double _itemHeight = 44;
const double _iconSize = 24;
const double _labelGap = 6;

/// Narrowest the active name may get before it is dropped (a few letters
/// plus the ellipsis).
const double _labelMinWidth = 32;
const double _badgePadH = 5;
const double _badgeBorder = 1.5;
const double _badgeMinWidth = 20;

/// Screen edge to pill. 8, not 16: at 360 wide the active name ("Community")
/// needs the room.
const double _sideMargin = 8;

/// Active capsule's inner horizontal padding.
const double _capsulePadH = 10;
const Duration _slide = Duration(milliseconds: 200);
const Duration _morph = Duration(milliseconds: 220);
const Color _pillDark = Color(0xFF1C1C2E);

/// One tab in [FloatingTabBar].
class FloatingTabItem {
  const FloatingTabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.color,
    this.badgeCount = 0,
    this.imageAsset,
    this.avatarUrl,
  });

  final IconData icon;
  final IconData activeIcon;

  /// Drawn only on the active capsule; always the item's semantics label.
  final String label;

  /// The tab's accent: capsule fill, active icon and (darkened) label.
  final Color color;
  final int badgeCount;

  /// A full-colour image used instead of [icon] (the Chats logo mark).
  final String? imageAsset;

  /// The signed-in user's photo used instead of [icon] (Profile).
  final String? avatarUrl;
}

/// The capsule fill opacity behind the active tab (spec §8.1).
@visibleForTesting
double tabCapsuleAlpha({required bool dark}) => dark ? 0.20 : 0.14;

/// The active tab's label colour: the tab colour pushed toward black (light)
/// or white (dark) until it reads at >= 4.5:1 on its capsule. Starts at 35 %
/// and only goes further for colours that need it (amber, teal).
@visibleForTesting
Color tabLabelColor(Color c, {required bool dark}) {
  final pill = dark ? _pillDark : Colors.white;
  final fill = Color.alphaBlend(
    c.withValues(alpha: tabCapsuleAlpha(dark: dark)),
    pill,
  );
  final toward = dark ? Colors.white : Colors.black;
  final fillLum = fill.computeLuminance();
  for (var t = 0.35; t < 1; t += 0.05) {
    final candidate = Color.lerp(c, toward, t)!;
    final l = candidate.computeLuminance();
    final hi = l > fillLum ? l : fillLum;
    final lo = l > fillLum ? fillLum : l;
    if ((hi + 0.05) / (lo + 0.05) >= 4.5) return candidate;
  }
  return toward;
}

/// The floating glass pill tab bar (spec §8). Place it as a direct child of
/// a [Stack]: it positions itself at the bottom.
///
/// Inactive tabs are icon only; the active tab grows into a capsule with its
/// name. The bar slides away when [visible] is false or the keyboard is
/// open, and ignores touches while hidden.
class FloatingTabBar extends StatefulWidget {
  const FloatingTabBar({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelect,
    required this.visible,
    this.onKeyboardClosed,
  });

  final List<FloatingTabItem> items;
  final int selected;
  final ValueChanged<int> onSelect;
  final bool visible;

  /// Called when the keyboard goes from open to closed, so the owner can
  /// bring back a bar it hid on scroll (a list that now fits the viewport
  /// sends no scroll updates to do it).
  final VoidCallback? onKeyboardClosed;

  static const double height = 56;
  static const double _gapNoInset = 8;
  static const double _breathing = 12;

  /// Marks the glass pill for tests.
  @visibleForTesting
  static const pillKey = ValueKey('floating-tab-bar-pill');

  /// Distance from the screen bottom to the bar's bottom edge.
  static double _gap(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).bottom;
    return inset > 0 ? inset - 4 : _gapNoInset;
  }

  /// Space a tab page must leave at its bottom so content scrolls clear of
  /// the floating bar (spec §8.2). Mirrors the bar's own positioning.
  static double clearance(BuildContext context) {
    return _gap(context) + height + _breathing;
  }

  /// Room a list leaves above [clearance] for a create FAB that sits on the
  /// bar (an extended FAB is 48 tall, plus a 16 gap to the last item).
  static const double fabSpace = 64;

  /// Bottom padding for a `Scaffold.floatingActionButton` on a tab page so
  /// the button's bottom edge lands on [clearance], like the reels FAB.
  /// The Scaffold already lifts a FAB by its 16 margin plus the bottom
  /// view padding, so only the rest is added here.
  static double fabLift(BuildContext context) {
    final lift = clearance(context) -
        kFloatingActionButtonMargin -
        MediaQuery.viewPaddingOf(context).bottom;
    return lift < 0 ? 0 : lift;
  }

  @override
  State<FloatingTabBar> createState() => _FloatingTabBarState();
}

class _FloatingTabBarState extends State<FloatingTabBar>
    with WidgetsBindingObserver {
  List<FloatingTabItem> get items => widget.items;
  int get selected => widget.selected;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// The keyboard shows up as a change in the view's insets. Re-read them
  /// here because the bar sits inside a Scaffold body, whose MediaQuery has
  /// the view insets removed.
  @override
  void didChangeMetrics() {
    if (!mounted) return;
    final open = _keyboardOpen;
    // Insets change on every frame of the keyboard animation; only an
    // open/closed flip needs a rebuild (the inset itself reaches the bar
    // through MediaQuery).
    if (open == _wasKeyboardOpen) return;
    final closed = _wasKeyboardOpen && !open;
    _wasKeyboardOpen = open;
    setState(() {});
    if (closed) widget.onKeyboardClosed?.call();
  }

  bool get _keyboardOpen => View.of(context).viewInsets.bottom > 0;

  /// Last seen keyboard state, to report open -> closed exactly once.
  bool _wasKeyboardOpen = false;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDarkMode;
    _wasKeyboardOpen = _keyboardOpen;
    final hidden = !widget.visible || _wasKeyboardOpen;

    // Slides by moving its own box (not a paint transform) so the hidden
    // bar's layout rect is off screen too, shadow included.
    return AnimatedPositioned(
      left: 0,
      right: 0,
      bottom: hidden
          ? -2 * FloatingTabBar.height
          : FloatingTabBar._gap(context),
      duration: _slide,
      curve: Curves.easeOutCubic,
      child: IgnorePointer(
        ignoring: hidden,
        // A slid-away bar must not keep five dead TalkBack/VoiceOver stops.
        child: ExcludeSemantics(
          excluding: hidden,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _sideMargin),
            child: Center(
              child: ClipRRect(
                key: FloatingTabBar.pillKey,
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    height: FloatingTabBar.height,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: dark
                          ? _pillDark.withValues(alpha: 0.92)
                          : Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: dark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: dark
                              ? Colors.black.withValues(alpha: 0.4)
                              : Colors.black.withValues(alpha: 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 4),
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < items.length; i++)
                          if (i == selected)
                            // Only the active capsule may shrink, so a long
                            // name ellipsizes instead of overflowing.
                            Flexible(child: _item(context, i, dark))
                          else
                            _item(context, i, dark),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(BuildContext context, int i, bool dark) {
    final item = items[i];
    final isSelected = i == selected;
    final inactiveColor = dark
        ? Colors.white.withValues(alpha: 0.4)
        : Colors.black.withValues(alpha: 0.35);
    final labelStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w700,
      color: tabLabelColor(item.color, dark: dark),
    );

    final Widget icon;
    if (item.avatarUrl != null) {
      icon = AnimatedContainer(
        duration: _morph,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? item.color : Colors.transparent,
            width: 2,
          ),
        ),
        child: CircleAvatar(
          radius: 10,
          backgroundColor: inactiveColor,
          backgroundImage: CachedNetworkImageProvider(item.avatarUrl!),
        ),
      );
    } else if (item.imageAsset != null) {
      // Full-colour brand mark: it can't tint, so dim it when inactive.
      icon = AnimatedOpacity(
        duration: _morph,
        opacity: isSelected ? 1.0 : 0.45,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.asset(
            item.imageAsset!,
            width: 24,
            height: 24,
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      icon = Icon(
        isSelected ? item.activeIcon : item.icon,
        size: _iconSize,
        color: isSelected ? item.color : inactiveColor,
      );
    }

    final hasBadge = item.badgeCount > 0;
    // The count overhangs the icon's corner; overhang never overflows.
    final iconWithBadge = Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        if (hasBadge)
          Positioned(
            right: -10,
            top: -6,
            child: _badge(context, item.badgeCount, dark),
          ),
      ],
    );

    // The active capsule degrades instead of overflowing on narrow screens
    // or large text: first the count moves from after the name back onto
    // the icon, then the name drops (it stays the semantics label).
    final Widget content = !isSelected
        ? iconWithBadge
        : LayoutBuilder(
            builder: (context, c) {
              final room = c.maxWidth;
              const withLabel = _iconSize + _labelGap + _labelMinWidth;
              if (room < withLabel) return iconWithBadge;
              final badgeAfter = hasBadge
                  ? _labelGap + _badgeWidth(context, item.badgeCount)
                  : 0.0;
              final countAfterName = hasBadge && room >= withLabel + badgeAfter;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasBadge && !countAfterName) iconWithBadge else icon,
                  const SizedBox(width: _labelGap),
                  Flexible(
                    child: Text(
                      item.label,
                      style: labelStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  ),
                  if (countAfterName) ...[
                    const SizedBox(width: _labelGap),
                    _badge(context, item.badgeCount, dark),
                  ],
                ],
              );
            },
          );

    return Semantics(
      button: true,
      selected: isSelected,
      // The unread count is drawn but would otherwise never be announced.
      label: item.badgeCount > 0
          ? '${item.label}, ${item.badgeCount}'
          : item.label,
      excludeSemantics: true,
      onTap: () => widget.onSelect(i),
      child: GestureDetector(
        onTap: () => widget.onSelect(i),
        behavior: HitTestBehavior.opaque,
        // No gap between items: the 48 min width is the hit target.
        child: AnimatedContainer(
          duration: _morph,
          curve: Curves.easeOutCubic,
          height: _itemHeight,
          padding: isSelected
              ? const EdgeInsets.symmetric(horizontal: _capsulePadH)
              : EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 48),
          decoration: BoxDecoration(
            color: isSelected
                ? item.color.withValues(alpha: tabCapsuleAlpha(dark: dark))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          // widthFactor 1: centre the content but hug it. A plain
          // `alignment` would stretch the (Flexible) active capsule over
          // all the free width.
          child: Align(widthFactor: 1, child: content),
        ),
      ),
    );
  }

  TextStyle? _badgeStyle(BuildContext context) => Theme.of(context)
      .textTheme
      .labelMedium
      ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700, height: 1.2);

  String _badgeText(int count) => count > 99 ? '99+' : '$count';

  /// Laid-out width of [_badge] for [count] at the current text scale.
  double _badgeWidth(BuildContext context, int count) {
    final painter = TextPainter(
      text: TextSpan(text: _badgeText(count), style: _badgeStyle(context)),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final w = painter.width + 2 * _badgePadH + 2 * _badgeBorder;
    painter.dispose();
    return w < _badgeMinWidth ? _badgeMinWidth : w;
  }

  Widget _badge(BuildContext context, int count, bool dark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: _badgePadH),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: dark ? _pillDark : Colors.white,
          width: _badgeBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      constraints: const BoxConstraints(minWidth: _badgeMinWidth),
      child: Text(
        _badgeText(count),
        style: _badgeStyle(context),
        textAlign: TextAlign.center,
        maxLines: 1,
      ),
    );
  }
}
