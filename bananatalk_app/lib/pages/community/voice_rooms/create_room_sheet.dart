import 'package:flutter/material.dart';
import 'package:bananatalk_app/models/community/topic_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

/// Create Room Bottom Sheet
class CreateRoomSheet extends StatefulWidget {
  final Function(String title, String topic, String language, int maxParticipants)
      onCreateRoom;

  const CreateRoomSheet({
    super.key,
    required this.onCreateRoom,
  });

  @override
  State<CreateRoomSheet> createState() => _CreateRoomSheetState();
}

class _CreateRoomSheetState extends State<CreateRoomSheet> {
  final _titleController = TextEditingController();
  String _selectedTopicId = 'language_exchange';
  String _selectedLanguage = 'English';
  int _maxParticipants = 8;

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
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseEnterRoomTitle),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.borderMD,
          ),
        ),
      );
      return;
    }

    widget.onCreateRoom(
      _titleController.text.trim(),
      _selectedTopicId,
      _selectedLanguage,
      _maxParticipants,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  color: Colors.grey[300],
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
                          backgroundColor: Colors.grey[100],
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
                      // Room title
                      Text(
                        l10n.roomTitle,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Spacing.gapSM,
                      TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: l10n.roomTitleHint,
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: AppRadius.borderMD,
                            borderSide: BorderSide.none,
                          ),
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
                              color: Colors.grey[600],
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
                  ? const Color(0xFF00BFA5).withValues(alpha:0.15)
                  : Colors.grey[100],
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
                        : Colors.grey[700],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: AppRadius.borderMD,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedLanguage,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          borderRadius: AppRadius.borderMD,
          items: _languages.map((language) {
            return DropdownMenuItem(
              value: language,
              child: Text(language),
            );
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
    );
  }
}
