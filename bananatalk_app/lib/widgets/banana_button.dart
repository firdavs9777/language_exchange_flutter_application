import 'package:flutter/material.dart';

class BananaButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? color;
  final Color? textColor;
  final TextStyle? textStyle;
  final double? elevation;
  final EdgeInsetsGeometry? padding;
  final BorderSide? borderSide;
  final BorderRadiusGeometry? borderRadius;
  final Widget? icon; // Add the icon parameter

  const BananaButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color,
    this.textColor,
    this.textStyle,
    this.elevation,
    this.padding,
    this.borderSide,
    this.borderRadius,
    this.icon, // Accept the icon parameter
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        primary: color,
        elevation: elevation,
        padding: padding,
        side: borderSide,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(4.0),
        ),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            icon!, // Display the icon if it's provided
            SizedBox(width: 8), // Add some space between the icon and the text
          ],
          Text(
            text,
            style: textStyle ??
                TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
          ),
        ],
      ),
    );
  }
}
