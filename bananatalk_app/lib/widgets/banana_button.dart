import 'package:flutter/material.dart';

class BananaButton extends StatelessWidget {
  final Widget BananaText; // This should be your BananaText widget
  final VoidCallback onPressed;
  final Color? color;
  final Color? textColor;
  final TextStyle? textStyle;
  final double? elevation;
  final EdgeInsetsGeometry? padding;
  final BorderSide? borderSide;
  final BorderRadiusGeometry? borderRadius;
  final Widget? icon;

  const BananaButton({
    super.key,
    required this.BananaText,
    required this.onPressed,
    this.color,
    this.textColor,
    this.textStyle,
    this.elevation,
    this.padding,
    this.borderSide,
    this.borderRadius,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color, // Updated from 'primary' (deprecated)
        elevation: elevation,
        padding: padding,
        side: borderSide,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(4.0),
        ),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize:
            MainAxisSize.min, // Important: prevents unnecessary expansion
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            icon!,
            SizedBox(width: 8),
          ],
          BananaText, // Use the widget directly, not as text in Text()
        ],
      ),
    );
  }
}
