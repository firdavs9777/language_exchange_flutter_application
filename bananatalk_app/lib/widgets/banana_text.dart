import 'package:flutter/material.dart';

class BananaText extends StatelessWidget {
  final String text;
  final TextStyle? BanaStyles;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final bool? softWrap;

  // CORRECTED CONSTRUCTOR - Key and all optional parameters in curly braces
  const BananaText(
    this.text, {
    Key? key,
    this.BanaStyles,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: BanaStyles,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      softWrap: softWrap,
    );
  }
}

class BananaTextStyles {
  // Original styles
  static const TextStyle heading = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle subheading = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
  );

  // Extended styles for buttons and more
  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static const TextStyle buttonTextDark = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle largeButton = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle smallButton = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );

  // Link styles
  static const TextStyle link = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: Colors.blue,
    decoration: TextDecoration.underline,
  );

  static const TextStyle linkBold = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.blue,
    decoration: TextDecoration.underline,
  );

  // Title styles
  static const TextStyle title = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.bold,
  );

  // Error and success styles
  static const TextStyle error = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: Colors.red,
  );

  static const TextStyle success = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: Colors.white,
  );

  static const TextStyle warning = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: Colors.orange,
  );

  // Input field styles
  static const TextStyle labelText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle inputText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle hintText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
  );

  // Special text styles
  static const TextStyle boldText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle lightText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w300,
  );

  static const TextStyle smallText = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle largeText = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.normal,
  );

  // App bar text
  static const TextStyle appBarTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  // Card text styles
  static const TextStyle cardTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
  );

  // Price/number styles
  static const TextStyle price = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.green,
  );

  static const TextStyle priceStrike = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,

    decoration: TextDecoration.lineThrough,
  );
}
