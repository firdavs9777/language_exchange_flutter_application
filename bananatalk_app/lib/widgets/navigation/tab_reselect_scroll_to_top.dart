import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/widgets/navigation/floating_tab_bar.dart';

/// Scrolls the on-screen vertical lists inside [child] to the top when the
/// user re-taps tab [tab] in the floating bar (spec §8.2, `tabReselectProvider`).
///
/// Used for tabs whose lists live deep inside sub-tabs and screens that each
/// own (or don't own) their controller — Community's eight sub-tabs, the
/// chat list, the moments feed and reels grid. Rather than threading a
/// controller through every one of them, it finds the [Scrollable]s under
/// it that are vertical, scrolled, and actually on screen. A sub-tab kept
/// alive off to the side of a `TabBarView` is not on screen, so it keeps its
/// place. Horizontal carousels are never touched.
class TabReselectScrollToTop extends ConsumerStatefulWidget {
  const TabReselectScrollToTop({
    super.key,
    required this.tab,
    required this.child,
  });

  /// The top-level tab index this subtree belongs to.
  final int tab;
  final Widget child;

  static const Duration duration = Duration(milliseconds: 300);

  @override
  ConsumerState<TabReselectScrollToTop> createState() =>
      _TabReselectScrollToTopState();
}

class _TabReselectScrollToTopState
    extends ConsumerState<TabReselectScrollToTop> {
  void _scrollToTop() {
    final scope = context.findRenderObject();
    if (scope is! RenderBox || !scope.attached || !scope.hasSize) return;
    final scopeRect = scope.localToGlobal(Offset.zero) & scope.size;

    void visit(Element e) {
      if (e is StatefulElement && e.state is ScrollableState) {
        final position = (e.state as ScrollableState).position;
        final box = e.renderObject;
        if (position.axis == Axis.vertical &&
            position.hasPixels &&
            position.hasContentDimensions &&
            position.pixels > position.minScrollExtent &&
            box is RenderBox &&
            box.attached &&
            box.hasSize &&
            _painted(box, scope) &&
            (box.localToGlobal(Offset.zero) & box.size).overlaps(scopeRect)) {
          position.animateTo(
            position.minScrollExtent,
            duration: TabReselectScrollToTop.duration,
            curve: Curves.easeOutCubic,
          );
        }
      }
      e.visitChildren(visit);
    }

    context.visitChildElements(visit);
  }

  /// Whether every ancestor between [box] and [scope] paints it. A sub-tab
  /// a `TabBarView` keeps alive off screen sits in its sliver's keep-alive
  /// bucket: still attached, but not painted and with a stale offset.
  static bool _painted(RenderObject box, RenderObject scope) {
    RenderObject node = box;
    while (node != scope) {
      final parent = node.parent;
      if (parent == null) return false;
      if (!parent.paintsChild(node)) return false;
      node = parent;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(tabReselectProvider, (_, next) {
      if (next.tab == widget.tab) _scrollToTop();
    });
    return widget.child;
  }
}
