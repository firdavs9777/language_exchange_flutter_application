import 'dart:async';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_models/exam/evaluation_status.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/exam_study_provider.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const Duration _pollInterval = Duration(seconds: 3);
const Duration _pollTimeout = Duration(seconds: 60);

/// Polls the backend's evaluation endpoint until the essay grading
/// finishes (or [_pollTimeout] elapses). When status != "pending" the
/// screen renders score + feedback. After completion, invalidates the
/// user's progress so the dashboard's section tile catches up.
class EvaluationResultScreen extends ConsumerStatefulWidget {
  const EvaluationResultScreen({
    super.key,
    required this.evaluationId,
    required this.examId,
  });

  final String evaluationId;
  final String examId;

  @override
  ConsumerState<EvaluationResultScreen> createState() =>
      _EvaluationResultScreenState();
}

class _EvaluationResultScreenState
    extends ConsumerState<EvaluationResultScreen> {
  EvaluationStatus? _status;
  String? _errorMessage;
  Timer? _pollTimer;
  Timer? _timeoutTimer;
  bool _polling = true;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _errorMessage = null;
    _polling = true;
    _pollOnce(); // immediate, then on interval
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _pollOnce());
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(_pollTimeout, _stopPolling);
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _timeoutTimer?.cancel();
    if (!mounted) return;
    setState(() => _polling = false);
  }

  Future<void> _pollOnce() async {
    try {
      final status = await ref
          .read(examStudyServiceProvider)
          .pollEvaluation(widget.evaluationId);
      if (!mounted) return;
      setState(() => _status = status);
      if (!status.isPending) {
        _stopPolling();
        _refreshProgress();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
      _stopPolling();
    }
  }

  void _refreshProgress() {
    final userId = ref.read(authServiceProvider).userId;
    if (userId.isEmpty) return;
    ref.invalidate(
      userExamProgressProvider(
        ProgressKey(userId: userId, examId: widget.examId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final status = _status;

    Widget body;
    if (_errorMessage != null && (status == null || status.isPending)) {
      body = _errorState(l10n);
    } else if (status == null || status.isPending) {
      body = _polling ? _evaluatingState(l10n) : _timeoutState(l10n);
    } else if (status.isFailed) {
      body = _failedState(l10n, status);
    } else {
      body = _completedState(l10n, status);
    }

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        elevation: 0,
        title: Text(
          l10n.examEssayResultTitle,
          style: TextStyle(
            color: context.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: body,
    );
  }

  Widget _evaluatingState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              l10n.examEssayEvaluating,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.examEssayEvaluatingHint,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: context.textSecondary,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeoutState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_top_rounded, size: 40, color: context.textMuted),
            const SizedBox(height: 12),
            Text(
              l10n.examEssayPollTimeout,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: context.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _startPolling,
              child: Text(l10n.examEssayPollRefresh),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 40, color: context.textMuted),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? l10n.examStudyError,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _startPolling,
              child: Text(l10n.examStudyRetry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _failedState(AppLocalizations l10n, EvaluationStatus status) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Color(0xFFEF4444),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.examEssayResultFailed,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ),
            if (status.errorMessage != null) ...[
              const SizedBox(height: 6),
              Text(
                status.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: context.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.examEssayResultRetry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _completedState(AppLocalizations l10n, EvaluationStatus status) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _scoreCard(l10n, status),
          if (status.transcript != null && status.transcript!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _transcriptBlock(l10n, status.transcript!),
          ],
          if (status.feedback != null && status.feedback!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _feedbackBlock(l10n, status.feedback!),
          ],
          if (status.strengths.isNotEmpty) ...[
            const SizedBox(height: 16),
            _bulletList(
              title: l10n.examEssayResultStrengths,
              items: status.strengths,
              accent: const Color(0xFF22C55E),
              icon: Icons.check_circle_rounded,
            ),
          ],
          if (status.improvements.isNotEmpty) ...[
            const SizedBox(height: 16),
            _bulletList(
              title: l10n.examEssayResultImprovements,
              items: status.improvements,
              accent: const Color(0xFFFFA000),
              icon: Icons.tips_and_updates_rounded,
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                l10n.examEssayResultDone,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreCard(AppLocalizations l10n, EvaluationStatus status) {
    final score = status.score ?? 0;
    final accent = score >= 75
        ? const Color(0xFF22C55E)
        : score >= 50
            ? const Color(0xFFFFA000)
            : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.18),
            accent.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.examEssayResultScore,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.textSecondary,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$score / 100',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: accent,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.star_rounded, color: accent, size: 56),
        ],
      ),
    );
  }

  Widget _transcriptBlock(AppLocalizations l10n, String transcript) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.containerColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.mic_rounded, size: 16, color: context.textSecondary),
              const SizedBox(width: 6),
              Text(
                l10n.examSpeakingTranscriptHeading,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: context.textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            transcript,
            style: TextStyle(
              fontSize: 14,
              color: context.textPrimary,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _feedbackBlock(AppLocalizations l10n, String feedback) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.dividerColor),
      ),
      child: Text(
        feedback,
        style: TextStyle(
          fontSize: 14,
          color: context.textPrimary,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _bulletList({
    required String title,
    required List<String> items,
    required Color accent,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: accent,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final item in items) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 14,
                        color: context.textPrimary,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
