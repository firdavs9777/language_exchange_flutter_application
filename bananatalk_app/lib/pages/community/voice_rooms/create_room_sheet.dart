import 'package:flutter/material.dart';
import 'package:bananatalk_app/models/community/topic_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

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
  String _selectedTopic = 'Language Tips';
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
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a room title'),
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
      _selectedTopic,
      _selectedLanguage,
      _maxParticipants,
    );
    Navigator.pop(context);
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
            Padding(
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
                    child: Builder(
                      builder: (context) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create Voice Room',
                            style: context.titleLarge,
                          ),
                          Text(
                            'Start a live conversation',
                            style: context.bodyMedium.copyWith(
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      ),
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
            ),
            const Divider(height: 1),
            // Form
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Room title
                  const Text(
                    'Room Title',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Spacing.gapSM,
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: 'e.g., English Practice - Beginners Welcome!',
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
                  const Text(
                    'Topic',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Spacing.gapSM,
                  _buildTopicSelector(),
                  Spacing.gapLG,
                  // Language
                  const Text(
                    'Language',
                    style: TextStyle(
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
                      const Text(
                        'Max Participants',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$_maxParticipants people',
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
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.mic_rounded),
                          SizedBox(width: 8),
                          Text(
                            'Start Room',
                            style: TextStyle(
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

  Widget _buildTopicSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: Topic.defaultTopics.take(12).map((topic) {
        final isSelected = _selectedTopic == topic.name;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedTopic = topic.name;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF00BFA5).withOpacity(0.15)
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
