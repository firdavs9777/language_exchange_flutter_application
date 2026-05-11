import 'package:flutter/material.dart';
import 'package:bananatalk_app/models/community/topic_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/community/widgets/community_snackbar.dart';

/// Create Room Bottom Sheet
class CreateRoomSheet extends StatefulWidget {
  final Future<void> Function(
    String title,
    String topic,
    String language,
    int maxParticipants,
    DateTime? scheduledFor,
    String? category,
  ) onCreateRoom;

  const CreateRoomSheet({super.key, required this.onCreateRoom});

  @override
  State<CreateRoomSheet> createState() => _CreateRoomSheetState();
}

class _CreateRoomSheetState extends State<CreateRoomSheet> {
  final _titleController = TextEditingController();
  String _selectedTopicId = 'language_exchange';
  String _selectedLanguage = 'English';
  int _maxParticipants = 8;
  bool _isScheduled = false;
  DateTime? _scheduledFor;
  String? _category;

  // Inline validation state — cleared as user corrects the field.
  String? _titleError;
  String? _categoryError;

  final List<String> _languages = [
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

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _createRoom() {
    final l10n = AppLocalizations.of(context)!;
    final titleEmpty = _titleController.text.trim().isEmpty;
    final categoryEmpty = _category == null;

    if (titleEmpty || categoryEmpty) {
      setState(() {
        _titleError = titleEmpty ? l10n.pleaseEnterRoomTitle : null;
        _categoryError = categoryEmpty ? 'Please pick a category' : null;
      });
      // Toast the first missing field for visibility on screens that
      // scroll the form below the fold.
      showCommunitySnackBar(
        context,
        message: titleEmpty
            ? l10n.pleaseEnterRoomTitle
            : 'Please pick a category',
        type: CommunitySnackBarType.error,
      );
      return;
    }

    widget.onCreateRoom(
      _titleController.text.trim(),
      _selectedTopicId,
      _selectedLanguage,
      _maxParticipants,
      _isScheduled ? _scheduledFor : null,
      _category,
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _scheduledFor ?? now.add(const Duration(hours: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? initial : now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _scheduledFor = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _scheduledFor?.hour ?? now.hour,
          _scheduledFor?.minute ?? now.minute,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    if (_scheduledFor == null) return;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledFor!),
    );
    if (picked != null) {
      final rounded = picked.minute - (picked.minute % 15);
      setState(() {
        _scheduledFor = DateTime(
          _scheduledFor!.year,
          _scheduledFor!.month,
          _scheduledFor!.day,
          picked.hour,
          rounded,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
                          ),
                          borderRadius: AppRadius.borderMD,
                        ),
                        child: const Icon(
                          Icons.mic_rounded,
                          color: Colors.white,
                        ),
                      ),
                      Spacing.hGapMD,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.createVoiceRoom,
                              style: context.titleLarge,
                            ),
                            Text(
                              l10n.startLiveConversation,
                              style: context.bodyMedium.copyWith(
                                color: context.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: context.containerColor,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const Divider(height: 1),
            // Form
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Room title (* required)
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: l10n.roomTitle),
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
                        onChanged: (_) {
                          if (_titleError != null) {
                            setState(() => _titleError = null);
                          }
                        },
                        decoration: InputDecoration(
                          hintText: l10n.roomTitleHint,
                          filled: true,
                          fillColor: context.containerColor,
                          border: OutlineInputBorder(
                            borderRadius: AppRadius.borderMD,
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: AppRadius.borderMD,
                            borderSide: _titleError != null
                                ? const BorderSide(
                                    color: Colors.red,
                                    width: 1.5,
                                  )
                                : BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: AppRadius.borderMD,
                            borderSide: BorderSide(
                              color: _titleError != null
                                  ? Colors.red
                                  : const Color(0xFF00BFA5),
                              width: 1.5,
                            ),
                          ),
                          errorText: _titleError,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        maxLength: 50,
                      ),
                      Spacing.gapMD,
                      // Topic
                      Text(
                        l10n.roomTopic,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Spacing.gapSM,
                      _buildTopicSelector(),
                      Spacing.gapLG,
                      // Language
                      Text(
                        l10n.roomLanguage,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Spacing.gapSM,
                      _buildLanguageSelector(),
                      Spacing.gapLG,
                      // Max participants
                      Row(
                        children: [
                          Text(
                            l10n.maxParticipants,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            l10n.nPeople(_maxParticipants),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Spacing.gapSM,
                      Slider(
                        value: _maxParticipants.toDouble(),
                        min: 2,
                        max: 20,
                        divisions: 18,
                        activeColor: const Color(0xFF00BFA5),
                        onChanged: (value) {
                          setState(() {
                            _maxParticipants = value.toInt();
                          });
                        },
                      ),
                      Spacing.gapLG,
                      // Schedule for later
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.scheduleForLater),
                        value: _isScheduled,
                        onChanged: (v) => setState(() {
                          _isScheduled = v;
                          if (!v) _scheduledFor = null;
                        }),
                        activeThumbColor: AppColors.primary,
                      ),
                      if (_isScheduled) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                ),
                                label: Text(
                                  _scheduledFor == null
                                      ? l10n.pickDate
                                      : '${_scheduledFor!.year}-${_scheduledFor!.month.toString().padLeft(2, '0')}-${_scheduledFor!.day.toString().padLeft(2, '0')}',
                                ),
                                onPressed: _pickDate,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(
                                  Icons.access_time,
                                  size: 16,
                                ),
                                label: Text(
                                  _scheduledFor == null
                                      ? l10n.pickTime
                                      : '${_scheduledFor!.hour.toString().padLeft(2, '0')}:${_scheduledFor!.minute.toString().padLeft(2, '0')}',
                                ),
                                onPressed:
                                    _scheduledFor == null ? null : _pickTime,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      // Category picker
                      DropdownButtonFormField<String?>(
                        decoration: InputDecoration(
                          labelText: '${l10n.pickCategory} *',
                          border: OutlineInputBorder(
                            borderRadius: AppRadius.borderMD,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: AppRadius.borderMD,
                            borderSide: _categoryError != null
                                ? const BorderSide(
                                    color: Colors.red,
                                    width: 1.5,
                                  )
                                : const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: AppRadius.borderMD,
                            borderSide: BorderSide(
                              color: _categoryError != null
                                  ? Colors.red
                                  : const Color(0xFF00BFA5),
                              width: 1.5,
                            ),
                          ),
                          errorText: _categoryError,
                        ),
                        initialValue: _category,
                        items: [
                          DropdownMenuItem(
                            value: 'casual',
                            child: Text(l10n.categoryCasual),
                          ),
                          DropdownMenuItem(
                            value: 'language_practice',
                            child: Text(l10n.categoryLanguagePractice),
                          ),
                          DropdownMenuItem(
                            value: 'topic',
                            child: Text(l10n.categoryTopic),
                          ),
                          DropdownMenuItem(
                            value: 'qa',
                            child: Text(l10n.categoryQA),
                          ),
                        ],
                        onChanged: (v) => setState(() {
                          _category = v;
                          if (_categoryError != null) _categoryError = null;
                        }),
                      ),
                      const SizedBox(height: 16),
                      // Create button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _createRoom,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00BFA5),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.borderMD,
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.mic_rounded),
                              const SizedBox(width: 8),
                              Text(
                                l10n.startRoom,
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
                );
              },
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: Topic.defaultTopics.take(12).map((topic) {
        final isSelected = _selectedTopicId == topic.id;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedTopicId = topic.id;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF00BFA5).withValues(alpha: 0.15)
                  : context.containerColor,
              borderRadius: AppRadius.borderLG,
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF00BFA5)
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(topic.icon, style: const TextStyle(fontSize: 16)),
                Spacing.hGapSM,
                Text(
                  topic.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFF00BFA5)
                        : context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLanguageSelector() {
    return Builder(
      builder: (context) => Container(
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
            items: _languages.map((language) {
              return DropdownMenuItem(value: language, child: Text(language));
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedLanguage = value;
                });
              }
            },
          ),
        ),
      ),
    );
  }
}
