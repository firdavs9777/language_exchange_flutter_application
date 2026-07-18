import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/room.dart';
import 'package:bananatalk_app/pages/community/widgets/community_snackbar.dart';
import 'package:bananatalk_app/providers/rooms_provider.dart';
import 'package:bananatalk_app/providers/voice_room_languages_provider.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Shows the "New Topic Room" bottom sheet and returns the newly created
/// [Room] on success (caller decides what to do with it — refresh the
/// directory, navigate into it, etc.), or `null` if the sheet was dismissed
/// or the create call failed.
Future<Room?> showCreateTopicRoomSheet(
  BuildContext context, {
  String? presetLanguage,
}) {
  return showModalBottomSheet<Room?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CreateTopicRoomSheet(presetLanguage: presetLanguage),
  );
}

/// Bottom sheet for creating a user-owned topic room nested under a
/// target-language hub. Mirrors the visual language of
/// `voice_rooms/create_room_sheet.dart` (rounded top sheet, gradient header
/// icon, pill inputs) but is a much shorter form — a topic room is just a
/// title + target language + optional description, created via
/// `RoomApiClient.createRoom`.
class CreateTopicRoomSheet extends ConsumerStatefulWidget {
  const CreateTopicRoomSheet({super.key, this.presetLanguage});

  /// Pre-selected target language (e.g. the caller's learning language),
  /// used to save the user a tap. Falls back to 'English' if omitted/empty.
  final String? presetLanguage;

  @override
  ConsumerState<CreateTopicRoomSheet> createState() =>
      _CreateTopicRoomSheetState();
}

class _CreateTopicRoomSheetState extends ConsumerState<CreateTopicRoomSheet> {
  static const int _titleMaxLength = 60;
  static const int _descriptionMaxLength = 140;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  late String _selectedLanguage =
      (widget.presetLanguage != null && widget.presetLanguage!.isNotEmpty)
          ? widget.presetLanguage!
          : 'English';

  String? _titleError;
  bool _isSubmitting = false;

  /// "English" is ambiguous (UK vs US). When the selected language is English,
  /// the creator picks the flag variant; default to 🇺🇸 so English rooms aren't
  /// locked to the British flag. Only used when [_isEnglish].
  String _englishFlag = '🇺🇸';

  bool get _isEnglish => _selectedLanguage.toLowerCase().contains('english');

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = AppLocalizations.of(context)!.roomNameRequired);
      return;
    }

    setState(() {
      _titleError = null;
      _isSubmitting = true;
    });

    final description = _descriptionController.text.trim();
    final room = await ref.read(roomApiClientProvider).createRoom(
          title: title,
          targetLanguage: _selectedLanguage,
          description: description.isEmpty ? null : description,
          // Store the chosen UK/US flag for English; other languages derive
          // their flag from the language name client-side.
          emojiFlag: _isEnglish ? _englishFlag : null,
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (room != null) {
      Navigator.of(context).pop(room);
    } else {
      showCommunitySnackBar(
        context,
        message: AppLocalizations.of(context)!.roomCreateError,
        type: CommunitySnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2196F3), Color(0xFF00BCD4)],
                      ),
                      borderRadius: AppRadius.borderMD,
                    ),
                    child: const Icon(
                      Icons.forum_rounded,
                      color: Colors.white,
                    ),
                  ),
                  Spacing.hGapMD,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.roomCreateTitle, style: context.titleLarge),
                        Text(
                          l10n.roomCreateSubtitle,
                          style: context.bodyMedium.copyWith(
                            color: context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: context.containerColor,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Form
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Room name (* required)
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: l10n.roomNameLabel),
                        const TextSpan(
                          text: ' *',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Spacing.gapSM,
                  TextField(
                    controller: _titleController,
                    enabled: !_isSubmitting,
                    onChanged: (_) {
                      if (_titleError != null) {
                        setState(() => _titleError = null);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: l10n.roomNameHint,
                      filled: true,
                      fillColor: context.containerColor,
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.borderMD,
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppRadius.borderMD,
                        borderSide: _titleError != null
                            ? const BorderSide(color: Colors.red, width: 1.5)
                            : BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppRadius.borderMD,
                        borderSide: BorderSide(
                          color: _titleError != null
                              ? Colors.red
                              : const Color(0xFF00BCD4),
                          width: 1.5,
                        ),
                      ),
                      errorText: _titleError,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    maxLength: _titleMaxLength,
                  ),
                  Spacing.gapMD,
                  // Language
                  Text(
                    l10n.language,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  Spacing.gapSM,
                  _buildLanguageSelector(l10n),
                  Spacing.gapMD,
                  // Description (optional)
                  Text(
                    l10n.roomDescriptionLabel,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  Spacing.gapSM,
                  TextField(
                    controller: _descriptionController,
                    enabled: !_isSubmitting,
                    maxLines: 2,
                    maxLength: _descriptionMaxLength,
                    decoration: InputDecoration(
                      hintText: l10n.roomDescriptionHint,
                      filled: true,
                      fillColor: context.containerColor,
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.borderMD,
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  Spacing.gapSM,
                  // Create button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00BCD4),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.borderMD,
                        ),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_rounded),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.roomCreateSubmit,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(AppLocalizations l10n) {
    // Full shared catalog (fetch-once, cached); fallback while loading. The
    // current selection is kept in the item list even if the catalog
    // doesn't contain it (DropdownButton requires value ∈ items).
    final catalogNames = ref.watch(voiceRoomLanguagesProvider).maybeWhen(
          data: (names) => names,
          orElse: () => kVoiceRoomLanguagesFallback,
        );
    final languages = catalogNames.contains(_selectedLanguage)
        ? catalogNames
        : [_selectedLanguage, ...catalogNames];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: context.containerColor,
            borderRadius: AppRadius.borderMD,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedLanguage,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              borderRadius: AppRadius.borderMD,
              items: languages
                  .map(
                    (language) => DropdownMenuItem(
                        value: language, child: Text(language)),
                  )
                  .toList(),
              onChanged: _isSubmitting
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => _selectedLanguage = value);
                      }
                    },
            ),
          ),
        ),
        // English is UK/US ambiguous — let the creator choose which flag.
        if (_isEnglish) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _EnglishFlagChoice(
                  label: '🇺🇸 ${l10n.roomUsEnglish}',
                  selected: _englishFlag == '🇺🇸',
                  onTap: _isSubmitting
                      ? null
                      : () => setState(() => _englishFlag = '🇺🇸'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _EnglishFlagChoice(
                  label: '🇬🇧 ${l10n.roomUkEnglish}',
                  selected: _englishFlag == '🇬🇧',
                  onTap: _isSubmitting
                      ? null
                      : () => setState(() => _englishFlag = '🇬🇧'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// A small selectable pill for the US/UK English flag choice.
class _EnglishFlagChoice extends StatelessWidget {
  const _EnglishFlagChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.borderMD,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.12)
              : context.containerColor,
          borderRadius: AppRadius.borderMD,
          border: Border.all(
            color: selected ? AppColors.primary : context.dividerColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: context.bodyMedium.copyWith(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.primary : context.textPrimary,
          ),
        ),
      ),
    );
  }
}
