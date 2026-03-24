import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// A text widget that automatically detects URLs and makes them tappable.
/// URLs are styled with underline and accent color, and open in an external browser.
class LinkifiedText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final TextStyle? linkStyle;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  const LinkifiedText({
    super.key,
    required this.text,
    required this.style,
    this.linkStyle,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  @override
  State<LinkifiedText> createState() => _LinkifiedTextState();
}

class _LinkifiedTextState extends State<LinkifiedText> {
  static final _urlRegex = RegExp(
    r'(https?://[^\s]+|www\.[^\s]+)',
    caseSensitive: false,
  );

  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    var uri = Uri.tryParse(url);
    if (uri == null) return;

    // Prepend https:// for www. URLs
    if (url.toLowerCase().startsWith('www.')) {
      uri = Uri.parse('https://$url');
    }

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  List<TextSpan> _buildSpans() {
    // Dispose old recognizers
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    final spans = <TextSpan>[];
    final text = widget.text;

    final effectiveLinkStyle = widget.linkStyle ??
        widget.style.copyWith(
          color: const Color(0xFF1E88E5),
          decoration: TextDecoration.underline,
          decorationColor: const Color(0xFF1E88E5),
        );

    int lastEnd = 0;
    for (final match in _urlRegex.allMatches(text)) {
      // Add plain text before the URL
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: widget.style,
        ));
      }

      // Add the URL as a tappable span
      final url = match.group(0)!;
      final recognizer = TapGestureRecognizer()..onTap = () => _openUrl(url);
      _recognizers.add(recognizer);

      spans.add(TextSpan(
        text: url,
        style: effectiveLinkStyle,
        recognizer: recognizer,
      ));

      lastEnd = match.end;
    }

    // Add remaining plain text
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: widget.style,
      ));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    // If no URLs found, render as plain text for performance
    if (!_urlRegex.hasMatch(widget.text)) {
      return Text(
        widget.text,
        style: widget.style,
        maxLines: widget.maxLines,
        overflow: widget.overflow,
        textAlign: widget.textAlign,
      );
    }

    return Text.rich(
      TextSpan(children: _buildSpans()),
      maxLines: widget.maxLines,
      overflow: widget.overflow,
      textAlign: widget.textAlign,
    );
  }
}
