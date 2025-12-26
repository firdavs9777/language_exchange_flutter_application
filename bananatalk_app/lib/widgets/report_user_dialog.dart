import 'package:flutter/material.dart';
import 'package:bananatalk_app/services/report_service.dart';
import 'package:bananatalk_app/services/block_service.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

enum ReportReason {
  spam('Spam', 'This user is sending spam messages'),
  harassment('Harassment', 'This user is harassing me'),
  inappropriate('Inappropriate Content', 'This user is sharing inappropriate content'),
  impersonation('Impersonation', 'This user is impersonating someone'),
  scam('Scam or Fraud', 'This user is attempting to scam or defraud'),
  hate('Hate Speech', 'This user is posting hate speech'),
  violence('Violence or Threats', 'This user is threatening violence'),
  other('Other', 'Other reason');

  final String title;
  final String description;
  const ReportReason(this.title, this.description);
}

class ReportUserDialog extends StatefulWidget {
  final String currentUserId;
  final String targetUserId;
  final String targetUserName;
  final String? targetUserAvatar;

  const ReportUserDialog({
    super.key,
    required this.currentUserId,
    required this.targetUserId,
    required this.targetUserName,
    this.targetUserAvatar,
  });

  static Future<void> show({
    required BuildContext context,
    required String currentUserId,
    required String targetUserId,
    required String targetUserName,
    String? targetUserAvatar,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => ReportUserDialog(
        currentUserId: currentUserId,
        targetUserId: targetUserId,
        targetUserName: targetUserName,
        targetUserAvatar: targetUserAvatar,
      ),
    );
  }

  @override
  State<ReportUserDialog> createState() => _ReportUserDialogState();
}

class _ReportUserDialogState extends State<ReportUserDialog> {
  ReportReason? _selectedReason;
  final TextEditingController _detailsController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null) return;

    setState(() => _isSubmitting = true);

    // Store details before any async operation
    final details = _detailsController.text.trim();

    // Submit report
    final reportResult = await ReportService.reportUser(
      reporterId: widget.currentUserId,
      reportedUserId: widget.targetUserId,
      reason: _selectedReason!.name,
      details: details,
    );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    final isSuccess = reportResult['success'] == true;

    // Close this dialog first
    Navigator.pop(context);

    // Show result
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.error_outline,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  reportResult['message'] ??
                      (isSuccess
                          ? 'Report submitted successfully. Thank you for helping keep our community safe.'
                          : 'Failed to submit report'),
                ),
              ),
            ],
          ),
          backgroundColor: isSuccess ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 4),
        ),
      );

      // Show block option dialog
      if (isSuccess && context.mounted) {
        final blockUser = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(AppLocalizations.of(context)!.wouldYouAlsoLikeToBlockThisUser),
            content: Text(
              'Blocking ${widget.targetUserName} will prevent them from contacting you.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(AppLocalizations.of(context)!.noThanks),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(AppLocalizations.of(context)!.yesBlockThem),
              ),
            ],
          ),
        );

        if (blockUser == true && context.mounted) {
          // Call block service directly
          final blockResult = await BlockService.blockUser(
            currentUserId: widget.currentUserId,
            blockedUserId: widget.targetUserId,
            blockedUserName: widget.targetUserName,
          );

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  blockResult['success'] == true
                      ? '${widget.targetUserName} has been blocked'
                      : blockResult['message'] ?? 'Failed to block user',
                ),
                backgroundColor:
                    blockResult['success'] == true ? Colors.green : Colors.red,
              ),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Icon(Icons.flag, color: Colors.orange[700], size: 24),
          const SizedBox(width: 12),
          Text(AppLocalizations.of(context)!.reportUser2),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Report ${widget.targetUserName} for:',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),

            // Reason selection
            ...ReportReason.values.map((reason) {
              return RadioListTile<ReportReason>(
                title: Text(reason.title),
                subtitle: Text(
                  reason.description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                value: reason,
                groupValue: _selectedReason,
                onChanged: (value) {
                  setState(() => _selectedReason = value);
                },
                contentPadding: EdgeInsets.zero,
                dense: true,
              );
            }),

            const SizedBox(height: 16),

            // Additional details
            TextField(
              controller: _detailsController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.additionalDetailsOptional,
                hintText: AppLocalizations.of(context)!.provideMoreInformation,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              maxLines: 3,
              maxLength: 500,
            ),

            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your report will be reviewed by our team. We take all reports seriously.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: Text(
            AppLocalizations.of(context)!.cancel,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _selectedReason == null || _isSubmitting
              ? null
              : _submitReport,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange[700],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            disabledBackgroundColor: Colors.grey[300],
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(AppLocalizations.of(context)!.submitReport),
        ),
      ],
    );
  }
}
