import 'dart:async';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/learning/exam_study/evaluation_result_screen.dart';
import 'package:bananatalk_app/pages/learning/exam_study/widgets/exam_figure.dart';
import 'package:bananatalk_app/pages/learning/exam_study/widgets/quota_banner.dart';
import 'package:bananatalk_app/providers/provider_models/exam/exam_question.dart';
import 'package:bananatalk_app/providers/provider_models/exam/exam_submission_result.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/exam_study_provider.dart';
import 'package:bananatalk_app/services/exam_essay_quota.dart';
import 'package:bananatalk_app/services/ad_service.dart';
import 'package:bananatalk_app/widgets/ads/ad_widgets.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const int _essayMinChars = 50;
const int _essayMaxChars = 5000;

/// Full-screen essay editor with word/char counter, draft persistence,
/// and the free-tier VIP quota gate. On submit we hit the backend
/// (which returns 202 + pollUrl) and push the result screen with the
/// returned evaluation id.
class EssayEditorScreen extends ConsumerStatefulWidget {
  const EssayEditorScreen({
    super.key,
    required this.question,
    required this.examId,
  });

  final ExamQuestion question;
  final String examId;

  @override
  ConsumerState<EssayEditorScreen> createState() => _EssayEditorScreenState();
}

class _EssayEditorScreenState extends ConsumerState<EssayEditorScreen> {
  late final TextEditingController _controller;
  late final String _draftKey;
  bool _submitting = false;
  int _quotaUsed = 0;
  bool _isVip = false;
  Timer? _draftSaveTimer;

  @override
  void initState() {
    super.initState();
    _draftKey = 'exam_essay_draft:${widget.question.id}';
    _controller = TextEditingController();
    _restoreDraft();
    _refreshQuota();
    _controller.addListener(_scheduleDraftSave);
  }

  @override
  void dispose() {
    _draftSaveTimer?.cancel();
    _persistDraft(); // final flush
    _controller.dispose();
    super.dispose();
  }

  Future<void> _restoreDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final draft = prefs.getString(_draftKey);
    if (draft != null && draft.isNotEmpty && mounted) {
      _controller.text = draft;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.examEssayDraftRestored),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _scheduleDraftSave() {
    _draftSaveTimer?.cancel();
    _draftSaveTimer = Timer(
      const Duration(seconds: 2),
      _persistDraft,
    );
  }

  Future<void> _persistDraft() async {
    final prefs = await SharedPreferences.getInstance();
    if (_controller.text.trim().isEmpty) {
      await prefs.remove(_draftKey);
    } else {
      await prefs.setString(_draftKey, _controller.text);
    }
  }

  Future<void> _refreshQuota() async {
    final userAsync = ref.read(userProvider);
    final user = userAsync.valueOrNull;
    final userId = ref.read(authServiceProvider).userId;
    final isVip = user?.isVip ?? false;
    final used = userId.isEmpty ? 0 : await ExamEssayQuota.usedToday(userId);
    if (!mounted) return;
    setState(() {
      _isVip = isVip;
      _quotaUsed = used;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = _controller.text;
    final chars = text.length;
    final words = text.trim().isEmpty
        ? 0
        : text.trim().split(RegExp(r'\s+')).length;
    final tooShort = chars < _essayMinChars;
    final tooLong = chars > _essayMaxChars;
    final outOfQuota = !_isVip &&
        _quotaUsed >= ExamEssayQuota.dailyLimit;
    final canSubmit = !tooShort && !tooLong && !outOfQuota && !_submitting;

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        elevation: 0,
        title: Text(
          l10n.examEssayPrompt,
          style: TextStyle(
            color: context.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  QuotaBanner(used: _quotaUsed, isVip: _isVip),
                  if (!_isVip) const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.containerColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.dividerColor),
                    ),
                    child: Builder(
                      builder: (context) {
                        final prompt =
                            ExamPrompt.parse(widget.question.questionText);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (prompt.figure != null) ...[
                              ExamFigureView(spec: prompt.figure!),
                              const SizedBox(height: 14),
                            ],
                            Text(
                              prompt.prose,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: context.textPrimary,
                                height: 1.45,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _controller,
                    maxLines: null,
                    minLines: 8,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(_essayMaxChars),
                    ],
                    style: TextStyle(
                      fontSize: 15,
                      color: context.textPrimary,
                      height: 1.5,
                    ),
                    decoration: InputDecoration(
                      hintText: l10n.examEssayPrompt,
                      filled: true,
                      fillColor: context.surfaceColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            BorderSide(color: context.dividerColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: context.primaryColor,
                          width: 2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            BorderSide(color: context.dividerColor),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        l10n.examEssayWordCount(words),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.textMuted,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n.examEssayCharCount(chars),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: tooShort || tooLong
                              ? const Color(0xFFEF4444)
                              : context.textMuted,
                        ),
                      ),
                    ],
                  ),
                  if (tooShort) ...[
                    const SizedBox(height: 4),
                    Text(
                      l10n.examEssayMinChars(_essayMinChars),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ],
                  if (tooLong) ...[
                    const SizedBox(height: 4),
                    Text(
                      l10n.examEssayMaxChars(_essayMaxChars),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                border: Border(top: BorderSide(color: context.dividerColor)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BannerAdWidget(),
                  const SizedBox(height: 8),
                  SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: canSubmit ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        context.primaryColor.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Text(
                          l10n.examEssaySubmit,
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
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final result = await ref.read(examStudyServiceProvider).submitAnswer(
            questionId: widget.question.id,
            userAnswer: _controller.text,
          );
      if (!mounted) return;
      if (result is AsyncResult) {
        // Record quota use only after the server accepts the submission.
        final userId = ref.read(authServiceProvider).userId;
        if (userId.isNotEmpty && !_isVip) {
          await ExamEssayQuota.recordSubmission(userId);
        }
        // Clear the draft — submitted text lives on the server now.
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_draftKey);

        if (!mounted) return;
        // Interstitial after finishing a session (throttled + skipped for VIP).
        await AdService().maybeShowInterstitial(
          everyN: 1,
          minGap: const Duration(seconds: 60),
        );
        if (!mounted) return;
        await Navigator.of(context).push(
          AppPageRoute(
            builder: (_) => EvaluationResultScreen(
              evaluationId: result.evaluationId,
              examId: widget.examId,
            ),
          ),
        );
        if (!mounted) return;
        // Bubble the dashboard refresh up — sections under this exam
        // should re-pull progress when the user returns.
        Navigator.of(context).pop();
      } else if (result is InstantResult) {
        // Defensive: backend shouldn't return InstantResult for essays.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.feedback)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
