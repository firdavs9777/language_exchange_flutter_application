/// AI Study hub spacing (spec 2026-10-13 §3.1). Compact on purpose — the owner
/// asked that no space be wasted. Use these, never literals, in hub files.
class StudyHubMetrics {
  StudyHubMetrics._();

  static const double pageMargin = 12;
  static const double tileGap = 8;
  static const double groupGap = 16;
  static const double groupLabelGap = 8;
  static const double tileHeight = 64;
  static const double todayRowHeight = 72;
  static const double recommendedHeight = 48;
  static const double carouselCardHeight = 84;
  static const double cardRadius = 16;
  static const double tileRadius = 14;
  static const double tileIconSize = 36;
}
