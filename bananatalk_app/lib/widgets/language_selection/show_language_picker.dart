import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:bananatalk_app/models/language_model.dart';
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:bananatalk_app/services/translation_service.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/widgets/language_selection/language_picker_screen.dart';

/// Process-lifetime cache of the backend's `/languages` payload, so we
/// don't refetch the 127-language list every time a picker opens.
List<Language>? _cachedLanguages;

/// Open the full LanguagePickerScreen (search + recommended + 127 langs)
/// and return the user's pick. Falls back to TranslationService's static
/// 44-language list when the backend fetch fails so the picker is always
/// usable. Returns null if the user backed out.
Future<Language?> showLanguagePickerSheet(
  BuildContext context, {
  String? currentCode,
}) async {
  final languages = await _loadLanguages();
  if (languages.isEmpty || !context.mounted) return null;

  final selected = currentCode == null
      ? null
      : languages.firstWhere(
          (l) => l.code == currentCode,
          orElse: () => languages.first,
        );

  return Navigator.of(context).push<Language>(
    AppPageRoute(
      builder: (_) => LanguagePickerScreen(
        languages: languages,
        selectedLanguage: selected,
      ),
    ),
  );
}

Future<List<Language>> _loadLanguages() async {
  final cached = _cachedLanguages;
  if (cached != null && cached.isNotEmpty) return cached;
  try {
    final response = await http.get(
      Uri.parse('${Endpoints.baseURL}${Endpoints.languagesURL}'),
    );
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final List<dynamic> list = decoded['data'] ?? [];
      final parsed = list.map<Language>((j) => Language.fromJson(j)).toList();
      if (parsed.isNotEmpty) {
        _cachedLanguages = parsed;
        return parsed;
      }
    }
  } catch (_) {
    // best-effort
  }
  // Fall back to the hardcoded 44-language list so the picker still works
  // offline / when the backend is hiccuping.
  final fallback = TranslationService.supportedLanguages
      .map((m) => Language(
            id: m['code'] ?? '',
            code: m['code'] ?? '',
            name: m['name'] ?? '',
            nativeName: m['name'] ?? '',
            backendFlag: m['flag'],
          ))
      .toList();
  return fallback;
}
