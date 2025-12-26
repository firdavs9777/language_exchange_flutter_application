import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/services/poll_service.dart';
import 'package:intl/intl.dart';

class PollWidget extends StatefulWidget {
  final Poll poll;
  final String currentUserId;
  final bool isFromMe;
  final VoidCallback? onVoted;
  final VoidCallback? onClosed;

  const PollWidget({
    Key? key,
    required this.poll,
    required this.currentUserId,
    this.isFromMe = false,
    this.onVoted,
    this.onClosed,
  }) : super(key: key);

  @override
  State<PollWidget> createState() => _PollWidgetState();
}

class _PollWidgetState extends State<PollWidget> {
  late Poll _poll;
  bool _isVoting = false;
  int? _selectedOption;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _poll = widget.poll;
    _selectedOption = _poll.getUserVoteIndex(widget.currentUserId);
    _showResults = _selectedOption != null || 
                   _poll.status != 'active' ||
                   _poll.settings.showResultsBeforeVote;
  }

  @override
  void didUpdateWidget(PollWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.poll.id != widget.poll.id) {
      _poll = widget.poll;
      _selectedOption = _poll.getUserVoteIndex(widget.currentUserId);
      _showResults = _selectedOption != null || 
                     _poll.status != 'active' ||
                     _poll.settings.showResultsBeforeVote;
    }
  }

  Future<void> _vote(int optionIndex) async {
    if (_isVoting || _poll.status != 'active') return;
    if (_selectedOption != null && !_poll.settings.allowMultipleVotes) return;

    setState(() {
      _isVoting = true;
      _selectedOption = optionIndex;
    });

    try {
      final result = await PollService.votePoll(
        pollId: _poll.id,
        optionIndex: optionIndex,
      );

      if (mounted) {
        if (result['success'] == true && result['data'] != null) {
          setState(() {
            _poll = result['data'] as Poll;
            _showResults = true;
            _isVoting = false;
          });
          widget.onVoted?.call();
        } else {
          setState(() {
            _selectedOption = null;
            _isVoting = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Failed to vote'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _selectedOption = null;
          _isVoting = false;
        });
      }
    }
  }

  Future<void> _closePoll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Poll?'),
        content: const Text('No more votes will be accepted after closing.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Close'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final result = await PollService.closePoll(pollId: _poll.id);

      if (mounted) {
        if (result['success'] == true && result['data'] != null) {
          setState(() {
            _poll = result['data'] as Poll;
          });
          widget.onClosed?.call();
        }
      }
    } catch (e) {
      // Ignore errors
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isFromMe ? Colors.white : Colors.black87;
    final subtleColor = widget.isFromMe 
        ? Colors.white.withOpacity(0.7) 
        : Colors.grey[600];
    final accentColor = widget.isFromMe 
        ? Colors.white 
        : Theme.of(context).primaryColor;

    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poll icon and status
          Row(
            children: [
              Icon(Icons.poll, size: 16, color: subtleColor),
              const SizedBox(width: 4),
              Text(
                'Poll',
                style: TextStyle(
                  fontSize: 12,
                  color: subtleColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (_poll.status != 'active')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _poll.status == 'closed' ? 'Closed' : 'Expired',
                    style: TextStyle(
                      fontSize: 10,
                      color: subtleColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Question
          Text(
            _poll.question,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),

          // Options
          ..._poll.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            return _buildOption(
              index: index,
              option: option,
              textColor: textColor,
              accentColor: accentColor,
              subtleColor: subtleColor!,
            );
          }),

          const SizedBox(height: 8),

          // Footer
          Row(
            children: [
              Text(
                '${_poll.uniqueVoters} vote${_poll.uniqueVoters != 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  color: subtleColor,
                ),
              ),
              if (_poll.expiresAt != null) ...[
                Text(' • ', style: TextStyle(color: subtleColor)),
                Text(
                  _formatExpiry(_poll.expiresAt!),
                  style: TextStyle(
                    fontSize: 12,
                    color: subtleColor,
                  ),
                ),
              ],
              const Spacer(),
              // Close button for creator
              if (_poll.status == 'active' && 
                  _poll.creator.id == widget.currentUserId)
                GestureDetector(
                  onTap: _closePoll,
                  child: Text(
                    'Close poll',
                    style: TextStyle(
                      fontSize: 12,
                      color: accentColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),

          // Quiz result
          if (_poll.settings.isQuiz && _showResults && _selectedOption != null)
            _buildQuizResult(textColor),
        ],
      ),
    );
  }

  Widget _buildOption({
    required int index,
    required PollOption option,
    required Color textColor,
    required Color accentColor,
    required Color subtleColor,
  }) {
    final isSelected = _selectedOption == index;
    final percentage = _showResults 
        ? option.getPercentage(_poll.totalVotes)
        : 0.0;
    final isActive = _poll.status == 'active';
    final canVote = isActive && 
        (_selectedOption == null || _poll.settings.allowMultipleVotes);

    return GestureDetector(
      onTap: canVote && !_isVoting ? () => _vote(index) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: Stack(
          children: [
            // Background progress bar
            if (_showResults)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: widget.isFromMe
                        ? Colors.white.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation(
                      isSelected
                          ? accentColor.withOpacity(0.3)
                          : (widget.isFromMe
                              ? Colors.white.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.2)),
                    ),
                  ),
                ),
              ),
            
            // Option content
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected
                      ? accentColor
                      : (widget.isFromMe
                          ? Colors.white.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.3)),
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  // Selection indicator
                  if (_selectedOption == null && isActive)
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.isFromMe
                              ? Colors.white.withOpacity(0.5)
                              : Colors.grey.withOpacity(0.5),
                        ),
                      ),
                    )
                  else if (isSelected)
                    Icon(
                      Icons.check_circle,
                      size: 20,
                      color: accentColor,
                    )
                  else
                    const SizedBox(width: 20),
                    
                  const SizedBox(width: 8),
                  
                  // Option text
                  Expanded(
                    child: Text(
                      option.text,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                  
                  // Percentage
                  if (_showResults)
                    Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: isSelected ? accentColor : subtleColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    
                  // Loading indicator
                  if (_isVoting && isSelected)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizResult(Color textColor) {
    final isCorrect = _selectedOption == _poll.settings.correctOptionIndex;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCorrect
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isCorrect ? Icons.check_circle : Icons.cancel,
            color: isCorrect ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCorrect ? 'Correct!' : 'Incorrect',
                  style: TextStyle(
                    color: isCorrect ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_poll.settings.explanation != null)
                  Text(
                    _poll.settings.explanation!,
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor.withOpacity(0.7),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatExpiry(String expiresAt) {
    try {
      final expiry = DateTime.parse(expiresAt);
      final now = DateTime.now();
      
      if (expiry.isBefore(now)) {
        return 'Expired';
      }
      
      final difference = expiry.difference(now);
      
      if (difference.inDays > 0) {
        return '${difference.inDays}d left';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h left';
      } else {
        return '${difference.inMinutes}m left';
      }
    } catch (e) {
      return '';
    }
  }
}

