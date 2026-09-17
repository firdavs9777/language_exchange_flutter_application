import 'package:flutter/material.dart';

import 'package:bananatalk_app/widgets/cached_image_widget.dart';

/// The cover strip for a club or a gathering.
///
/// A cover is OPTIONAL and most groups will not have one, so the no-image case
/// is the designed state rather than a fallback bolted on: it renders a colour
/// derived from the group's own id, which is stable across rebuilds and
/// devices and gives every group a recognisable identity without anyone
/// uploading anything.
///
/// Deriving from the id rather than picking at random matters — a colour that
/// changed on every rebuild would make a list flicker, and one that differed
/// per device would stop being a recognition cue at all.
class GroupCover extends StatelessWidget {
  const GroupCover({
    super.key,
    required this.id,
    required this.title,
    this.imageUrl,
    this.height = 160,
    this.onTap,
  });

  final String id;
  final String title;
  final String? imageUrl;
  final double height;

  /// Set only for someone who may change it. A tap that cannot do anything is
  /// worse than no tap at all.
  final VoidCallback? onTap;

  /// Muted, readable-behind-white palette. Not theme colours: these sit under
  /// white text in both light and dark mode, so they must be dark enough in
  /// both rather than flipping with the theme.
  static const List<List<Color>> _palettes = [
    [Color(0xFF4E5D94), Color(0xFF6B7BB8)],
    [Color(0xFF3F6B52), Color(0xFF5A8F70)],
    [Color(0xFF8A5A3C), Color(0xFFB07A55)],
    [Color(0xFF5B4B7A), Color(0xFF7E6BA3)],
    [Color(0xFF2F6B73), Color(0xFF4A8F99)],
    [Color(0xFF7A4550), Color(0xFFA36470)],
  ];

  /// Exposed for tests: the stability of this mapping is the property that
  /// matters, and asserting it through a rendered gradient would be brittle.
  static List<List<Color>> get palettesForTest => _palettes;

  List<Color> get _palette {
    if (id.isEmpty) return _palettes.first;
    // Sum of code units: stable for a given id, and cheap.
    final hash = id.codeUnits.fold<int>(0, (a, b) => a + b);
    return _palettes[hash % _palettes.length];
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    final colors = _palette;

    final cover = SizedBox(
      height: height,
      width: double.infinity,
      child: hasImage
          ? CachedImageWidget(
              key: const Key('group-cover-image'),
              imageUrl: imageUrl!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: height,
            )
          : Container(
              key: const Key('group-cover-fallback'),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
    );

    if (onTap == null) return cover;

    return Stack(
      children: [
        cover,
        Positioned(
          right: 12,
          bottom: 12,
          child: Material(
            color: Colors.black.withValues(alpha: 0.55),
            shape: const CircleBorder(),
            child: InkWell(
              key: const Key('group-cover-edit'),
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.photo_camera_outlined,
                    color: Colors.white, size: 20),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
