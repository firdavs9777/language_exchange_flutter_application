import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/utils/hashtag_text.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Whether the server has hashtags on (`appConfig.hashtagsEnabled`); false
/// while the config loads or when it could not be fetched.
final hashtagsEnabledProvider = Provider<bool>(
  (ref) => ref
      .watch(appConfigProvider)
      .maybeWhen(
        data: (config) => config?.hashtagsEnabled ?? false,
        orElse: () => false,
      ),
);

/// Opens the page of hashtag [tag] (as typed or stored, with or without `#`).
void openHashtag(BuildContext context, String tag) {
  final clean = normalizeHashtag(tag);
  if (clean == null) return;
  context.push('/hashtag/${Uri.encodeComponent(clean)}');
}

/// Makes a tag chip ([child]) open its hashtag page when [enabled]; with it
/// off, [child] is returned untouched.
class HashtagTap extends StatelessWidget {
  const HashtagTap({
    super.key,
    required this.enabled,
    required this.tag,
    required this.child,
  });

  final bool enabled;
  final String tag;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => openHashtag(context, tag),
      child: child,
    );
  }
}

/// Text whose `#hashtags` are tappable when [linksEnabled]. With links off it
/// is exactly the [Text] it replaces (same style, lines and overflow), so a
/// screen looks the same until the server turns hashtags on.
class HashtagText extends StatefulWidget {
  const HashtagText({
    super.key,
    required this.text,
    this.style,
    this.maxLines,
    this.overflow,
    required this.linksEnabled,
  });

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool linksEnabled;

  @override
  State<HashtagText> createState() => _HashtagTextState();
}

class _HashtagTextState extends State<HashtagText> {
  final List<TapGestureRecognizer> _recognizers = [];

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.linksEnabled) {
      return Text(
        widget.text,
        style: widget.style,
        maxLines: widget.maxLines,
        overflow: widget.overflow,
      );
    }
    // Rebuilt each time: the recognizers belong to the spans drawn now.
    _disposeRecognizers();
    final color = Theme.of(context).colorScheme.primary;
    final spans = <InlineSpan>[
      for (final span in splitHashtags(widget.text))
        if (span.isHashtag)
          TextSpan(
            text: span.text,
            style: TextStyle(color: color),
            recognizer: TapGestureRecognizer()
              ..onTap = () => openHashtag(context, span.tag!),
          )
        else
          TextSpan(text: span.text),
    ];
    for (final span in spans) {
      final r = (span as TextSpan).recognizer;
      if (r is TapGestureRecognizer) _recognizers.add(r);
    }
    return Text.rich(
      TextSpan(children: spans),
      style: widget.style,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
    );
  }
}
