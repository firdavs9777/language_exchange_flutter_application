import 'package:bananatalk_app/pages/menu_tab/TabBarMenu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A top-level page built the first time its tab is selected, then kept.
/// TabsScreen built every page at launch, so Community's requests fired on
/// app start even for people who never opened it.
class LazyTab extends ConsumerStatefulWidget {
  const LazyTab({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  ConsumerState<LazyTab> createState() => _LazyTabState();
}

class _LazyTabState extends ConsumerState<LazyTab> {
  bool _visited = false;

  @override
  Widget build(BuildContext context) {
    _visited = _visited || ref.watch(selectedTabProvider) == widget.index;
    return _visited ? widget.child : const SizedBox.shrink();
  }
}
