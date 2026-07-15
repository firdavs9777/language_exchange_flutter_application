import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/languages_provider.dart';

/// Legacy minimal fallback, kept for the (fetch-failed, no persisted
/// cache) case so the voice-room filter/create sheet is never empty.
const List<String> kVoiceRoomLanguagesFallback = [
  'English',
  'Korean',
  'Japanese',
  'Chinese',
  'Spanish',
  'French',
  'German',
  'Italian',
  'Portuguese',
  'Russian',
  'Arabic',
  'Hindi',
  'Uzbek',
];

/// Voice-room language names — now derived from the shared catalog
/// (languagesProvider: one fetch, session + persisted cache) instead of
/// its own HTTP call. Raw catalog names, matching what rooms store.
final voiceRoomLanguagesProvider = FutureProvider<List<String>>((ref) async {
  final catalog = await ref.watch(languagesProvider.future);
  final names = catalog.map((l) => l.name).toList();
  return names.isEmpty ? kVoiceRoomLanguagesFallback : names;
});
