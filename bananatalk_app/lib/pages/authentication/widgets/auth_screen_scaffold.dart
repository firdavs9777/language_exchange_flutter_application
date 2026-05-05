import 'package:flutter/material.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Standard scaffold for auth screens — surface bg, transparent AppBar
/// with rounded back, scrollable body that survives keyboard pop-up.
class AuthScreenScaffold extends StatelessWidget {
  final String? title;
  final bool showBackButton;
  final List<Widget>? actions;
  final Widget body;
  final EdgeInsetsGeometry bodyPadding;
  final bool resizeToAvoidBottomInset;

  const AuthScreenScaffold({
    super.key,
    this.title,
    this.showBackButton = true,
    this.actions,
    required this.body,
    this.bodyPadding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        foregroundColor: context.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: title == null
            ? null
            : Text(
                title!,
                style: context.titleLarge.copyWith(fontWeight: FontWeight.w700),
              ),
        actions: actions,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: bodyPadding,
          child: body,
        ),
      ),
    );
  }
}
