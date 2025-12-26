import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:bananatalk_app/services/moments_service.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

class ReportMomentDialog extends StatefulWidget {
  final String momentId;
  final VoidCallback? onReported;

  const ReportMomentDialog({
    Key? key,
    required this.momentId,
    this.onReported,
  }) : super(key: key);

  /// Show the report moment dialog
  static Future<bool?> show({
    required BuildContext context,
    required String momentId,
    VoidCallback? onReported,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => ReportMomentDialog(
        momentId: momentId,
        onReported: onReported,
      ),
    );
  }

  @override
  State<ReportMomentDialog> createState() => _ReportMomentDialogState();
}

class _ReportMomentDialogState extends State<ReportMomentDialog> {
  MomentReportReason? _selectedReason;
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseSelectAReason)),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await MomentsService.reportMoment(
        momentId: widget.momentId,
        reason: _selectedReason!,
        description: _descriptionController.text.trim(),
      );

      if (mounted) {
        if (result['success'] == true) {
          widget.onReported?.call();
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppLocalizations.of(context)!.reportSubmitted),
              backgroundColor: Colors.green,
            ),
          );
        } else if (result['alreadyReported'] == true) {
          Navigator.pop(context, false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppLocalizations.of(context)!.youHaveAlreadyReportedThisMoment),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Failed to submit report'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.error}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.flag, color: Colors.red),
                const SizedBox(width: 8),
                const Text(
                  'Report Moment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context, false),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Why are you reporting this moment?',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),

            // Reason selection
            ...MomentReportReason.values.map((reason) {
              return RadioListTile<MomentReportReason>(
                title: Text(reason.displayName),
                subtitle: _getReasonDescription(reason),
                value: reason,
                groupValue: _selectedReason,
                onChanged: (value) {
                  setState(() => _selectedReason = value);
                },
                contentPadding: EdgeInsets.zero,
              );
            }),

            // Description for "Other" reason
            if (_selectedReason == MomentReportReason.other) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Please describe the issue',
                  hintText: AppLocalizations.of(context)!.tellUsMoreAboutWhyYouAreReportingThis,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
                maxLength: 500,
              ),
            ],

            const SizedBox(height: 16),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedReason != null && !_isSubmitting
                    ? _submitReport
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(AppLocalizations.of(context)!.submitReport),
              ),
            ),

            const SizedBox(height: 8),

            // Disclaimer
            Text(
              'Your report is anonymous. We will review this content and take action if it violates our community guidelines.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget? _getReasonDescription(MomentReportReason reason) {
    String? description;
    switch (reason) {
      case MomentReportReason.spam:
        description = 'Unsolicited or repetitive content';
        break;
      case MomentReportReason.inappropriate:
        description = 'Nudity, sexual content, or adult material';
        break;
      case MomentReportReason.harassment:
        description = 'Bullying, threats, or personal attacks';
        break;
      case MomentReportReason.hateSpeech:
        description = 'Content promoting hatred or discrimination';
        break;
      case MomentReportReason.violence:
        description = 'Graphic violence or threats of violence';
        break;
      case MomentReportReason.misinformation:
        description = 'False or misleading information';
        break;
      case MomentReportReason.other:
        description = 'Something else not listed above';
        break;
    }
    return description != null
        ? Text(
            description,
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          )
        : null;
  }
}

