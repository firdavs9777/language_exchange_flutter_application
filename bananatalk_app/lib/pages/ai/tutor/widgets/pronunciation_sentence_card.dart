import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/pronunciation_provider.dart';
import '../../../../utils/theme_extensions.dart';

/// Renders the active sentence and the primary action button for the
/// current state. The scored render (word-level + char strikethrough)
/// is built in Task 8.
class PronunciationSentenceCard extends StatefulWidget {
  final SentenceAttempt attempt;
  final PronStatus status;
  final bool customDraftOpen;
  final String? errorMessage;

  final VoidCallback onRecord;
  final VoidCallback onStop;
  final VoidCallback onReplay;
  final VoidCallback onRetry;
  final VoidCallback onNext;
  final VoidCallback onOpenCustom;
  final void Function(String) onSubmitCustom;
  final VoidCallback onCancelCustom;

  const PronunciationSentenceCard({
    super.key,
    required this.attempt,
    required this.status,
    required this.customDraftOpen,
    required this.errorMessage,
    required this.onRecord,
    required this.onStop,
    required this.onReplay,
    required this.onRetry,
    required this.onNext,
    required this.onOpenCustom,
    required this.onSubmitCustom,
    required this.onCancelCustom,
  });

  @override
  State<PronunciationSentenceCard> createState() =>
      _PronunciationSentenceCardState();
}

class _PronunciationSentenceCardState extends State<PronunciationSentenceCard> {
  final TextEditingController _customCtrl = TextEditingController();
  String _lastAutoPlayedSentence = '';

  @override
  void didUpdateWidget(covariant PronunciationSentenceCard old) {
    super.didUpdateWidget(old);
    // Auto-play TTS once when a new sentence becomes ready.
    if (widget.status == PronStatus.ready &&
        widget.attempt.sentence.sentence != _lastAutoPlayedSentence) {
      _lastAutoPlayedSentence = widget.attempt.sentence.sentence;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => widget.onReplay());
    }
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    widget.attempt.sentence.sentence,
                    textAlign: TextAlign.center,
                    style: context.titleLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (widget.status == PronStatus.ready && !widget.customDraftOpen)
            TextButton.icon(
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: Text(l10n.aiTutorPronounceUseYourOwn),
              onPressed: widget.onOpenCustom,
            ),
          if (widget.customDraftOpen)
            _buildCustomField(context, l10n),
          if (widget.errorMessage != null &&
              widget.status != PronStatus.scoring)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Text(
                widget.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          const SizedBox(height: 12),
          _buildPrimaryActionRow(context, l10n),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCustomField(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          TextField(
            controller: _customCtrl,
            decoration: InputDecoration(
              hintText: l10n.aiTutorPronounceCustomHint,
              border: const OutlineInputBorder(),
            ),
            maxLength: 200,
            maxLines: 2,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: widget.onCancelCustom,
                child: Text(l10n.aiTutorPronounceCustomCancel),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => widget.onSubmitCustom(_customCtrl.text),
                child: Text(l10n.aiTutorPronounceCustomUse),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryActionRow(BuildContext context, AppLocalizations l10n) {
    switch (widget.status) {
      case PronStatus.ready:
        return _BigRoundButton(
          icon: Icons.mic_rounded,
          label: l10n.aiTutorPronounceTapToRecord,
          onPressed: widget.onRecord,
          color: AppColors.primary,
        );
      case PronStatus.recording:
        return _BigRoundButton(
          icon: Icons.stop_rounded,
          label: l10n.aiTutorPronounceTapToStop,
          onPressed: widget.onStop,
          color: Colors.redAccent,
          pulse: true,
        );
      case PronStatus.scoring:
        return Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(l10n.aiTutorPronounceTranscribing),
          ],
        );
      case PronStatus.scored:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            OutlinedButton(
              onPressed: widget.onRetry,
              child: Text(l10n.aiTutorPronounceTryAgain),
            ),
            FilledButton(
              onPressed: widget.onNext,
              child: Text(l10n.aiTutorPronounceNext),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _BigRoundButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;
  final bool pulse;

  const _BigRoundButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.color,
    this.pulse = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkResponse(
          onTap: onPressed,
          radius: 60,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: pulse ? 110 : 100,
            height: pulse ? 110 : 100,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: pulse ? 0.5 : 0.3),
                  blurRadius: pulse ? 30 : 16,
                  spreadRadius: pulse ? 8 : 2,
                ),
              ],
            ),
            child: Icon(icon, size: 40, color: Colors.white),
          ),
        ),
        const SizedBox(height: 12),
        Text(label, style: context.bodyMedium),
      ],
    );
  }
}
