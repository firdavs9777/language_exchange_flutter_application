import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/models/language_model.dart';
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:bananatalk_app/utils/language_codes.dart';

/// Shared language catalog — the ONE source for every language picker.
///
/// The backend `languages` collection (GET /languages, 127+ entries) is the
/// source of truth for what languages exist in this app. Signup, profile
/// edit, the community filter and the AI screens already fetched it; this
/// provider extends that to the previously-hardcoded surfaces (moment
/// composer tag incl. reels/prompt defaults, moments feed filter, matching,
/// vocabulary add, AI lesson builder, voice-room create).
///
/// Resolution order:
///   1. network fetch (result persisted for offline),
///   2. persisted cache from a previous session,
///   3. [kLanguageCatalogFallback] (minimal hardcoded list) — fetch-failed,
///      first-ever launch offline.
/// The session itself is cached by the FutureProvider (fetched once until
/// invalidated).

const String _kLanguagesCacheKey = 'languages_catalog_cache_v1';

/// Minimal offline fallback — intentionally small; the catalog is the
/// real list. Mirrors the composer's historical 17 languages so no
/// existing selection can become invalid when offline.
const List<Map<String, String>> _kFallbackEntries = [
  {'code': 'en', 'name': 'English'},
  {'code': 'ko', 'name': 'Korean'},
  {'code': 'ja', 'name': 'Japanese'},
  {'code': 'zh', 'name': 'Chinese'},
  {'code': 'es', 'name': 'Spanish'},
  {'code': 'fr', 'name': 'French'},
  {'code': 'de', 'name': 'German'},
  {'code': 'it', 'name': 'Italian'},
  {'code': 'pt', 'name': 'Portuguese'},
  {'code': 'ru', 'name': 'Russian'},
  {'code': 'ar', 'name': 'Arabic'},
  {'code': 'hi', 'name': 'Hindi'},
  {'code': 'tg', 'name': 'Tajik'},
  {'code': 'th', 'name': 'Thai'},
  {'code': 'vi', 'name': 'Vietnamese'},
  {'code': 'nl', 'name': 'Dutch'},
  {'code': 'sv', 'name': 'Swedish'},
];

final List<Language> kLanguageCatalogFallback = List.unmodifiable(
  _kFallbackEntries.map(
    (e) => Language(
      id: '',
      code: e['code']!,
      name: e['name']!,
      nativeName: e['name']!,
    ),
  ),
);

/// Parse a `GET /languages` response body (or the persisted copy of one)
/// into Language objects. Returns [] for anything malformed.
List<Language> parseLanguageCatalog(String body) {
  try {
    final decoded = json.decode(body);
    final data = decoded is Map<String, dynamic>
        ? (decoded['data'] as List? ?? [])
        : (decoded is List ? decoded : []);
    return data
        .whereType<Map<String, dynamic>>()
        .map(Language.fromJson)
        .where((l) => l.code.isNotEmpty && l.name.isNotEmpty)
        .toList();
  } catch (_) {
    return [];
  }
}

/// Pure precedence decision: fetched (non-empty) → cached (non-empty) →
/// fallback. Extracted so the offline/degraded behavior is unit-testable
/// without network or SharedPreferences.
List<Language> resolveLanguageCatalog({
  List<Language>? fetched,
  List<Language>? cached,
  required List<Language> fallback,
}) {
  if (fetched != null && fetched.isNotEmpty) return fetched;
  if (cached != null && cached.isNotEmpty) return cached;
  return fallback;
}

final languagesProvider = FutureProvider<List<Language>>((ref) async {
  List<Language>? fetched;
  String? fetchedBody;

  try {
    final response = await http
        .get(Uri.parse('${Endpoints.baseURL}${Endpoints.languagesURL}'))
        .timeout(const Duration(seconds: 8));
    if (response.statusCode == 200) {
      final parsed = parseLanguageCatalog(response.body);
      if (parsed.isNotEmpty) {
        fetched = parsed;
        fetchedBody = response.body;
      }
    }
  } catch (_) {
    // fall through to cache/fallback
  }

  List<Language>? cached;
  try {
    final prefs = await SharedPreferences.getInstance();
    if (fetchedBody != null) {
      // Persist the fresh copy for future offline sessions.
      await prefs.setString(_kLanguagesCacheKey, fetchedBody);
    } else {
      final stored = prefs.getString(_kLanguagesCacheKey);
      if (stored != null) cached = parseLanguageCatalog(stored);
    }
  } catch (_) {
    // cache unavailable — fallback still covers us
  }

  final catalog = resolveLanguageCatalog(
    fetched: fetched,
    cached: cached,
    fallback: kLanguageCatalogFallback,
  );

  // Keep the sync view (FilterOptions.languages, moment-card labels) in
  // step with whatever we resolved.
  LanguageCatalog.update(catalog);

  return catalog;
});

/// Raw catalog NAMES — for the name-keyed surfaces (matching filter,
/// voice-room create/browse) that compare against stored display-name
/// values like "Portuguese (Brazil)". Variants deliberately NOT collapsed
/// here: users' native_language can literally be the variant string.
final languageNamesProvider = Provider<List<String>>((ref) {
  final async = ref.watch(languagesProvider);
  return async.maybeWhen(
    data: (catalog) => catalog.map((l) => l.name).toList(),
    orElse: () => kLanguageCatalogFallback.map((l) => l.name).toList(),
  );
});

/// Code-keyed picker list (base ISO 639-1, variants collapsed, sign
/// languages/Hawaiian excluded — see LanguageCodes.toBaseIso6391) for the
/// composer tag, feed filter, vocabulary and lesson-builder surfaces.
/// `{'code','name','flag'}` maps, ready for dropdowns.
final taggableLanguagesProvider = Provider<List<Map<String, String>>>((ref) {
  final async = ref.watch(languagesProvider);
  return async.maybeWhen(
    data: LanguageCodes.buildTaggableLanguages,
    orElse: () => LanguageCodes.buildTaggableLanguages(kLanguageCatalogFallback),
  );
});
