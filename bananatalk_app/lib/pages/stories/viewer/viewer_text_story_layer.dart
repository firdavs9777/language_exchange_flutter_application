import 'package:flutter/material.dart';
import 'package:bananatalk_app/pages/stories/models/story_gradient.dart';

class ViewerTextStoryLayer extends StatelessWidget {
  final String text;
  final String backgroundColorHint; // either '#RRGGBB' or 'gradient_<name>'
  final String textColor; // '#RRGGBB'
  final String fontStyle; // 'normal' | 'bold' | 'italic' | 'handwriting'

  const ViewerTextStoryLayer({
    super.key,
    required this.text,
    required this.backgroundColorHint,
    required this.textColor,
    required this.fontStyle,
  });

  Color _parseColor(String hex) {
    final cleaned = hex.replaceAll('#', '');
    final value = cleaned.length == 6 ? 'FF$cleaned' : cleaned;
    return Color(int.parse(value, radix: 16));
  }

  Decoration _background() {
    if (backgroundColorHint.startsWith('gradient_')) {
      return BoxDecoration(
        gradient: StoryGradient.byId(backgroundColorHint).toLinearGradient(),
      );
    }
    if (backgroundColorHint.startsWith('#')) {
      return BoxDecoration(color: _parseColor(backgroundColorHint));
    }
    // Fallback to black
    return const BoxDecoration(color: Colors.black);
  }

  TextStyle _textStyleOf() {
    final base = TextStyle(
      color: _parseColor(textColor),
      fontSize: 28,
      height: 1.3,
    );
    return switch (fontStyle) {
      'bold' => base.copyWith(fontWeight: FontWeight.bold),
      'italic' => base.copyWith(fontStyle: FontStyle.italic),
      'handwriting' => base.copyWith(fontFamily: 'Caveat'),
      _ => base,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _background(),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: _textStyleOf(),
            ),
          ),
        ),
      ),
    );
  }
}
