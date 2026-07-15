import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/pages/moments/filter/moment_filter_model.dart';
import 'package:bananatalk_app/providers/languages_provider.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

class FilterLanguageSection extends ConsumerStatefulWidget {
  final MomentFilter tempFilter;
  final ValueChanged<MomentFilter> onChanged;

  const FilterLanguageSection({
    super.key,
    required this.tempFilter,
    required this.onChanged,
  });

  @override
  ConsumerState<FilterLanguageSection> createState() =>
      _FilterLanguageSectionState();
}

class _FilterLanguageSectionState
    extends ConsumerState<FilterLanguageSection> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, String>> get _filteredLanguages {
    if (_query.isEmpty) return FilterOptions.languages;
    return FilterOptions.languages
        .where((lang) =>
            lang['name']!.toLowerCase().contains(_query.toLowerCase()) ||
            lang['code']!.toLowerCase().contains(_query.toLowerCase()))
        .toList();
  }

  void _toggleLanguage(String langCode) {
    final languages = List<String>.from(widget.tempFilter.languages);
    if (languages.contains(langCode)) {
      languages.remove(langCode);
    } else {
      languages.add(langCode);
    }
    widget.onChanged(widget.tempFilter.copyWith(languages: languages));
  }

  @override
  Widget build(BuildContext context) {
    // Trigger the shared-catalog fetch on first open and rebuild when it
    // lands — FilterOptions.languages then serves the full 110+ list
    // instead of its static fallback.
    ref.watch(languagesProvider);

    final colorScheme = Theme.of(context).colorScheme;
    final filteredLangs = _filteredLanguages;

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.searchLanguages,
              prefixIcon: Icon(Icons.search, color: context.textSecondary),
              filled: true,
              fillColor: colorScheme.surfaceVariant.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
            ),
          ),
        ),
        // Selected languages
        if (widget.tempFilter.languages.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.selected,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${widget.tempFilter.languages.length}',
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.tempFilter.languages.map((langCode) {
                    final langData = FilterOptions.languages.firstWhere(
                      (item) => item['code'] == langCode,
                      orElse: () =>
                          {'code': langCode, 'name': langCode, 'flag': '🌍'},
                    );
                    return Chip(
                      label: Text('${langData['flag']} ${langData['name']}'),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => _toggleLanguage(langCode),
                      backgroundColor:
                          colorScheme.primary.withValues(alpha: 0.1),
                      side: BorderSide(color: colorScheme.primary),
                      labelStyle: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Divider(color: colorScheme.outlineVariant),
              ],
            ),
          ),
        // Language list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredLangs.length,
            itemBuilder: (context, index) {
              final lang = filteredLangs[index];
              final isSelected =
                  widget.tempFilter.languages.contains(lang['code']);

              return ListTile(
                onTap: () => _toggleLanguage(lang['code']!),
                leading: Text(
                  lang['flag']!,
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(
                  lang['name']!,
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? colorScheme.primary
                        : context.textPrimary,
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.check_circle, color: colorScheme.primary)
                    : Icon(Icons.circle_outlined,
                        color: colorScheme.outlineVariant),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: isSelected
                    ? colorScheme.primary.withValues(alpha: 0.05)
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }
}
