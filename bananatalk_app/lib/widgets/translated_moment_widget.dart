import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/services/translation_service.dart';
import 'package:bananatalk_app/services/language_service.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class TranslatedMomentWidget extends StatefulWidget {
  final String momentId;
  final String originalText;
  final String? originalLanguage;
  final List<MessageTranslation>? existingTranslations;
  final VoidCallback? onTranslationAdded;

  const TranslatedMomentWidget({
    Key? key,
    required this.momentId,
    required this.originalText,
    this.originalLanguage,
    this.existingTranslations,
    this.onTranslationAdded,
  }) : super(key: key);

  @override
  State<TranslatedMomentWidget> createState() => _TranslatedMomentWidgetState();
}

class _TranslatedMomentWidgetState extends State<TranslatedMomentWidget> {
  MessageTranslation? _activeTranslation;
  bool _isLoading = false;
  bool _showOriginal = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkExistingTranslations();
    _tryAutoTranslate();
  }

  void _checkExistingTranslations() async {
    if (widget.existingTranslations?.isNotEmpty == true) {
      final preferredLang = await TranslationService.getPreferredLanguage();
      final targetLang = preferredLang ?? await TranslationService.getAutoTranslateLanguage();
      
      final existing = widget.existingTranslations!.firstWhere(
        (t) => t.language == targetLang,
        orElse: () => widget.existingTranslations!.first,
      );
      
      if (mounted) {
        setState(() {
          _activeTranslation = existing;
          _showOriginal = existing.language != targetLang;
        });
      }
    }
  }

  Future<void> _tryAutoTranslate() async {
    // Check if auto-translate is enabled for moments
    final shouldAuto = await TranslationService.shouldAutoTranslate('moments');
    if (!shouldAuto) return;

    // Check if original language is different from device language
    final deviceLang = LanguageService.getDeviceLanguage();
    if (widget.originalLanguage != null && 
        widget.originalLanguage!.toLowerCase() == deviceLang.toLowerCase()) {
      return; // Same language, no need to translate
    }

    // Check if translation already exists
    if (widget.existingTranslations?.isNotEmpty == true) {
      final existing = widget.existingTranslations!.firstWhere(
        (t) => t.language == deviceLang,
        orElse: () => MessageTranslation(
          language: '',
          translatedText: '',
          translatedAt: '',
        ),
      );
      
      if (existing.language == deviceLang) {
        if (mounted) {
          setState(() {
            _activeTranslation = existing;
            _showOriginal = false;
          });
        }
        return;
      }
    }

    // Auto-translate to device language
    await _translateTo(deviceLang);
  }

  Future<void> _translateTo(String languageCode) async {
    // Check if already translated
    final existing = widget.existingTranslations?.firstWhere(
      (t) => t.language == languageCode,
      orElse: () => MessageTranslation(
        language: '',
        translatedText: '',
        translatedAt: '',
      ),
    );

    if (existing?.language == languageCode) {
      setState(() {
        _activeTranslation = existing;
        _showOriginal = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await TranslationService.translateMoment(
        momentId: widget.momentId,
        targetLanguage: languageCode,
      );

      if (mounted) {
        if (result['success'] == true) {
          setState(() {
            _activeTranslation = result['data'] as MessageTranslation;
            _showOriginal = false;
            _isLoading = false;
          });
          widget.onTranslationAdded?.call();
        } else {
          setState(() {
            // Show user-friendly error message instead of technical API errors
            final l10n = AppLocalizations.of(context)!;
            final errorMsg = result['error']?.toString() ?? l10n.translationUnavailable;
            if (errorMsg.contains('API key') || errorMsg.contains('libretranslate')) {
              _error = l10n.translationServiceBeingConfigured;
            } else {
              _error = l10n.translationUnavailable;
            }
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _error = l10n.translationUnavailable;
          _isLoading = false;
        });
      }
    }
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _LanguageSelectorSheet(
        onLanguageSelected: (code) {
          Navigator.pop(context);
          _translateTo(code);
        },
      ),
    );
  }

  void _toggleView() {
    setState(() {
      _showOriginal = !_showOriginal;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main text
        Text(
          _showOriginal || _activeTranslation == null
              ? widget.originalText
              : _activeTranslation!.translatedText,
          style: const TextStyle(fontSize: 16),
        ),

        // Translation controls
        if (_isLoading)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.translating,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          )
        else if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    _error!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          )
        else if (_activeTranslation != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: GestureDetector(
              onTap: _toggleView,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.translate, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _showOriginal
                        ? '${AppLocalizations.of(context)!.showTranslation} ${TranslationService.getLanguageName(_activeTranslation!.language)}'
                        : AppLocalizations.of(context)!.showOriginal,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          // Translate button
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: GestureDetector(
              onTap: _showLanguageSelector,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.translate, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    AppLocalizations.of(context)!.translate,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _LanguageSelectorSheet extends StatelessWidget {
  final Function(String) onLanguageSelected;

  const _LanguageSelectorSheet({
    required this.onLanguageSelected,
  });

  @override
  Widget build(BuildContext context) {
    final languages = TranslationService.supportedLanguages;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.translate),
                const SizedBox(width: 8),
                Text(
                  '${AppLocalizations.of(context)!.translate} ${AppLocalizations.of(context)!.to}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(),
          SizedBox(
            height: 300,
            child: ListView.builder(
              itemCount: languages.length,
              itemBuilder: (context, index) {
                final lang = languages[index];
                return ListTile(
                  leading: Text(
                    lang['flag']!,
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(lang['name']!),
                  subtitle: Text(lang['code']!.toUpperCase()),
                  onTap: () => onLanguageSelected(lang['code']!),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

