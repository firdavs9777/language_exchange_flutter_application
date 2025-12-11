import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_root/report_provider.dart';

class ReportDialog extends StatefulWidget {
  final String type; // 'user', 'moment', 'comment', 'message', 'story'
  final String reportedId; // ID of the reported content
  final String reportedUserId; // ID of the user who owns the content

  const ReportDialog({
    Key? key,
    required this.type,
    required this.reportedId,
    required this.reportedUserId,
  }) : super(key: key);

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final ReportService _reportService = ReportService();
  String? _selectedReason;
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  final List<Map<String, String>> _reasons = [
    {'value': 'spam', 'label': 'Spam'},
    {'value': 'harassment', 'label': 'Harassment or Bullying'},
    {'value': 'hate_speech', 'label': 'Hate Speech'},
    {'value': 'violence', 'label': 'Violence or Threats'},
    {'value': 'nudity', 'label': 'Nudity or Sexual Content'},
    {'value': 'false_information', 'label': 'False Information'},
    {'value': 'copyright', 'label': 'Copyright Violation'},
    {'value': 'other', 'label': 'Other'},
  ];

  String get _typeLabel {
    switch (widget.type) {
      case 'user':
        return 'user';
      case 'moment':
        return 'moment';
      case 'comment':
        return 'comment';
      case 'message':
        return 'message';
      case 'story':
        return 'story';
      default:
        return 'content';
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    // Prevent multiple submissions
    if (_isSubmitting) {
      return;
    }

    // Validate all required fields
    if (_selectedReason == null || _selectedReason!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a reason for reporting'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (widget.type.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report type is missing'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (widget.reportedId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reported content ID is missing'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (widget.reportedUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reported user ID is missing'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await _reportService.createReport(
        type: widget.type,
        reportId: widget.reportedId, // Parameter name is reportId, but we pass reportedId value
        reportedUser: widget.reportedUserId,
        reason: _selectedReason!,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      if (mounted) {
        if (result['success'] == true) {
          // Close dialog first to prevent multiple submissions
          Navigator.of(context).pop(true);
          // Reset state after closing
          setState(() {
            _isSubmitting = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Report submitted successfully'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          // Show detailed error message
          final errorMessage = result['error'] ?? 'Failed to submit report';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
          
          // Re-enable button after error
          setState(() {
            _isSubmitting = false;
          });
          
          // If it's a validation error, keep dialog open
          if (errorMessage.toLowerCase().contains('required') || 
              errorMessage.toLowerCase().contains('missing')) {
            // Don't close dialog, let user fix the issue
            return;
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.flag_outlined,
                    color: Colors.red[600],
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Report $_typeLabel',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Why are you reporting this $_typeLabel?',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Reason options
                    ..._reasons.map((reason) => RadioListTile<String>(
                          title: Text(reason['label']!),
                          value: reason['value']!,
                          groupValue: _selectedReason,
                          onChanged: (value) {
                            setState(() {
                              _selectedReason = value;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        )),

                    const SizedBox(height: 24),

                    // Additional details
                    Text(
                      'Additional details (optional)',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Provide more information about the issue...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: AbsorbPointer(
                      absorbing: _isSubmitting,
                      child: Opacity(
                        opacity: _isSubmitting ? 0.6 : 1.0,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitReport,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Submit Report',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

