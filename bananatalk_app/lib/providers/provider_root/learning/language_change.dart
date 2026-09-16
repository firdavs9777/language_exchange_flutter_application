import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:bananatalk_app/providers/provider_root/learning/daily_pack_providers.dart';
import 'package:bananatalk_app/providers/provider_root/learning/lessons_providers.dart';
import 'package:bananatalk_app/providers/tutor_provider.dart';

/// Everything that has to be re-fetched when a learner changes which language
/// they speak or which one they are learning.
///
/// WHY THIS EXISTS: changing `language_to_learn` used to invalidate exactly one
/// provider — the prompt of the day. Everything else kept serving content for
/// the OLD language until the app was restarted:
///
///   * `dailyPackProvider` watches only the app's UI locale, while the SERVER
///     derives the pack's content language from the profile. Switching from
///     Korean to Japanese left yesterday's Korean pack on the Today tab,
///     looking like the change had not saved.
///   * `userProvider` itself was never refreshed, so every screen reading the
///     language pair off the cached user — lesson filters, recommendations —
///     stayed on the old pair.
///   * The tutor's memory holds `targetLanguages` server-side.
///
/// Both directions matter. Native language is not cosmetic here: it is the
/// SOURCE language for lessons and explanations, so changing it changes the
/// content just as much as changing the target does.
///
/// Kept as one function rather than a list of `ref.invalidate` calls at each
/// call site, because the recurring defect in this codebase is one rule living
/// in several places and getting fixed in one of them. Anything language-
/// derived gets added HERE, and every caller improves at once.
void invalidateLanguageDerived(WidgetRef ref) {
  // The root. Anything that WATCHES the user (recommendedLessonsProvider, and
  // every screen reading the language pair) re-runs off this one line.
  ref.invalidate(userProvider);

  // These do not watch the user, so they need saying explicitly.
  ref.invalidate(dailyPackProvider);
  ref.invalidate(promptOfDayProvider);
  ref.invalidate(tutorMemoryAndQuotasProvider);
  ref.invalidate(recommendedLessonsProvider);

  // Lesson filters are held in a StateProvider that screens seed from the user
  // in initState. Resetting it means the next open re-seeds from the fresh
  // user rather than keeping the old pair for the life of the process.
  ref.invalidate(lessonFilterProvider);
}
