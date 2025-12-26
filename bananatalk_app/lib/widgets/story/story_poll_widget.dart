import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';

/// Interactive poll widget for stories
class StoryPollWidget extends StatefulWidget {
  final StoryPoll poll;
  final bool isOwner;
  final Function(int)? onVote;

  const StoryPollWidget({
    Key? key,
    required this.poll,
    this.isOwner = false,
    this.onVote,
  }) : super(key: key);

  @override
  State<StoryPollWidget> createState() => _StoryPollWidgetState();
}

class _StoryPollWidgetState extends State<StoryPollWidget> with SingleTickerProviderStateMixin {
  int? _selectedIndex;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.poll.userVoteIndex;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool get _hasVoted => _selectedIndex != null || widget.poll.hasUserVoted;

  void _vote(int index) {
    if (_hasVoted) return;
    setState(() => _selectedIndex = index);
    _animationController.forward();
    widget.onVote?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.poll.question,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ...widget.poll.options.asMap().entries.map((entry) {
            final option = entry.value;
            final isSelected = _selectedIndex == entry.key || option.voted;
            
            return _PollOptionItem(
              option: option,
              isSelected: isSelected,
              hasVoted: _hasVoted,
              animation: _animation,
              onTap: () => _vote(entry.key),
            );
          }),
          if (_hasVoted || widget.isOwner) ...[
            const SizedBox(height: 12),
            Text(
              '${widget.poll.totalVotes} votes',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PollOptionItem extends StatelessWidget {
  final StoryPollOption option;
  final bool isSelected;
  final bool hasVoted;
  final Animation<double> animation;
  final VoidCallback onTap;

  const _PollOptionItem({
    required this.option,
    required this.isSelected,
    required this.hasVoted,
    required this.animation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: hasVoted ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 48,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withOpacity(0.25) : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Stack(
            children: [
              if (hasVoted)
                AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    return FractionallySizedBox(
                      widthFactor: (option.percentage / 100) * animation.value,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? Colors.white.withOpacity(0.3)
                              : Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    );
                  },
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        option.text,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (hasVoted)
                      Text(
                        '${option.percentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Create poll dialog for story creation
class CreateStoryPollDialog extends StatefulWidget {
  final Function(StoryPoll) onPollCreated;

  const CreateStoryPollDialog({Key? key, required this.onPollCreated}) : super(key: key);

  @override
  State<CreateStoryPollDialog> createState() => _CreateStoryPollDialogState();
}

class _CreateStoryPollDialogState extends State<CreateStoryPollDialog> {
  final _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  bool _isAnonymous = false;

  @override
  void dispose() {
    _questionController.dispose();
    for (var c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_optionControllers.length < 4) {
      setState(() => _optionControllers.add(TextEditingController()));
    }
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        _optionControllers[index].dispose();
        _optionControllers.removeAt(index);
      });
    }
  }

  void _createPoll() {
    final question = _questionController.text.trim();
    final options = _optionControllers
        .map((c) => c.text.trim())
        .where((o) => o.isNotEmpty)
        .toList();

    if (question.isEmpty || options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a question and at least 2 options')),
      );
      return;
    }

    widget.onPollCreated(StoryPoll(
      question: question,
      options: options.asMap().entries.map((e) => 
        StoryPollOption(index: e.key, text: e.value)
      ).toList(),
      isAnonymous: _isAnonymous,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create Poll',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _questionController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Ask a question...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ..._optionControllers.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: entry.value,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Option ${entry.key + 1}',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          filled: true,
                          fillColor: Colors.grey[800],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    if (_optionControllers.length > 2)
                      IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () => _removeOption(entry.key),
                      ),
                  ],
                ),
              );
            }),
            if (_optionControllers.length < 4)
              TextButton.icon(
                onPressed: _addOption,
                icon: const Icon(Icons.add, color: Colors.blue),
                label: const Text('Add option', style: TextStyle(color: Colors.blue)),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Checkbox(
                  value: _isAnonymous,
                  onChanged: (v) => setState(() => _isAnonymous = v ?? false),
                  checkColor: Colors.black,
                  fillColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected) 
                        ? Colors.white 
                        : Colors.grey[700],
                  ),
                ),
                const Text('Anonymous voting', style: TextStyle(color: Colors.white)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _createPoll,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('Create'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

