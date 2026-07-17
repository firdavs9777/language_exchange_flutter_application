import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

class StoryFilter {
  const StoryFilter(this.name, this.matrix);
  final String name;
  final List<double>? matrix; // null = no filter
}

const kStoryFilters = <StoryFilter>[
  StoryFilter('Normal', null),
  StoryFilter('Warm', [
    1.15, 0, 0, 0, 10, 0, 1.05, 0, 0, 5, 0, 0, 0.9, 0, 0, 0, 0, 0, 1, 0,
  ]),
  StoryFilter('Cool', [
    0.95, 0, 0, 0, 0, 0, 1.0, 0, 0, 5, 0, 0, 1.15, 0, 10, 0, 0, 0, 1, 0,
  ]),
  StoryFilter('Mono', [
    0.33, 0.59, 0.11, 0, 0, 0.33, 0.59, 0.11, 0, 0,
    0.33, 0.59, 0.11, 0, 0, 0, 0, 0, 1, 0,
  ]),
  StoryFilter('Fade', [
    0.9, 0, 0, 0, 25, 0, 0.9, 0, 0, 25, 0, 0, 0.9, 0, 25, 0, 0, 0, 1, 0,
  ]),
  StoryFilter('Vivid', [
    1.25, 0, 0, 0, -10, 0, 1.25, 0, 0, -10, 0, 0, 1.25, 0, -10, 0, 0, 0, 1, 0,
  ]),
];

/// Wraps [child] in the selected filter's ColorFiltered (identity when null).
Widget applyStoryFilter(int index, Widget child) {
  final m = kStoryFilters[index].matrix;
  if (m == null) return child;
  return ColorFiltered(colorFilter: ColorFilter.matrix(m), child: child);
}

class FilterBar extends StatelessWidget {
  const FilterBar({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.preview,
  });
  final int selected;
  final ValueChanged<int> onSelect;
  final ImageProvider preview;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: kStoryFilters.length,
        itemBuilder: (context, i) => GestureDetector(
          onTap: () => onSelect(i),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: selected == i
                          ? const Color(0xFF00BFA5)
                          : Colors.white24,
                      width: selected == i ? 2.5 : 1),
                ),
                clipBehavior: Clip.hardEdge,
                child: applyStoryFilter(
                    i, Image(image: preview, fit: BoxFit.cover)),
              ),
              const SizedBox(height: 4),
              Text(kStoryFilters[i].name,
                  style: const TextStyle(color: Colors.white70, fontSize: 10)),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Captures the composed (filtered + drawn-on) image; falls back to the
/// original file on any failure so posting never breaks.
Future<File> bakeImage(GlobalKey repaintKey, File fallback) async {
  try {
    final boundary = repaintKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return fallback;
    final image = await boundary.toImage(pixelRatio: 2.0);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return fallback;
    final dir = await getTemporaryDirectory();
    final f = File(
        '${dir.path}/story_baked_${DateTime.now().millisecondsSinceEpoch}.png');
    await f.writeAsBytes(bytes.buffer.asUint8List());
    return f;
  } catch (_) {
    return fallback;
  }
}
