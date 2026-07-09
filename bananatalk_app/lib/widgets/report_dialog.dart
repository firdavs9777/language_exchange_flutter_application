import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:bananatalk_app/providers/provider_root/report_provider.dart';
import 'package:bananatalk_app/widgets/evidence_tile.dart';

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

  final List<PlatformFile> _selectedFiles = [];
  int _totalFileSize = 0; // in bytes

  static const int maxFileSize = 5 * 1024 * 1024; // 5 MB
  static const int maxFiles = 5;
  static const int maxTotalSize = 25 * 1024 * 1024; // 25 MB
  static const List<String> allowedExtensions = ['jpg', 'jpeg', 'png', 'txt'];

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

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
      allowMultiple: true,
    );

    if (result == null || result.files.isEmpty) {
      return; // User cancelled
    }

    // Validate and add files
    for (final file in result.files) {
      // Check if already at max files
      if (_selectedFiles.length >= maxFiles) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Max $maxFiles files per report'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        break;
      }

      // Check file size
      if (file.size > maxFileSize) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${file.name} is too large (max 5 MB)'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        continue;
      }

      // Check total size
      if (_totalFileSize + file.size > maxTotalSize) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Total size would exceed 25 MB'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        break;
      }

      // Add file
      setState(() {
        _selectedFiles.add(file);
        _totalFileSize += file.size;
      });
    }
  }

  void _removeFile(int index) {
    setState(() {
      _totalFileSize -= _selectedFiles[index].size;
      _selectedFiles.removeAt(index);
    });
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _submitReport() async {
    // Prevent multiple submissions
    if (_isSubmitting) {
      return;
    }

    // Validate evidence is attached
    if (_selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please attach at least one file as evidence'),
          backgroundColor: Colors.orange,
        ),
      );
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
          final reportId = result['data']['_id'];

          // Upload evidence files
          try {
            for (final file in _selectedFiles) {
              await _reportService.uploadEvidence(
                reportId: reportId,
                file: file,
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Report submitted, but some evidence failed to upload'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }

          // Close dialog after evidence is uploaded
          if (mounted) {
            setState(() {
              _isSubmitting = false;
            });
            Navigator.of(context).pop(true);
          }

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

                    const SizedBox(height: 24),

                    // Evidence section
                    Text(
                      'Add Evidence (Required)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload screenshots or text files to support your report',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),

                    // File picker button
                    ElevatedButton.icon(
                      onPressed: _selectedFiles.length >= maxFiles ? null : _pickFiles,
                      icon: const Icon(Icons.attach_file),
                      label: Text(
                        'Add Files (${_selectedFiles.length}/$maxFiles)',
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Display selected files
                    if (_selectedFiles.isNotEmpty) ...[
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: List.generate(
                            _selectedFiles.length,
                            (index) => EvidenceTile(
                              file: _selectedFiles[index],
                              onRemove: () => _removeFile(index),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // File size progress
                    Text(
                      'Total: ${_formatFileSize(_totalFileSize)} / ${_formatFileSize(maxTotalSize)}',
                      style: Theme.of(context).textTheme.labelSmall,
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
                      absorbing: _isSubmitting || _selectedFiles.isEmpty,
                      child: Opacity(
                        opacity: _isSubmitting || _selectedFiles.isEmpty ? 0.6 : 1.0,
                        child: ElevatedButton(
                          onPressed: (_isSubmitting || _selectedFiles.isEmpty) ? null : _submitReport,
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

