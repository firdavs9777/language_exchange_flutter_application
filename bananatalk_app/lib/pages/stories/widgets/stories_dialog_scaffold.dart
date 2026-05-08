import 'package:flutter/material.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

class StoriesDialogScaffold extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const StoriesDialogScaffold({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: padding,
      child: SafeArea(child: child),
    );
  }
}
