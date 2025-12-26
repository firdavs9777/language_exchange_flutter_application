import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/services/translation_service.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

class TranslatedMessageWidget extends StatefulWidget {
  final String messageId;
  final String originalText;
  final List<MessageTranslation>? existingTranslations;
  final bool isFromMe;
  final VoidCallback? onTranslationAdded;

  const TranslatedMessageWidget({
    Key? key,
    required this.messageId,
    required this.originalText,
    this.existingTranslations,
    this.isFromMe = false,
    this.onTranslationAdded,
  }) : super(key: key);

  @override
  State<TranslatedMessageWidget> createState() => _TranslatedMessageWidgetState();
}

class _TranslatedMessageWidgetState extends State<TranslatedMessageWidget> {
  MessageTranslation? _activeTranslation;
  bool _isLoading = false;
  bool _showOriginal = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkExistingTranslations();
  }

  void _checkExistingTranslations() async {
    if (widget.existingTranslations?.isNotEmpty == true) {
      // Get preferred language
      final preferredLang = await TranslationService.getPreferredLanguage();
      if (preferredLang != null) {
        final existing = widget.existingTranslations!.firstWhere(
          (t) => t.language == preferredLang,
          orElse: () => widget.existingTranslations!.first,
        );
        setState(() {
          _activeTranslation = existing;
          _showOriginal = false;
        });
      }
    }
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
      final result = await TranslationService.translateMessage(
        messageId: widget.messageId,
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
          final l10n = AppLocalizations.of(context)!;
          final errorMsg = result['error']?.toString() ?? l10n.translationUnavailable;
          setState(() {
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
    final textColor = widget.isFromMe ? Colors.white : Colors.black87;
    final subtleColor = widget.isFromMe 
        ? Colors.white.withOpacity(0.7) 
        : Colors.grey[600];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main text
        Text(
          _showOriginal || _activeTranslation == null
              ? widget.originalText
              : _activeTranslation!.translatedText,
          style: TextStyle(color: textColor),
        ),

        // Translation controls
        if (_isLoading)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(subtleColor),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.translating,
                  style: TextStyle(fontSize: 12, color: subtleColor),
                ),
              ],
            ),
          )
        else if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _error!,
              style: TextStyle(fontSize: 12, color: Colors.red[300]),
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
                  Icon(
                    Icons.translate,
                    size: 14,
                    color: subtleColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _showOriginal
                        ? '${AppLocalizations.of(context)!.showTranslation} ${TranslationService.getLanguageName(_activeTranslation!.language)}'
                        : AppLocalizations.of(context)!.showOriginal,
                    style: TextStyle(
                      fontSize: 12,
                      color: subtleColor,
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
                  Icon(
                    Icons.translate,
                    size: 14,
                    color: subtleColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    AppLocalizations.of(context)!.translate,
                    style: TextStyle(
                      fontSize: 12,
                      color: subtleColor,
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

/// Quick translate button for message options
class TranslateButton extends StatelessWidget {
  final String messageId;
  final VoidCallback? onTranslated;

  const TranslateButton({
    Key? key,
    required this.messageId,
    this.onTranslated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.translate, size: 20),
      onPressed: () async {
        final preferredLang = await TranslationService.getPreferredLanguage();
        
        if (preferredLang != null) {
          // Translate directly to preferred language
          final result = await TranslationService.translateMessage(
            messageId: messageId,
            targetLanguage: preferredLang,
          );
          
          if (result['success'] == true) {
            onTranslated?.call();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Translated to ${TranslationService.getLanguageName(preferredLang)}',
                  ),
                ),
              );
            }
          }
        } else {
          // Show language selector
          if (context.mounted) {
            showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (context) => _LanguageSelectorSheet(
                onLanguageSelected: (code) async {
                  Navigator.pop(context);
                  await TranslationService.setPreferredLanguage(code);
                  
                  final result = await TranslationService.translateMessage(
                    messageId: messageId,
                    targetLanguage: code,
                  );
                  
                  if (result['success'] == true) {
                    onTranslated?.call();
                  }
                },
              ),
            );
          }
        }
      },
      tooltip: 'Translate',
    );
  }
}

