import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/services/poll_service.dart';

class CreatePollDialog extends StatefulWidget {
  final String conversationId;
  final String receiverId;
  final Function(Poll)? onPollCreated;

  const CreatePollDialog({
    Key? key,
    required this.conversationId,
    required this.receiverId,
    this.onPollCreated,
  }) : super(key: key);

  /// Show the create poll dialog
  static Future<Poll?> show({
    required BuildContext context,
    required String conversationId,
    required String receiverId,
    Function(Poll)? onPollCreated,
  }) {
    return showModalBottomSheet<Poll>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => CreatePollDialog(
        conversationId: conversationId,
        receiverId: receiverId,
        onPollCreated: onPollCreated,
      ),
    );
  }

  @override
  State<CreatePollDialog> createState() => _CreatePollDialogState();
}

class _CreatePollDialogState extends State<CreatePollDialog> {
  final _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  
  bool _isCreating = false;
  bool _allowMultipleVotes = false;
  bool _isAnonymous = false;
  bool _isQuiz = false;
  int? _correctOptionIndex;
  String? _explanation;
  int? _expiresInHours;
  
  final List<int> _expiryOptions = [1, 6, 12, 24, 48, 168]; // hours

  @override
  void dispose() {
    _questionController.dispose();
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_optionControllers.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 10 options allowed')),
      );
      return;
    }
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    if (_optionControllers.length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimum 2 options required')),
      );
      return;
    }
    setState(() {
      _optionControllers[index].dispose();
      _optionControllers.removeAt(index);
      if (_correctOptionIndex == index) {
        _correctOptionIndex = null;
      } else if (_correctOptionIndex != null && _correctOptionIndex! > index) {
        _correctOptionIndex = _correctOptionIndex! - 1;
      }
    });
  }

  bool _validate() {
    final question = _questionController.text.trim();
    if (question.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a question')),
      );
      return false;
    }

    final validOptions = _optionControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (validOptions.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least 2 options')),
      );
      return false;
    }

    if (_isQuiz && _correctOptionIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select the correct answer for quiz')),
      );
      return false;
    }

    return true;
  }

  Future<void> _createPoll() async {
    if (!_validate()) return;

    setState(() => _isCreating = true);

    try {
      final options = _optionControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      final settings = PollSettings(
        allowMultipleVotes: _allowMultipleVotes,
        isAnonymous: _isAnonymous,
        isQuiz: _isQuiz,
        correctOptionIndex: _correctOptionIndex,
        explanation: _explanation,
        showResultsBeforeVote: !_isQuiz,
      );

      final result = await PollService.createPoll(
        conversationId: widget.conversationId,
        receiverId: widget.receiverId,
        question: _questionController.text.trim(),
        options: options,
        settings: settings,
        expiresInHours: _expiresInHours,
      );

      if (mounted) {
        if (result['success'] == true && result['data'] != null) {
          final poll = result['data'] as Poll;
          widget.onPollCreated?.call(poll);
          Navigator.pop(context, poll);
        } else {
          setState(() => _isCreating = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Failed to create poll'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.poll),
                const SizedBox(width: 8),
                const Text(
                  'Create Poll',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _isCreating ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isCreating ? null : _createPoll,
                  child: _isCreating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create'),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                // Question
                TextField(
                  controller: _questionController,
                  decoration: const InputDecoration(
                    labelText: 'Question',
                    hintText: 'Ask a question...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  maxLength: 200,
                ),
                const SizedBox(height: 16),

                // Options
                const Text(
                  'Options',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ..._optionControllers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final controller = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        if (_isQuiz)
                          Radio<int>(
                            value: index,
                            groupValue: _correctOptionIndex,
                            onChanged: (value) {
                              setState(() => _correctOptionIndex = value);
                            },
                          ),
                        Expanded(
                          child: TextField(
                            controller: controller,
                            decoration: InputDecoration(
                              hintText: 'Option ${index + 1}',
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            maxLength: 100,
                          ),
                        ),
                        if (_optionControllers.length > 2)
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            color: Colors.red,
                            onPressed: () => _removeOption(index),
                          ),
                      ],
                    ),
                  );
                }),
                
                // Add option button
                if (_optionControllers.length < 10)
                  TextButton.icon(
                    onPressed: _addOption,
                    icon: const Icon(Icons.add),
                    label: const Text('Add option'),
                  ),

                const SizedBox(height: 24),

                // Settings
                const Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),

                // Quiz mode
                SwitchListTile(
                  title: const Text('Quiz mode'),
                  subtitle: const Text('One option is the correct answer'),
                  value: _isQuiz,
                  onChanged: (value) {
                    setState(() {
                      _isQuiz = value;
                      if (!value) {
                        _correctOptionIndex = null;
                        _explanation = null;
                      }
                    });
                  },
                ),

                // Quiz explanation
                if (_isQuiz)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Explanation (optional)',
                        hintText: 'Explain the correct answer',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      onChanged: (value) => _explanation = value,
                    ),
                  ),

                // Multiple votes
                SwitchListTile(
                  title: const Text('Allow multiple votes'),
                  subtitle: const Text('Users can vote for multiple options'),
                  value: _allowMultipleVotes,
                  onChanged: _isQuiz
                      ? null
                      : (value) {
                          setState(() => _allowMultipleVotes = value);
                        },
                ),

                // Anonymous
                SwitchListTile(
                  title: const Text('Anonymous voting'),
                  subtitle: const Text('Hide who voted for each option'),
                  value: _isAnonymous,
                  onChanged: (value) {
                    setState(() => _isAnonymous = value);
                  },
                ),

                // Expiry
                ListTile(
                  title: const Text('Poll expires'),
                  subtitle: Text(_expiresInHours == null
                      ? 'Never'
                      : _formatExpiry(_expiresInHours!)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showExpiryPicker,
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showExpiryPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Never'),
            trailing: _expiresInHours == null
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () {
              setState(() => _expiresInHours = null);
              Navigator.pop(context);
            },
          ),
          ..._expiryOptions.map((hours) => ListTile(
                title: Text(_formatExpiry(hours)),
                trailing: _expiresInHours == hours
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  setState(() => _expiresInHours = hours);
                  Navigator.pop(context);
                },
              )),
        ],
      ),
    );
  }

  String _formatExpiry(int hours) {
    if (hours < 24) {
      return '$hours hour${hours > 1 ? 's' : ''}';
    } else {
      final days = hours ~/ 24;
      return '$days day${days > 1 ? 's' : ''}';
    }
  }
}

