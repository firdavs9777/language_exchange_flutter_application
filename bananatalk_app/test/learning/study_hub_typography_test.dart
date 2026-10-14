import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Spec §3.2: hub files use the text theme, never size literals.
void main() {
  const files = [
    'lib/pages/learning/main/study_hub.dart',
    'lib/pages/learning/main/sections/study_feature_tile.dart',
    'lib/pages/learning/main/sections/study_feature_groups.dart',
    'lib/pages/learning/main/sections/today_pack_row.dart',
    'lib/pages/learning/main/sections/recommended_tile.dart',
    'lib/pages/learning/main/sections/spotlight_carousel.dart',
    'lib/pages/learning/main/sections/progress_card.dart',
    'lib/widgets/study/study_upgrade_sheet.dart',
  ];
  for (final f in files) {
    test('$f has no fontSize literal', () {
      expect(File(f).readAsStringSync().contains(RegExp(r'fontSize:\s*\d')), isFalse);
    });
  }
}
