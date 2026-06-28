import 'dart:io';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/learning/exam_study/evaluation_result_screen.dart';
import 'package:bananatalk_app/pages/learning/exam_study/widgets/audio_recorder.dart';
import 'package:bananatalk_app/providers/provider_models/exam/exam_question.dart';
import 'package:bananatalk_app/providers/provider_root/exam_study_provider.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Full-screen speaking practice — prompt + AudioRecorder + submit.
/// On submit the audio is uploaded to /submit-audio (multipart) and
/// the screen pushes the polling EvaluationResultScreen with the
/// returned evaluation id.
class SpeakingPracticeScreen extends ConsumerStatefulWidget {
  const SpeakingPracticeScreen({
    super.key,
    required this.question,
    required this.examId,
  });

  final ExamQuestion question;
  final String examId;

  @override
  ConsumerState<SpeakingPracticeScreen> createState() =>
      _SpeakingPracticeScreenState();
}

class _SpeakingPracticeScreenState
    extends ConsumerState<SpeakingPracticeScreen> {
  bool _uploading = false;

  Future<void> _onRecorded(File audioFile) async {
    setState(() => _uploading = true);
    try {
      final result = await ref
          .read(examStudyServiceProvider)
          .submitSpeakingAnswer(
            questionId: widget.question.id,
            audioFile: audioFile,
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
      // Pop with `true` so the caller (section_practice) knows the user
      // actually submitted and can auto-advance to the next question.
      // Backing out via system-back or AppBar back returns null/false,
      // which keeps the user on the same question for a retry.
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        elevation: 0,
        title: Text(
          l10n.examSpeakingPrompt,
          style: TextStyle(
            color: context.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.containerColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.question.questionText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                        height: 1.5,
                      ),
                    ),
                    // Listen-to-prompt is a Phase-2 enhancement that
                    // hits /speech/tts. We surface the button now so
                    // the layout is final; tap is wired in a follow-up
                    // task (Chunk H+).
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: Center(
                  child: _uploading
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(
                              l10n.examSpeakingUploading,
                              style: TextStyle(
                                fontSize: 14,
                                color: context.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : AudioRecorder(onRecorded: _onRecorded),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
