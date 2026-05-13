import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../providers/pronunciation_provider.dart';
import '../../../../utils/theme_extensions.dart';

class PronunciationSummarySheet extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  const PronunciationSummarySheet({super.key, required this.onClose});

  @override
  ConsumerState<PronunciationSummarySheet> createState() =>
      _PronunciationSummarySheetState();
}

class _PronunciationSummarySheetState
    extends ConsumerState<PronunciationSummarySheet> {
  bool _saving = false;
  String? _saveError;

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      await ref.read(pronunciationControllerProvider.notifier).finish();
      if (!mounted) return;
      widget.onClose();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pronunciationControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    final scores = state.session
        .map((a) => a.lastScore?.overallScore)
        .whereType<int>()
        .toList();
    final avg = scores.isEmpty
        ? 0
        : (scores.reduce((a, b) => a + b) / scores.length).round();

    final weak = <String>{};
    for (final a in state.session) {
      final s = a.lastScore;
      if (s == null) continue;
      for (final w in s.wordScores) {
        if (w.status == 'wrong' || w.status == 'missing') weak.add(w.word);
      }
    }
    final weakList = weak.take(3).toList();

    final avgColor = avg >= 80
        ? Colors.green.shade600
        : avg >= 50
            ? Colors.orange.shade700
            : Colors.red.shade600;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.aiTutorPronounceSummaryTitle,
            style: context.titleLarge.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Text(l10n.aiTutorPronounceSummaryAvg, style: context.bodyMedium),
          const SizedBox(height: 4),
          Text(
            '$avg',
            style: context.displayLarge.copyWith(
              fontWeight: FontWeight.w800,
              color: avgColor,
            ),
          ),
          if (weakList.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(l10n.aiTutorPronounceSummaryWeak,
                style: context.bodyMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: [
                for (final w in weakList)
                  Chip(
                    label: Text(w),
                    backgroundColor: Colors.orange.shade50,
                    side: BorderSide(color: Colors.orange.shade200),
                  ),
              ],
            ),
          ],
          if (_saveError != null) ...[
            const SizedBox(height: 12),
            Text(
              _saveError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(
                _saving
                    ? l10n.aiTutorPronounceSaving
                    : l10n.aiTutorPronounceSaveClose,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
