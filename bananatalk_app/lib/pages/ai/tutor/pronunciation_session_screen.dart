import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../providers/pronunciation_provider.dart';
import 'widgets/pronunciation_sentence_card.dart';

class PronunciationSessionScreen extends ConsumerStatefulWidget {
  const PronunciationSessionScreen({super.key});

  @override
  ConsumerState<PronunciationSessionScreen> createState() =>
      _PronunciationSessionScreenState();
}

class _PronunciationSessionScreenState
    extends ConsumerState<PronunciationSessionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(pronunciationControllerProvider.notifier).init();
    });
  }

  Future<bool> _confirmQuit(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.aiTutorPronounceQuitConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.aiTutorPronounceQuitNo),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.aiTutorPronounceQuitYes),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pronunciationControllerProvider);
    final ctrl = ref.read(pronunciationControllerProvider.notifier);
    final l10n = AppLocalizations.of(context)!;
    final isSummary = state.status == PronStatus.summary;

    return PopScope(
      canPop: isSummary,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final allow = await _confirmQuit(context);
        if (!context.mounted) return;
        if (allow) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.aiTutorPronounceSentenceOf(
            (state.currentIndex + 1)
                .clamp(1, PronunciationState.sessionLength),
            PronunciationState.sessionLength,
          )),
          actions: [
            if (state.status == PronStatus.ready ||
                state.status == PronStatus.scored)
              IconButton(
                icon: const Icon(Icons.volume_up_rounded),
                tooltip: 'Replay',
                onPressed: ctrl.playReference,
              ),
          ],
        ),
        body: SafeArea(
          child: _buildBody(context, state, ctrl, l10n),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    PronunciationState state,
    PronunciationController ctrl,
    AppLocalizations l10n,
  ) {
    switch (state.status) {
      case PronStatus.loading:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(l10n.aiTutorPronounceLoading),
              if (state.errorMessage != null) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    state.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: ctrl.init,
                  child: const Text('Retry'),
                ),
              ],
            ],
          ),
        );
      case PronStatus.ready:
      case PronStatus.recording:
      case PronStatus.scoring:
      case PronStatus.scored:
        final current = state.current;
        if (current == null) return const SizedBox.shrink();
        return PronunciationSentenceCard(
          attempt: current,
          status: state.status,
          customDraftOpen: state.customDraftOpen,
          errorMessage: state.errorMessage,
          onRecord: ctrl.tapRecord,
          onStop: ctrl.tapStop,
          onReplay: ctrl.playReference,
          onRetry: ctrl.retry,
          onNext: ctrl.next,
          onOpenCustom: ctrl.openCustomDraft,
          onSubmitCustom: ctrl.submitCustom,
          onCancelCustom: ctrl.closeCustomDraft,
        );
      case PronStatus.summary:
        // Built in Task 9 — placeholder so the screen still compiles.
        return const Center(child: Text('Summary — wiring next'));
    }
  }
}
