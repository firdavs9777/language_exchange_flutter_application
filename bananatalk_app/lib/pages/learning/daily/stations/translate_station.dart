import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';

/// The weekend productive station: write the sentence in your target language.
/// Typed input only in wave 1 — speech input is a deferred spec question.
class TranslateStation extends StatefulWidget {
  final TranslatePayload payload;
  final Future<StationResult> Function(String) onSubmit;
  final VoidCallback onDone;

  const TranslateStation({
    super.key,
    required this.payload,
    required this.onSubmit,
    required this.onDone,
  });

  @override
  State<TranslateStation> createState() => _TranslateStationState();
}

class _TranslateStationState extends State<TranslateStation> {
  final _controller = TextEditingController();
  StationResult? _result;
  bool _submitting = false;
  bool _failed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _failed = false;
    });
    try {
      final result = await widget.onSubmit(_controller.text.trim());
      if (mounted) setState(() => _result = result);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final canSubmit = _controller.text.trim().isNotEmpty && !_submitting;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(l10n.packTranslatePrompt, style: theme.textTheme.labelMedium),
        const SizedBox(height: 12),
        Text(widget.payload.sentence, style: theme.textTheme.titleLarge),
        if (widget.payload.hint.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              widget.payload.hint,
              key: const Key('translate-hint'),
              style: theme.textTheme.bodySmall,
            ),
          ),
        const SizedBox(height: 24),
        TextField(
          key: const Key('translate-input'),
          controller: _controller,
          minLines: 2,
          maxLines: 5,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: l10n.packTranslateHint,
          ),
        ),
        const SizedBox(height: 16),
        if (_result != null) ...[
          Padding(
            key: const Key('station-score'),
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              // A submission the grader could not mark says so rather than
              // showing a score the learner did not earn.
              _result!.graded == false
                  ? l10n.packNotGraded
                  : l10n.dailyScore(_result!.score, _result!.total),
              style: theme.textTheme.titleLarge,
            ),
          ),
          if (_result!.feedback.isNotEmpty)
            Padding(
              key: const Key('translate-feedback'),
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_result!.feedback, style: theme.textTheme.bodyMedium),
            ),
          if (_result!.suggestedTranslation.isNotEmpty)
            Padding(
              key: const Key('translate-suggestion'),
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                l10n.packSuggestedTranslation(_result!.suggestedTranslation),
                style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
        ],
        if (_failed)
          Padding(
            key: const Key('station-error'),
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              l10n.packSubmitFailed,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
            ),
          ),
        if (_result == null)
          FilledButton(
            key: const Key('station-submit'),
            onPressed: canSubmit ? _submit : null,
            child: Text(l10n.dailyCheck),
          )
        else
          FilledButton(
            key: const Key('station-continue'),
            onPressed: widget.onDone,
            child: Text(l10n.packContinue),
          ),
      ],
    );
  }
}
