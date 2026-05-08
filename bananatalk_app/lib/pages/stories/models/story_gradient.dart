import 'package:flutter/material.dart';

class StoryGradient {
  final String id;
  final String name;
  final List<Color> colors;
  final List<double> stops;

  const StoryGradient({
    required this.id,
    required this.name,
    required this.colors,
    this.stops = const [0.0, 1.0],
  });

  LinearGradient toLinearGradient() => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
        stops: stops,
      );

  static const List<StoryGradient> presets = [
    StoryGradient(id: 'gradient_sunset', name: 'Sunset', colors: [Color(0xFFFF512F), Color(0xFFF09819)]),
    StoryGradient(id: 'gradient_ocean', name: 'Ocean', colors: [Color(0xFF2193B0), Color(0xFF6DD5ED)]),
    StoryGradient(id: 'gradient_forest', name: 'Forest', colors: [Color(0xFF134E5E), Color(0xFF71B280)]),
    StoryGradient(id: 'gradient_purple', name: 'Purple', colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)]),
    StoryGradient(id: 'gradient_fire', name: 'Fire', colors: [Color(0xFFEB5757), Color(0xFFF2994A)]),
    StoryGradient(id: 'gradient_midnight', name: 'Midnight', colors: [Color(0xFF232526), Color(0xFF414345)]),
    StoryGradient(id: 'gradient_candy', name: 'Candy', colors: [Color(0xFFFC466B), Color(0xFF3F5EFB)]),
    StoryGradient(id: 'gradient_sky', name: 'Sky', colors: [Color(0xFF56CCF2), Color(0xFF2F80ED)]),
    StoryGradient(id: 'gradient_aurora', name: 'Aurora', colors: [Color(0xFF00C9FF), Color(0xFF92FE9D)]),
    StoryGradient(id: 'gradient_peach', name: 'Peach', colors: [Color(0xFFED4264), Color(0xFFFFEDBC)]),
    StoryGradient(id: 'gradient_mint', name: 'Mint', colors: [Color(0xFF00B09B), Color(0xFF96C93D)]),
    StoryGradient(id: 'gradient_lavender', name: 'Lavender', colors: [Color(0xFFE1B0FF), Color(0xFFB39DDB)]),
    StoryGradient(
      id: 'gradient_galaxy',
      name: 'Galaxy',
      colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
      stops: [0.0, 0.5, 1.0],
    ),
  ];

  static StoryGradient byId(String id) =>
      presets.firstWhere((g) => g.id == id, orElse: () => presets.first);
}
