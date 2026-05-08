import 'package:flutter/material.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/utils/language_flags.dart';

/// Immutable data holder for a single active-filter chip.
class FilterChipData {
  final String label;
  final String key;
  const FilterChipData(this.label, this.key);
}

/// Horizontal scrolling row of active filter chips.
///
/// Shows one chip per active filter value and a "Clear" button that fires
/// [onClearAll]. Each chip's close icon fires [onRemove] with the filter key.
class CommunityFilterChips extends StatelessWidget {
  const CommunityFilterChips({
    super.key,
    required this.filters,
    required this.onRemove,
    required this.onClearAll,
  });

  final Map<String, dynamic> filters;
  final void Function(String key) onRemove;
  final VoidCallback onClearAll;

  /// Returns true when at least one filter differs from its default value.
  static bool hasActiveFilters(Map<String, dynamic> f) {
    return f['gender'] != null ||
        f['nativeLanguage'] != null ||
        f['learningLanguage'] != null ||
        f['country'] != null ||
        f['languageLevel'] != null ||
        (f['onlineOnly'] == true) ||
        (f['newUsersOnly'] == true) ||
        (f['minAge'] != null && (f['minAge'] as int) > 18) ||
        (f['maxAge'] != null && (f['maxAge'] as int) < 100);
  }

  List<FilterChipData> _buildChips(Map<String, dynamic> f) {
    final chips = <FilterChipData>[];

    if (f['nativeLanguage'] != null) {
      final lang = f['nativeLanguage'] as String;
      final flag = LanguageFlags.getFlagByName(lang);
      chips.add(FilterChipData('$flag $lang', 'nativeLanguage'));
    }
    if (f['learningLanguage'] != null) {
      final lang = f['learningLanguage'] as String;
      final flag = LanguageFlags.getFlagByName(lang);
      chips.add(FilterChipData('$flag $lang', 'learningLanguage'));
    }
    if (f['country'] != null) {
      chips.add(FilterChipData('📍 ${f['country']}', 'country'));
    }
    if (f['gender'] != null) {
      final g = f['gender'] as String;
      chips.add(FilterChipData(g == 'male' ? '♂ Male' : '♀ Female', 'gender'));
    }
    if (f['languageLevel'] != null) {
      chips.add(FilterChipData('🎯 ${f['languageLevel']}', 'languageLevel'));
    }
    if (f['onlineOnly'] == true) {
      chips.add(const FilterChipData('🟢 Online', 'onlineOnly'));
    }
    if (f['newUsersOnly'] == true) {
      chips.add(const FilterChipData('✨ New', 'newUsersOnly'));
    }
    if ((f['minAge'] as int?) != null && (f['minAge'] as int) > 18 ||
        (f['maxAge'] as int?) != null && (f['maxAge'] as int) < 100) {
      final min = f['minAge'] as int? ?? 18;
      final max = f['maxAge'] as int? ?? 100;
      chips.add(FilterChipData('$min-$max y/o', 'age'));
    }

    return chips;
  }

  @override
  Widget build(BuildContext context) {
    final chips = _buildChips(filters);
    if (chips.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: chips.map((chip) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: context.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: context.primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            chip.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: context.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => onRemove(chip.key),
                            child: Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: context.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onClearAll,
            child: Text(
              'Clear',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.red.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
