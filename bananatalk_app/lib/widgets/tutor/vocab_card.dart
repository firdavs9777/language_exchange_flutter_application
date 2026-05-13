import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/api_client.dart';
import '../../utils/theme_extensions.dart';
import '../../core/theme/app_theme.dart';

/// Inline vocab card the tutor drops into chat when it introduces a
/// new word. Tapping "Add to vocab" POSTs the payload to the existing
/// `/learning/vocabulary` endpoint.
class VocabCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> payload;
  const VocabCard({super.key, required this.payload});

  @override
  ConsumerState<VocabCard> createState() => _VocabCardState();
}

class _VocabCardState extends ConsumerState<VocabCard> {
  bool _adding = false;
  bool _added = false;
  String? _error;

  Future<void> _addToVocab() async {
    setState(() {
      _adding = true;
      _error = null;
    });
    try {
      final res = await ApiClient().post(
        'learning/vocabulary',
        body: {
          'word': widget.payload['word'],
          'language': widget.payload['language'],
          'definition': widget.payload['definition'],
          'example': widget.payload['example'],
        },
      );
      if (!res.success) throw StateError(res.error ?? 'Failed');
      if (mounted) {
        setState(() {
          _adding = false;
          _added = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _adding = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final word = widget.payload['word']?.toString() ?? '';
    final ipa = widget.payload['ipa']?.toString();
    final definition = widget.payload['definition']?.toString() ?? '';
    final example = widget.payload['example']?.toString() ?? '';

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.containerColor,
          borderRadius: AppRadius.borderMD,
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.book_outlined, size: 16, color: AppColors.accent),
                const SizedBox(width: 6),
                Text(
                  'Vocab',
                  style: context.bodySmall.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    word,
                    style: context.titleMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (ipa != null && ipa.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text('/$ipa/',
                      style: context.bodySmall.copyWith(color: context.textMuted)),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(definition, style: context.bodyMedium),
            if (example.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                '"$example"',
                style: context.bodySmall.copyWith(
                  fontStyle: FontStyle.italic,
                  color: context.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: (_adding || _added) ? null : _addToVocab,
                icon: Icon(_added ? Icons.check : Icons.add),
                label: Text(_added
                    ? 'Added to vocab'
                    : (_adding ? 'Adding…' : 'Add to vocab')),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 4),
              Text(_error!,
                  style: const TextStyle(color: Colors.red, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }
}
