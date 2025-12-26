import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/services/correction_service.dart';
import 'package:intl/intl.dart';

class CorrectionWidget extends StatefulWidget {
  final MessageCorrection correction;
  final bool isMyMessage;
  final VoidCallback? onAccepted;

  const CorrectionWidget({
    Key? key,
    required this.correction,
    this.isMyMessage = false,
    this.onAccepted,
  }) : super(key: key);

  @override
  State<CorrectionWidget> createState() => _CorrectionWidgetState();
}

class _CorrectionWidgetState extends State<CorrectionWidget> {
  bool _isExpanded = false;
  bool _isAccepting = false;

  Future<void> _acceptCorrection() async {
    if (_isAccepting || widget.correction.isAccepted) return;

    setState(() => _isAccepting = true);

    // Note: Would need messageId passed in for actual API call
    // This is simplified for the widget
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      setState(() => _isAccepting = false);
      widget.onAccepted?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final diffs = CorrectionService.getDifferences(
      widget.correction.originalText,
      widget.correction.correctedText,
    );

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Row(
              children: [
                Icon(
                  Icons.school,
                  size: 16,
                  color: Colors.blue[700],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Correction from ${widget.correction.corrector.name ?? 'User'}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
                if (widget.correction.isAccepted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Accepted',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.blue[700],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Diff view
          _buildDiffView(diffs),

          // Expanded content
          if (_isExpanded) ...[
            const Divider(height: 16),
            
            // Original text
            _buildTextSection('Original:', widget.correction.originalText, Colors.red),
            const SizedBox(height: 8),
            
            // Corrected text
            _buildTextSection('Corrected:', widget.correction.correctedText, Colors.green),

            // Explanation
            if (widget.correction.explanation != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 16,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.correction.explanation!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Accept button for message owner
            if (widget.isMyMessage && !widget.correction.isAccepted) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isAccepting ? null : _acceptCorrection,
                  icon: _isAccepting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check, size: 18),
                  label: const Text('Accept Correction'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],

            // Timestamp
            const SizedBox(height: 8),
            Text(
              _formatDate(widget.correction.createdAt),
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDiffView(List<TextDiff> diffs) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: diffs.map((diff) {
        switch (diff.type) {
          case DiffType.deleted:
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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
    );
  }

  Widget _buildTextSection(String label, String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM d, HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }
}

/// Compact correction indicator for message bubbles
class CorrectionIndicator extends StatelessWidget {
  final int correctionCount;
  final VoidCallback? onTap;

  const CorrectionIndicator({
    Key? key,
    required this.correctionCount,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.school,
              size: 12,
              color: Colors.blue[700],
            ),
            const SizedBox(width: 4),
            Text(
              '$correctionCount',
              style: TextStyle(
                fontSize: 11,
                color: Colors.blue[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

