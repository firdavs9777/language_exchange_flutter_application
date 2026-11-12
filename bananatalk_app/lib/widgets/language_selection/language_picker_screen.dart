import 'package:flutter/material.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/models/language_model.dart';
import 'package:bananatalk_app/utils/language_flags.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

/// Language Picker Screen with alphabetical organization and recommended section
class LanguagePickerScreen extends StatefulWidget {
  final List<Language> languages;
  final Language? selectedLanguage;

  const LanguagePickerScreen({
    Key? key,
    required this.languages,
    this.selectedLanguage,
  }) : super(key: key);

  @override
  State<LanguagePickerScreen> createState() => _LanguagePickerScreenState();
}

class _LanguagePickerScreenState extends State<LanguagePickerScreen> {
  List<Language> _filteredLanguages = [];
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Alphabet index for quick navigation
  final List<String> _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('');
  
  @override
  void initState() {
    super.initState();
    _filteredLanguages = _sortLanguagesAlphabetically(widget.languages);
    _searchController.addListener(_filterLanguages);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Sort languages alphabetically by name
  List<Language> _sortLanguagesAlphabetically(List<Language> languages) {
    final sorted = List<Language>.from(languages);
    sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return sorted;
  }

  /// Filter languages based on search query
  void _filterLanguages() {
    final query = _searchController.text.toLowerCase().trim();
    
    setState(() {
      if (query.isEmpty) {
        _filteredLanguages = _sortLanguagesAlphabetically(widget.languages);
      } else {
        _filteredLanguages = widget.languages.where((lang) {
          return lang.name.toLowerCase().contains(query) ||
                 lang.nativeName.toLowerCase().contains(query) ||
                 lang.code.toLowerCase().contains(query);
        }).toList();
        _filteredLanguages = _sortLanguagesAlphabetically(_filteredLanguages);
      }
    });
  }

  /// Get recommended languages
  List<Language> _getRecommendedLanguages() {
    final recommendedCodes = LanguageFlags.getRecommendedCodes();
    return widget.languages
        .where((lang) => recommendedCodes.contains(lang.code))
        .toList();
  }

  /// Scroll to letter section
  void _scrollToLetter(String letter) {
    final index = _filteredLanguages.indexWhere(
      (lang) => lang.name.toUpperCase().startsWith(letter),
    );
    
    if (index != -1) {
      // Calculate approximate position
      // 56.0 is the approximate height of each list item
      final position = (index * 56.0).toDouble();
      _scrollController.animateTo(
        position,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final recommendedLanguages = _getRecommendedLanguages();
    final showRecommended = _searchController.text.isEmpty;

    // Theme colours, not white/black: in dark mode this was a full white page.
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: context.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.selectLanguage,
          style: TextStyle(
            color: context.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.search,
                hintStyle: TextStyle(color: context.textHint),
                prefixIcon: Icon(Icons.search, color: context.textHint),
                filled: true,
                fillColor: context.containerColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // Scrollable List (Recommended + All Languages)
          Expanded(
            child: _filteredLanguages.isEmpty && !showRecommended
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: context.textMuted),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!.noLanguagesFound,
                          style: TextStyle(
                            fontSize: 16,
                            color: context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : Stack(
                    children: [
                      ListView(
                        controller: _scrollController,
                        children: [
                          // Recommended Section
                          if (showRecommended && recommendedLanguages.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  AppLocalizations.of(context)!.recommended,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: context.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                            ...recommendedLanguages.map((lang) => _buildLanguageTile(lang)),
                            const SizedBox(height: 8),
                            // Divider between recommended and all languages
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Divider(color: context.dividerColor),
                            ),
                          ],

                          // All Languages List
                          ...List.generate(_filteredLanguages.length, (index) {
                            final language = _filteredLanguages[index];
                            
                            // Show alphabet divider
                            final showDivider = index == 0 ||
                                language.name[0].toUpperCase() !=
                                    _filteredLanguages[index - 1].name[0].toUpperCase();
                            
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (showDivider)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                                    child: Text(
                                      language.name[0].toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: context.textSecondary,
                                      ),
                                    ),
                                  ),
                                _buildLanguageTile(language),
                              ],
                            );
                          }),
                        ],
                      ),
                      
                      // Alphabet Index Overlay (right side)
                      if (showRecommended && _filteredLanguages.length > 20)
                        Positioned(
                          right: 0,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: 24,
                            alignment: Alignment.centerRight,
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _alphabet.length,
                              itemBuilder: (context, index) {
                                final letter = _alphabet[index];
                                final hasLanguage = _filteredLanguages.any(
                                  (lang) => lang.name.toUpperCase().startsWith(letter),
                                );
                                
                                return GestureDetector(
                                  onTap: hasLanguage ? () => _scrollToLetter(letter) : null,
                                  child: Container(
                                    height: 20,
                                    alignment: Alignment.center,
                                    child: Text(
                                      letter,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: hasLanguage ? context.primaryColor : context.textMuted,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  /// Build individual language tile
  Widget _buildLanguageTile(Language language) {
    final isSelected = widget.selectedLanguage?.code == language.code;
    
    return InkWell(
      onTap: () => Navigator.pop(context, language),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? context.primaryColor.withValues(alpha: 0.1) : Colors.transparent,
        ),
        child: Row(
          children: [
            // Flag Emoji
            Text(
              language.flag,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 16),
            
            // Language Names
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    language.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    language.nativeName,
                    style: TextStyle(
                      fontSize: 14,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Selected Indicator
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: context.primaryColor,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

