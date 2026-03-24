import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/services/correction_service.dart';

/// Bottom sheet for correcting another user's message (Tandem/HelloTalk style).
/// Shows the original text in an editable field, lets user fix it and add explanation.
class CorrectionBottomSheet extends StatefulWidget {
  final String messageId;
  final String originalText;
  final String senderName;

  const CorrectionBottomSheet({
    super.key,
    required this.messageId,
    required this.originalText,
    required this.senderName,
  });

  @override
  State<CorrectionBottomSheet> createState() => _CorrectionBottomSheetState();
}

class _CorrectionBottomSheetState extends State<CorrectionBottomSheet> {
  late TextEditingController _correctedController;
  late TextEditingController _explanationController;
  bool _isSending = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _correctedController = TextEditingController(text: widget.originalText);
    _explanationController = TextEditingController();
    _correctedController.addListener(_checkChanges);
  }

  @override
  void dispose() {
    _correctedController.dispose();
    _explanationController.dispose();
    super.dispose();
  }

  void _checkChanges() {
    final changed = _correctedController.text.trim() != widget.originalText.trim();
    if (changed != _hasChanges) {
      setState(() => _hasChanges = changed);
    }
  }

  Future<void> _sendCorrection() async {
    if (!_hasChanges || _isSending) return;

    setState(() => _isSending = true);

    final result = await CorrectionService.sendCorrection(
      messageId: widget.messageId,
      originalText: widget.originalText,
      correctedText: _correctedController.text.trim(),
      explanation: _explanationController.text.trim().isNotEmpty
          ? _explanationController.text.trim()
          : null,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Correction sent'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error']?.toString() ?? 'Failed to send correction'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    // Show diff preview
    final diffs = _hasChanges
        ? CorrectionService.getDifferences(
            widget.originalText, _correctedController.text.trim())
        : <TextDiff>[];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.gray700 : AppColors.gray300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                const Icon(Icons.spellcheck_rounded, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Correct ${widget.senderName}\'s message',
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 22),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Original text label
                  Text(
                    'Original',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.gray400 : AppColors.gray600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.gray800 : AppColors.gray100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      widget.originalText,
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? AppColors.gray300 : AppColors.gray700,
                        height: 1.4,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Corrected text field
                  Text(
                    'Your correction',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.gray400 : AppColors.gray600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _correctedController,
                    maxLines: null,
                    minLines: 2,
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? AppColors.white : AppColors.gray900,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Type the corrected version...',
                      hintStyle: TextStyle(
                        color: isDark ? AppColors.gray600 : AppColors.gray400,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.gray800
                          : theme.primaryColor.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: theme.primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.gray700
                              : theme.primaryColor.withValues(alpha: 0.2),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: theme.primaryColor,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),

                  // Diff preview
                  if (diffs.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Changes',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.gray400 : AppColors.gray600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.gray800 : AppColors.gray50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text.rich(
                        TextSpan(
                          children: diffs.map((diff) {
                            switch (diff.type) {
                              case DiffType.unchanged:
                                return TextSpan(
                                  text: '${diff.text} ',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: isDark
                                        ? AppColors.gray300
                                        : AppColors.gray700,
                                  ),
                                );
                              case DiffType.deleted:
                                return TextSpan(
                                  text: '${diff.text} ',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.red[400],
                                    decoration: TextDecoration.lineThrough,
                                    decorationColor: Colors.red[400],
                                  ),
                                );
                              case DiffType.added:
                                return TextSpan(
                                  text: '${diff.text} ',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.green[600],
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                            }
                          }).toList(),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Explanation field (optional)
                  Text(
                    'Explanation (optional)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.gray400 : AppColors.gray600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _explanationController,
                    maxLines: 2,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.white : AppColors.gray900,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Why did you make this correction?',
                      hintStyle: TextStyle(
                        color: isDark ? AppColors.gray600 : AppColors.gray400,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: isDark ? AppColors.gray800 : AppColors.gray50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Send button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _hasChanges && !_isSending ? _sendCorrection : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        isDark ? AppColors.gray800 : AppColors.gray200,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Send Correction',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Show the correction bottom sheet
Future<bool?> showCorrectionBottomSheet(
  BuildContext context, {
  required String messageId,
  required String originalText,
  required String senderName,
}) {
  HapticFeedback.mediumImpact();
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: CorrectionBottomSheet(
        messageId: messageId,
        originalText: originalText,
        senderName: senderName,
      ),
    ),
  );
}
