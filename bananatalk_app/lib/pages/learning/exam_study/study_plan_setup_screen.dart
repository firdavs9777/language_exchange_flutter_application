import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/learning/exam_study/study_plan_screen.dart';
import 'package:bananatalk_app/providers/provider_models/exam/exam_type.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/exam_study_provider.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Two-input form: target score + exam date. On submit calls the
/// backend's generate-study-plan endpoint and pushes the plan screen
/// with the freshly-created plan.
class StudyPlanSetupScreen extends ConsumerStatefulWidget {
  const StudyPlanSetupScreen({super.key, required this.exam});

  final ExamType exam;

  @override
  ConsumerState<StudyPlanSetupScreen> createState() =>
      _StudyPlanSetupScreenState();
}

class _StudyPlanSetupScreenState
    extends ConsumerState<StudyPlanSetupScreen> {
  final TextEditingController _scoreController = TextEditingController();
  DateTime? _examDate;
  bool _generating = false;
  String? _error;

  @override
  void dispose() {
    _scoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final maxScore = widget.exam.maxScore?.toDouble() ?? 100;

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        elevation: 0,
        title: Text(
          l10n.examPlanSetupTitle,
          style: TextStyle(
            color: context.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.exam.name,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: context.textPrimary,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.examPlanTargetScore,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.textSecondary,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _scoreController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              decoration: InputDecoration(
                hintText: 'e.g. ${(maxScore * 0.75).toStringAsFixed(0)}',
                filled: true,
                fillColor: context.surfaceColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: context.dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      BorderSide(color: context.primaryColor, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: context.dividerColor),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.examPlanExamDate,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.textSecondary,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.dividerColor),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      color: context.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _examDate != null
                          ? _formatDate(_examDate!)
                          : l10n.examPlanPickDate,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _examDate != null
                            ? context.textPrimary
                            : context.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFEF4444),
                ),
              ),
            ],
            const SizedBox(height: 28),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _generating ? null : _generate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: _generating
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            l10n.examPlanGenerating,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        l10n.examPlanGenerate,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _examDate ?? now.add(const Duration(days: 30)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() => _examDate = picked);
    }
  }

  Future<void> _generate() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _error = null);

    final scoreText = _scoreController.text.trim();
    final score = double.tryParse(scoreText);
    if (score == null || score <= 0) {
      setState(() => _error = l10n.examPlanInvalidScore);
      return;
    }
    if (_examDate == null || !_examDate!.isAfter(DateTime.now())) {
      setState(() => _error = l10n.examPlanInvalidDate);
      return;
    }
    final userId = ref.read(authServiceProvider).userId;
    if (userId.isEmpty) {
      setState(() => _error = l10n.vipLoginRequired);
      return;
    }

    setState(() => _generating = true);
    try {
      final plan = await ref.read(examStudyServiceProvider).generateStudyPlan(
            userId: userId,
            examId: widget.exam.id,
            targetScore: score,
            examDate: _examDate!,
          );
      if (!mounted) return;
      // Bust the cached plan so the plan-screen pulls the fresh one.
      ref.invalidate(
        userStudyPlanProvider(
          ProgressKey(userId: userId, examId: widget.exam.id),
        ),
      );
      await Navigator.of(context).pushReplacement(
        AppPageRoute(
          builder: (_) => StudyPlanScreen(exam: widget.exam, initialPlan: plan),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
