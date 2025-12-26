import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/services/correction_service.dart';

class AddCorrectionDialog extends StatefulWidget {
  final String messageId;
  final String originalText;
  final Function(MessageCorrection)? onCorrectionAdded;

  const AddCorrectionDialog({
    Key? key,
    required this.messageId,
    required this.originalText,
    this.onCorrectionAdded,
  }) : super(key: key);

  /// Show the add correction dialog
  static Future<MessageCorrection?> show({
    required BuildContext context,
    required String messageId,
    required String originalText,
    Function(MessageCorrection)? onCorrectionAdded,
  }) {
    return showModalBottomSheet<MessageCorrection>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => AddCorrectionDialog(
        messageId: messageId,
        originalText: originalText,
        onCorrectionAdded: onCorrectionAdded,
      ),
    );
  }

  @override
  State<AddCorrectionDialog> createState() => _AddCorrectionDialogState();
}

class _AddCorrectionDialogState extends State<AddCorrectionDialog> {
  late TextEditingController _correctedController;
  final _explanationController = TextEditingController();
  bool _isSending = false;
  List<TextDiff> _diffs = [];

  @override
  void initState() {
    super.initState();
    _correctedController = TextEditingController(text: widget.originalText);
    _updateDiffs();
  }

  @override
  void dispose() {
    _correctedController.dispose();
    _explanationController.dispose();
    super.dispose();
  }

  void _updateDiffs() {
    final correctedText = _correctedController.text;
    if (correctedText.isEmpty || correctedText == widget.originalText) {
      setState(() => _diffs = []);
      return;
    }

    setState(() {
      _diffs = CorrectionService.getDifferences(
        widget.originalText,
        correctedText,
      );
    });
  }

  bool _hasChanges() {
    return _correctedController.text.trim() != widget.originalText.trim() &&
        _correctedController.text.trim().isNotEmpty;
  }

  Future<void> _sendCorrection() async {
    if (!_hasChanges() || _isSending) return;

    setState(() => _isSending = true);

    try {
      final result = await CorrectionService.sendCorrection(
        messageId: widget.messageId,
        originalText: widget.originalText,
        correctedText: _correctedController.text.trim(),
        explanation: _explanationController.text.trim(),
      );

      if (mounted) {
        if (result['success'] == true && result['data'] != null) {
          final correction = result['data'] as MessageCorrection;
          widget.onCorrectionAdded?.call(correction);
          Navigator.pop(context, correction);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Correction sent!')),
          );
        } else {
          setState(() => _isSending = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Failed to send correction'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
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
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.school, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Correct Message',
                  style: TextStyle(
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
            const SizedBox(height: 8),
            Text(
              'Help them learn by correcting their message',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),

            // Original text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Original message:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.originalText,
                    style: const TextStyle(fontSize: 15),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Corrected text input
            TextField(
              controller: _correctedController,
              onChanged: (_) => _updateDiffs(),
              decoration: InputDecoration(
                labelText: 'Your correction',
                hintText: 'Type the corrected version',
                border: const OutlineInputBorder(),
                helperText: _hasChanges()
                    ? 'Changes detected'
                    : 'Make changes to the text above',
                helperStyle: TextStyle(
                  color: _hasChanges() ? Colors.green : null,
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),

            // Diff preview
            if (_diffs.isNotEmpty) ...[
              Text(
                'Preview:',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: _diffs.map((diff) {
                    switch (diff.type) {
                      case DiffType.deleted:
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            diff.text,
                            style: TextStyle(
                              color: Colors.red[800],
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        );
                      case DiffType.added:
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            diff.text,
                            style: TextStyle(
                              color: Colors.green[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      case DiffType.unchanged:
                        return Text(diff.text);
                    }
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Explanation input
            TextField(
              controller: _explanationController,
              decoration: const InputDecoration(
                labelText: 'Explanation (optional)',
                hintText: 'Why is this correction helpful?',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              maxLength: 200,
            ),
            const SizedBox(height: 16),

            // Send button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _hasChanges() && !_isSending ? _sendCorrection : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text('Send Correction'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

